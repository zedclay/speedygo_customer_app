import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_socket.dart';

enum OrderTrackingFocus {
  overview,
  statusDetails,
  map,
  nearby,
  completed,
}

class OrderTrackingState {
  const OrderTrackingState({
    this.loading = true,
    this.refreshing = false,
    this.order,
    this.delivery,
    this.deliveryNotFound = false,
    this.tracking,
    this.stage = OrderTrackingStage.unknown,
    this.socketConnected = false,
    this.offline = false,
    this.errorMessage,
    this.lastLocationRecordedAt,
    this.focus = OrderTrackingFocus.overview,
  });

  final bool loading;
  final bool refreshing;
  final OrderDetail? order;
  final CustomerDeliveryDetail? delivery;
  final bool deliveryNotFound;
  final TrackingSnapshot? tracking;
  final OrderTrackingStage stage;
  final bool socketConnected;
  final bool offline;
  final String? errorMessage;
  final String? lastLocationRecordedAt;
  final OrderTrackingFocus focus;

  OrderTrackingState copyWith({
    bool? loading,
    bool? refreshing,
    OrderDetail? order,
    CustomerDeliveryDetail? delivery,
    bool? deliveryNotFound,
    bool clearDelivery = false,
    TrackingSnapshot? tracking,
    bool clearTracking = false,
    OrderTrackingStage? stage,
    bool? socketConnected,
    bool? offline,
    String? errorMessage,
    bool clearError = false,
    String? lastLocationRecordedAt,
    OrderTrackingFocus? focus,
  }) {
    return OrderTrackingState(
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      order: order ?? this.order,
      delivery: clearDelivery ? null : (delivery ?? this.delivery),
      deliveryNotFound: deliveryNotFound ?? this.deliveryNotFound,
      tracking: clearTracking ? null : (tracking ?? this.tracking),
      stage: stage ?? this.stage,
      socketConnected: socketConnected ?? this.socketConnected,
      offline: offline ?? this.offline,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastLocationRecordedAt:
          lastLocationRecordedAt ?? this.lastLocationRecordedAt,
      focus: focus ?? this.focus,
    );
  }
}

class OrderTrackingController extends Notifier<OrderTrackingState> {
  OrderTrackingController(this.orderId);

  final String orderId;

  TrackingRealtimeClient? _socket;
  StreamSubscription<TrackingLocation>? _locationSub;
  StreamSubscription<TrackingSnapshot>? _statusSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _connectionSub;
  Timer? _pollTimer;
  var _generation = 0;
  var _backgrounded = false;
  var _pollsWhileSocketDown = 0;

  static const _pollInterval = Duration(seconds: 20);
  static const _maxPollsWhileSocketDown = 30;

  @override
  OrderTrackingState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    unawaited(_teardownRealtime(keepState: false));
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
      unawaited(_teardownRealtime(keepState: false));
    });
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh(initial: true));
    });
    return const OrderTrackingState();
  }

  void setFocus(OrderTrackingFocus focus) {
    state = state.copyWith(focus: focus);
  }

  void onAppResumed() {
    _backgrounded = false;
    // Always refetch snapshot after resume; terminal stages stay terminal.
    unawaited(refresh());
  }

  void onAppBackgrounded() {
    _backgrounded = true;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh({bool initial = false}) async {
    final generation = _generation;
    state = state.copyWith(
      loading: initial || state.order == null,
      refreshing: !initial && state.order != null,
      clearError: true,
    );
    try {
      final order = await ref.read(ordersApiProvider).getOrder(orderId);
      if (generation != _generation) {
        return;
      }
      CustomerDeliveryDetail? delivery;
      var deliveryNotFound = false;
      try {
        delivery = await ref.read(ordersApiProvider).getDelivery(orderId);
        deliveryNotFound = delivery == null;
      } on ApiException catch (error) {
        if (error.code == 'ORDER_NOT_FOUND') {
          rethrow;
        }
        if (generation != _generation) {
          return;
        }
        state = state.copyWith(errorMessage: error.message);
      }

      TrackingSnapshot? tracking;
      if (delivery != null) {
        try {
          tracking = await ref.read(ordersApiProvider).getTracking(orderId);
        } catch (_) {
          tracking = null;
        }
      }

      if (generation != _generation) {
        return;
      }
      final stage = resolveOrderTrackingStage(
        order: order,
        delivery: delivery,
        deliveryNotFound: deliveryNotFound,
      );
      state = state.copyWith(
        loading: false,
        refreshing: false,
        order: order,
        delivery: delivery,
        clearDelivery: delivery == null,
        deliveryNotFound: deliveryNotFound,
        tracking: tracking,
        clearTracking: tracking == null,
        stage: stage,
        offline: false,
        lastLocationRecordedAt: tracking?.location?.recordedAt,
      );

      unawaited(ref.read(activeOrderControllerProvider.notifier).refresh());

      if (orderTrackingStageIsTerminal(stage)) {
        await _teardownRealtime(keepState: true);
        return;
      }
      await _connectRealtime(generation, delivery != null);
      _schedulePolling(generation);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loading: false,
        refreshing: false,
        errorMessage: error.message,
        offline: error.code == 'NETWORK_TIMEOUT' || error.code == 'OFFLINE',
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loading: false,
        refreshing: false,
        errorMessage: AppStrings.trackingLoadError,
      );
    }
  }

  Future<void> _connectRealtime(int generation, bool hasDelivery) async {
    if (!hasDelivery || orderTrackingStageIsTerminal(state.stage)) {
      await _teardownRealtime(keepState: true);
      return;
    }
    try {
      _socket ??= ref.read(trackingSocketFactoryProvider)(
        () async {
          return ref.read(sessionControllerProvider).tokens?.accessToken;
        },
      );
      await _locationSub?.cancel();
      await _statusSub?.cancel();
      await _errorSub?.cancel();
      await _connectionSub?.cancel();
      _locationSub = _socket!.locations.listen(_applyLocation);
      _statusSub = _socket!.statuses.listen(_applyTrackingSnapshot);
      _errorSub = _socket!.errors.listen((code) {
        if (generation != _generation) {
          return;
        }
        if (code == 'AUTH_INVALID_TOKEN' ||
            code == 'AUTH_SESSION_REVOKED' ||
            code == 'AUTH_SESSION_EXPIRED') {
          state = state.copyWith(
            socketConnected: false,
            offline: true,
            errorMessage: AppStrings.sessionExpired,
          );
          unawaited(_teardownRealtime(keepState: true));
          return;
        }
        state = state.copyWith(offline: true);
      });
      _connectionSub = _socket!.connection.listen((connected) {
        if (generation != _generation) {
          return;
        }
        state = state.copyWith(socketConnected: connected, offline: !connected);
        if (connected) {
          _pollsWhileSocketDown = 0;
        }
      });

      final snapshot = await _socket!.subscribe(orderId);
      if (generation != _generation) {
        return;
      }
      if (snapshot != null) {
        _applyTrackingSnapshot(snapshot);
      }
      state = state.copyWith(socketConnected: true, offline: false);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(socketConnected: false, offline: true);
    }
  }

  void _applyLocation(TrackingLocation location) {
    final previous = state.lastLocationRecordedAt;
    if (!shouldAcceptRecordedAt(
      previousRecordedAt: previous,
      incomingRecordedAt: location.recordedAt,
    )) {
      return;
    }
    state = state.copyWith(
      tracking: TrackingSnapshot(
        deliveryId: location.deliveryId,
        orderId: orderId,
        driverAssigned: true,
        assignedDriverId: location.assignedDriverId,
        status: 'LIVE',
        isStale: false,
        location: location,
      ),
      lastLocationRecordedAt: location.recordedAt,
      offline: false,
    );
  }

  void _applyTrackingSnapshot(TrackingSnapshot snapshot) {
    final incoming = snapshot.location?.recordedAt;
    final previous = state.lastLocationRecordedAt;
    if (incoming != null && previous != null) {
      final prevAt = DateTime.tryParse(previous)?.toUtc();
      final nextAt = DateTime.tryParse(incoming)?.toUtc();
      if (prevAt != null &&
          nextAt != null &&
          nextAt.isBefore(prevAt) &&
          snapshot.status == 'LIVE') {
        return;
      }
    }
    state = state.copyWith(
      tracking: snapshot,
      lastLocationRecordedAt: incoming ?? state.lastLocationRecordedAt,
      offline: false,
    );
  }

  void _schedulePolling(int generation) {
    _pollTimer?.cancel();
    if (orderTrackingStageIsTerminal(state.stage) || _backgrounded) {
      return;
    }
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (generation != _generation || _backgrounded) {
        return;
      }
      if (state.socketConnected) {
        _pollsWhileSocketDown = 0;
        return;
      }
      _pollsWhileSocketDown += 1;
      if (_pollsWhileSocketDown > _maxPollsWhileSocketDown) {
        _pollTimer?.cancel();
        _pollTimer = null;
        return;
      }
      unawaited(refresh());
    });
  }

  Future<void> _teardownRealtime({required bool keepState}) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _locationSub?.cancel();
    await _statusSub?.cancel();
    await _errorSub?.cancel();
    await _connectionSub?.cancel();
    _locationSub = null;
    _statusSub = null;
    _errorSub = null;
    _connectionSub = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.unsubscribe();
      } catch (_) {}
      await socket.disconnect();
      await socket.dispose();
    }
    if (keepState && ref.mounted) {
      state = state.copyWith(socketConnected: false);
    }
  }
}

final trackingSocketFactoryProvider = Provider<TrackingSocketFactory>((ref) {
  return (tokenProvider) => TrackingSocketClient(tokenProvider: tokenProvider);
});

typedef TrackingSocketFactory = TrackingRealtimeClient Function(
  TrackingTokenProvider tokenProvider,
);

final orderTrackingControllerProvider = NotifierProvider.autoDispose
    .family<OrderTrackingController, OrderTrackingState, String>(
      OrderTrackingController.new,
    );
