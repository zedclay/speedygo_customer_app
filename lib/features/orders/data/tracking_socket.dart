import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';

typedef TrackingTokenProvider = Future<String?> Function();

/// Realtime tracking transport. Reconnect must re-auth and resubscribe.
abstract class TrackingRealtimeClient {
  Stream<TrackingLocation> get locations;
  Stream<TrackingSnapshot> get statuses;
  Stream<String> get errors;
  Stream<bool> get connection;
  bool get isConnected;
  String? get subscribedOrderId;
  Future<TrackingSnapshot?> subscribe(String orderId);
  Future<void> unsubscribe();
  Future<void> disconnect();
  Future<void> dispose();
}

/// Socket.IO client for `/realtime` Customer tracking subscribe.
class TrackingSocketClient implements TrackingRealtimeClient {
  TrackingSocketClient({
    required this._tokenProvider,
    String? origin,
  }) : _origin = origin ?? ApiEndpoints.realtimeOrigin();

  final TrackingTokenProvider _tokenProvider;
  final String _origin;

  io.Socket? _socket;
  String? _subscribedOrderId;
  var _generation = 0;

  final _locationController = StreamController<TrackingLocation>.broadcast();
  final _statusController = StreamController<TrackingSnapshot>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  @override
  Stream<TrackingLocation> get locations => _locationController.stream;
  @override
  Stream<TrackingSnapshot> get statuses => _statusController.stream;
  @override
  Stream<String> get errors => _errorController.stream;
  @override
  Stream<bool> get connection => _connectionController.stream;

  @override
  bool get isConnected => _socket?.connected == true;
  @override
  String? get subscribedOrderId => _subscribedOrderId;

  @override
  Future<TrackingSnapshot?> subscribe(String orderId) async {
    final generation = ++_generation;
    await _ensureConnected(generation);
    if (generation != _generation) {
      return null;
    }
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw StateError('Tracking socket not connected');
    }
    return _emitSubscribe(socket, orderId, generation: generation);
  }

  Future<TrackingSnapshot?> _emitSubscribe(
    io.Socket socket,
    String orderId, {
    required int generation,
  }) {
    final completer = Completer<TrackingSnapshot?>();
    socket.emitWithAck(
      ApiEndpoints.trackingSubscribeEvent,
      {'orderId': orderId},
      ack: (dynamic response) {
        if (generation != _generation) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }
        if (response is! Map) {
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('Invalid tracking subscribe ack'),
            );
          }
          return;
        }
        final map = Map<String, dynamic>.from(response);
        if (map['ok'] != true) {
          final error = map['error'];
          final code = error is Map ? error['code']?.toString() : null;
          if (!completer.isCompleted) {
            completer.completeError(
              StateError(code ?? 'TRACKING_SUBSCRIBE_FAILED'),
            );
          }
          return;
        }
        _subscribedOrderId = orderId;
        final raw = map['snapshot'];
        if (raw is Map) {
          final snapshot = TrackingSnapshot.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (!completer.isCompleted) {
            completer.complete(snapshot);
          }
          return;
        }
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    return completer.future.timeout(const Duration(seconds: 8));
  }

  @override
  Future<void> unsubscribe() async {
    final socket = _socket;
    final orderId = _subscribedOrderId;
    _subscribedOrderId = null;
    if (socket == null || !socket.connected || orderId == null) {
      return;
    }
    final completer = Completer<void>();
    socket.emitWithAck(ApiEndpoints.trackingUnsubscribeEvent, {}, ack: (_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    try {
      await completer.future.timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  @override
  Future<void> disconnect() async {
    _generation += 1;
    _subscribedOrderId = null;
    final socket = _socket;
    _socket = null;
    socket?.dispose();
    _connectionController.add(false);
  }

  Future<void> _ensureConnected(int generation) async {
    if (_socket?.connected == true) {
      return;
    }
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('AUTH_INVALID_TOKEN');
    }
    if (generation != _generation) {
      return;
    }
    final previous = _socket;
    _socket = null;
    previous?.dispose();

    final socket = io.io(
      '$_origin${ApiEndpoints.realtimeNamespace}',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(500)
          .enableForceNew()
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      if (generation == _generation) {
        _connectionController.add(true);
      }
    });
    socket.onDisconnect((_) {
      if (generation == _generation) {
        _connectionController.add(false);
      }
    });
    socket.onReconnect((_) {
      if (generation != _generation) {
        return;
      }
      unawaited(_onReconnect(generation, socket));
    });
    socket.onConnectError((error) {
      if (generation == _generation) {
        _errorController.add(error.toString());
        _connectionController.add(false);
      }
    });
    socket.on(ApiEndpoints.trackingLocationEvent, (data) {
      if (generation != _generation || data is! Map) {
        return;
      }
      try {
        _locationController.add(
          TrackingLocation.fromJson(Map<String, dynamic>.from(data)),
        );
      } catch (_) {}
    });
    socket.on(ApiEndpoints.trackingStatusEvent, (data) {
      if (generation != _generation || data is! Map) {
        return;
      }
      try {
        final map = Map<String, dynamic>.from(data);
        // Status event omits orderId; keep last known / require caller merge.
        map.putIfAbsent('orderId', () => _subscribedOrderId ?? '');
        if ((map['orderId'] as String?)?.isEmpty ?? true) {
          return;
        }
        _statusController.add(TrackingSnapshot.fromJson(map));
      } catch (_) {}
    });
    socket.on(ApiEndpoints.trackingErrorEvent, (data) {
      if (generation != _generation) {
        return;
      }
      if (data is Map) {
        _errorController.add(data['code']?.toString() ?? 'TRACKING_ERROR');
      }
    });

    final connected = Completer<void>();
    socket.onConnect((_) {
      if (!connected.isCompleted) {
        connected.complete();
      }
    });
    socket.onConnectError((error) {
      if (!connected.isCompleted) {
        connected.completeError(error ?? 'connect_error');
      }
    });
    socket.connect();
    await connected.future.timeout(const Duration(seconds: 8));
  }

  Future<void> _onReconnect(int generation, io.Socket socket) async {
    if (generation != _generation) {
      return;
    }
    final token = await _tokenProvider();
    if (generation != _generation) {
      return;
    }
    if (token == null || token.isEmpty) {
      _errorController.add('AUTH_INVALID_TOKEN');
      _connectionController.add(false);
      return;
    }
    socket.auth = {'token': token};
    _connectionController.add(true);
    final orderId = _subscribedOrderId;
    if (orderId == null) {
      return;
    }
    try {
      await _emitSubscribe(socket, orderId, generation: generation);
    } catch (error) {
      if (generation == _generation) {
        _errorController.add(error.toString());
      }
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _locationController.close();
    await _statusController.close();
    await _errorController.close();
    await _connectionController.close();
  }
}
