import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/orders_list_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_api.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

enum OrderCancellationPhase {
  idle,
  submitting,
  accepted,
  rejected,
  pendingVerification,
}

class OrderCancellationState {
  const OrderCancellationState({
    this.phase = OrderCancellationPhase.idle,
    this.selectedReason,
    this.message,
    this.result,
    this.orderId,
  });

  final OrderCancellationPhase phase;
  final String? selectedReason;
  final String? message;
  final OrderCancellationResult? result;
  final String? orderId;

  bool get isBusy =>
      phase == OrderCancellationPhase.submitting ||
      phase == OrderCancellationPhase.pendingVerification;

  OrderCancellationState copyWith({
    OrderCancellationPhase? phase,
    String? selectedReason,
    bool clearReason = false,
    String? message,
    bool clearMessage = false,
    OrderCancellationResult? result,
    bool clearResult = false,
    String? orderId,
  }) {
    return OrderCancellationState(
      phase: phase ?? this.phase,
      selectedReason: clearReason
          ? null
          : (selectedReason ?? this.selectedReason),
      message: clearMessage ? null : (message ?? this.message),
      result: clearResult ? null : (result ?? this.result),
      orderId: orderId ?? this.orderId,
    );
  }
}

class OrderCancellationController
    extends Notifier<OrderCancellationState> {
  var _inFlight = false;
  var _generation = 0;
  String? _boundOrderId;

  @override
  OrderCancellationState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _inFlight = false;
    _boundOrderId = null;
    return const OrderCancellationState();
  }

  void bindOrder(String orderId) {
    if (_boundOrderId == orderId && state.orderId == orderId) {
      return;
    }
    _boundOrderId = orderId;
    state = OrderCancellationState(orderId: orderId);
  }

  void selectReason(String? reason) {
    if (_inFlight || state.phase == OrderCancellationPhase.accepted) {
      return;
    }
    state = state.copyWith(
      selectedReason: reason,
      clearReason: reason == null,
      phase: OrderCancellationPhase.idle,
      clearMessage: true,
    );
  }

  Future<OrderCancellationResult?> confirm(OrderDetail order) async {
    if (_inFlight) {
      return null;
    }
    if (state.phase == OrderCancellationPhase.pendingVerification ||
        state.phase == OrderCancellationPhase.accepted) {
      return null;
    }
    if (!order.canCustomerCancel) {
      state = state.copyWith(
        phase: OrderCancellationPhase.rejected,
        message: AppStrings.orderCancelNotEligible,
        orderId: order.id,
      );
      return null;
    }

    _inFlight = true;
    final generation = _generation;
    final orderId = order.id;
    _boundOrderId = orderId;
    state = state.copyWith(
      phase: OrderCancellationPhase.submitting,
      clearMessage: true,
      clearResult: true,
      orderId: orderId,
    );

    try {
      final result = await ref.read(ordersApiProvider).cancelOrder(
            orderId,
            reason: state.selectedReason,
          );
      if (!_isCurrent(generation, orderId)) {
        return null;
      }
      if (!result.cancellationAccepted || result.orderStatus != 'CANCELLED') {
        state = state.copyWith(
          phase: OrderCancellationPhase.rejected,
          message: AppStrings.orderCancelRejected,
          result: result,
        );
        return null;
      }
      await _afterAuthoritativeCancel(orderId, result, generation);
      if (!_isCurrent(generation, orderId)) {
        return null;
      }
      state = state.copyWith(
        phase: OrderCancellationPhase.accepted,
        message: _acceptedMessage(order.paymentMethod, result),
        result: result,
      );
      return result;
    } on AppException catch (error) {
      if (!_isCurrent(generation, orderId)) {
        return null;
      }
      if (isOrderCancellationUncertain(error)) {
        state = state.copyWith(
          phase: OrderCancellationPhase.pendingVerification,
          message: AppStrings.orderCancelPendingVerification,
        );
        return null;
      }
      state = state.copyWith(
        phase: OrderCancellationPhase.rejected,
        message: error.message,
      );
      return null;
    } catch (_) {
      if (!_isCurrent(generation, orderId)) {
        return null;
      }
      state = state.copyWith(
        phase: OrderCancellationPhase.rejected,
        message: AppStrings.unexpected,
      );
      return null;
    } finally {
      _inFlight = false;
    }
  }

  /// Read-only reconcile after timeout/5xx. Never re-POSTs cancel.
  Future<OrderCancellationResult?> retryVerification(OrderDetail order) async {
    if (_inFlight) {
      return null;
    }
    if (state.phase != OrderCancellationPhase.pendingVerification) {
      return null;
    }

    _inFlight = true;
    final generation = _generation;
    final orderId = order.id;
    state = state.copyWith(
      phase: OrderCancellationPhase.submitting,
      clearMessage: true,
      orderId: orderId,
    );

    try {
      final detail = await ref.read(ordersApiProvider).getOrder(orderId);
      if (!_isCurrent(generation, orderId)) {
        return null;
      }
      if (detail.isCancelled) {
        CustomerOrderRefunds? refunds;
        try {
          refunds = await ref.read(ordersApiProvider).listRefunds(orderId);
        } catch (_) {
          refunds = null;
        }
        if (!_isCurrent(generation, orderId)) {
          return null;
        }
        final result = OrderCancellationResult(
          orderId: orderId,
          orderStatus: detail.status,
          cancellationAccepted: true,
          refundRequired: refunds?.hasRefunds ?? false,
          refundId: refunds?.refunds.isNotEmpty == true
              ? refunds!.refunds.first.refundId
              : null,
          refundStatus: refunds?.refunds.isNotEmpty == true
              ? refunds!.refunds.first.status
              : null,
          refundAmountMinor: refunds?.refunds.isNotEmpty == true
              ? refunds!.refunds.first.amountMinor
              : null,
          cancelledAt: null,
        );
        await _afterAuthoritativeCancel(orderId, result, generation);
        if (!_isCurrent(generation, orderId)) {
          return null;
        }
        state = state.copyWith(
          phase: OrderCancellationPhase.accepted,
          message: _acceptedMessage(detail.paymentMethod, result),
          result: result,
        );
        return result;
      }
      if (detail.canCustomerCancel) {
        state = state.copyWith(
          phase: OrderCancellationPhase.idle,
          message: AppStrings.orderCancelPendingHint,
        );
        return null;
      }
      state = state.copyWith(
        phase: OrderCancellationPhase.rejected,
        message: AppStrings.orderCancelNotEligible,
      );
      return null;
    } on AppException catch (error) {
      if (!_isCurrent(generation, orderId)) {
        return null;
      }
      state = state.copyWith(
        phase: OrderCancellationPhase.pendingVerification,
        message: error.message,
      );
      return null;
    } catch (_) {
      if (!_isCurrent(generation, orderId)) {
        return null;
      }
      state = state.copyWith(
        phase: OrderCancellationPhase.pendingVerification,
        message: AppStrings.orderCancelPendingHint,
      );
      return null;
    } finally {
      _inFlight = false;
    }
  }

  bool _isCurrent(int generation, String orderId) {
    return generation == _generation && _boundOrderId == orderId;
  }

  String _acceptedMessage(String paymentMethod, OrderCancellationResult result) {
    if (paymentMethod == 'COD' && !result.refundRequired) {
      return '${AppStrings.orderCancelAccepted} ${AppStrings.orderCancelCodNoRefund}';
    }
    if (result.refundRequired) {
      return '${AppStrings.orderCancelAccepted} ${AppStrings.orderCancelElectronicRefundIntent}';
    }
    return AppStrings.orderCancelAccepted;
  }

  Future<void> _afterAuthoritativeCancel(
    String orderId,
    OrderCancellationResult result,
    int generation,
  ) async {
    ref.invalidate(orderDetailControllerProvider(orderId));
    ref.invalidate(orderRefundsControllerProvider(orderId));
    await Future.wait<void>([
      ref.read(ordersListControllerProvider.notifier).refresh(),
      ref.read(activeOrderControllerProvider.notifier).refresh(),
    ]);
    if (!_isCurrent(generation, orderId)) {
      return;
    }
    // Touch result so analyzer keeps the parameter meaningful for callers.
    assert(result.cancellationAccepted);
  }
}

final orderCancellationControllerProvider =
    NotifierProvider<OrderCancellationController, OrderCancellationState>(
      OrderCancellationController.new,
    );

final orderRefundsControllerProvider =
    FutureProvider.family<CustomerOrderRefunds?, String>((ref, orderId) async {
      ref.watch(catalogScopeProvider);
      final detail = await ref.watch(
        orderDetailControllerProvider(orderId).future,
      );
      if (!detail.isCancelled && detail.paymentMethod == 'COD') {
        // Unpaid COD open orders have no refund reads to surface.
        return null;
      }
      if (!detail.isCancelled) {
        return null;
      }
      try {
        final refunds = await ref.read(ordersApiProvider).listRefunds(orderId);
        return refunds;
      } on ApiException catch (error) {
        if (error.statusCode == 404) {
          return null;
        }
        rethrow;
      }
    });
