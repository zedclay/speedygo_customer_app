import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_controller.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_payment_method.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_api.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

enum OrderSubmissionPhase {
  idle,
  refreshing,
  submitting,
  reconfirmationRequired,
  pendingVerification,
  failed,
}

class OrderSubmissionState {
  const OrderSubmissionState({
    this.phase = OrderSubmissionPhase.idle,
    this.error,
    this.errorCode,
    this.reconfirmationMessage,
    this.submittedAt,
    this.expectedCustomerTotalMinor,
    this.paymentMethod,
  });

  final OrderSubmissionPhase phase;
  final String? error;
  final String? errorCode;
  final String? reconfirmationMessage;
  final DateTime? submittedAt;
  final String? expectedCustomerTotalMinor;
  final String? paymentMethod;

  bool get busy =>
      phase == OrderSubmissionPhase.refreshing ||
      phase == OrderSubmissionPhase.submitting;

  OrderSubmissionState copyWith({
    OrderSubmissionPhase? phase,
    String? error,
    String? errorCode,
    String? reconfirmationMessage,
    DateTime? submittedAt,
    String? expectedCustomerTotalMinor,
    String? paymentMethod,
    bool clearError = false,
    bool clearReconfirmation = false,
  }) {
    return OrderSubmissionState(
      phase: phase ?? this.phase,
      error: clearError ? null : (error ?? this.error),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      reconfirmationMessage: clearReconfirmation
          ? null
          : (reconfirmationMessage ?? this.reconfirmationMessage),
      submittedAt: submittedAt ?? this.submittedAt,
      expectedCustomerTotalMinor:
          expectedCustomerTotalMinor ?? this.expectedCustomerTotalMinor,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class OrderSubmissionController extends Notifier<OrderSubmissionState> {
  var _inFlight = false;
  String? _displayedFingerprint;

  @override
  OrderSubmissionState build() {
    ref.listen(checkoutControllerProvider, (previous, next) {
      if (next.hasCurrentTotals) {
        _displayedFingerprint = checkoutPreviewFingerprint(next.preview!);
      }
      if (!_inFlight &&
          (next.error != null ||
              (!next.loading && !next.hasCurrentTotals && previous?.preview != null))) {
        state = state.copyWith(
          phase: OrderSubmissionPhase.idle,
          clearError: true,
          clearReconfirmation: true,
        );
      }
    });
    return const OrderSubmissionState();
  }

  void reset() {
    _inFlight = false;
    state = const OrderSubmissionState();
  }

  Future<OrderDetail?> submit() async {
    if (_inFlight ||
        state.phase == OrderSubmissionPhase.pendingVerification) {
      return null;
    }
    final payment = ref.read(checkoutPaymentMethodProvider);
    final availability = ref.read(electronicPaymentAvailabilityProvider);
    if (!payment.isSelectable(availability)) {
      // Stale ELECTRONIC (or other unavailable): do not rewrite selection or POST.
      state = OrderSubmissionState(
        phase: OrderSubmissionPhase.failed,
        error: AppStrings.checkoutPaymentMethodUnavailable,
        errorCode: 'PAYMENT_METHOD_UNAVAILABLE',
        paymentMethod: payment.apiValue,
      );
      return null;
    }
    final checkout = ref.read(checkoutControllerProvider);
    if (!checkout.hasCurrentTotals ||
        checkout.addressId == null ||
        checkout.preview == null) {
      return null;
    }

    final heldPreview = checkout.preview;
    final reconfirming =
        state.phase == OrderSubmissionPhase.reconfirmationRequired;

    _inFlight = true;
    final priorFingerprint = _displayedFingerprint;
    state = state.copyWith(
      phase: OrderSubmissionPhase.refreshing,
      clearError: true,
      clearReconfirmation: true,
    );
    try {
      await ref.read(checkoutControllerProvider.notifier).refresh();
      final refreshed = ref.read(checkoutControllerProvider);
      if (!refreshed.hasCurrentTotals ||
          refreshed.addressId == null ||
          refreshed.preview == null) {
        if (reconfirming &&
            heldPreview != null &&
            !isPromotionCheckoutError(refreshed.errorCode)) {
          ref.read(checkoutControllerProvider.notifier).applyPreview(
            heldPreview,
            syncPromo: true,
          );
          _displayedFingerprint = checkoutPreviewFingerprint(heldPreview);
          state = OrderSubmissionState(
            phase: OrderSubmissionPhase.reconfirmationRequired,
            reconfirmationMessage: AppStrings.orderReconfirmationRequired,
          );
          return null;
        }
        state = OrderSubmissionState(
          phase: OrderSubmissionPhase.failed,
          error: refreshed.error ?? AppStrings.unexpected,
          errorCode: refreshed.errorCode,
        );
        return null;
      }
      final fingerprint = checkoutPreviewFingerprint(refreshed.preview!);
      _displayedFingerprint = fingerprint;
      if (priorFingerprint != null && priorFingerprint != fingerprint) {
        state = OrderSubmissionState(
          phase: OrderSubmissionPhase.reconfirmationRequired,
          reconfirmationMessage: AppStrings.checkoutReconfirmRequired,
        );
        return null;
      }

      state = state.copyWith(phase: OrderSubmissionPhase.submitting);
      final request = CreateOrderRequest.fromPreview(
        preview: refreshed.preview!,
        addressId: refreshed.addressId!,
        paymentMethod: payment.apiValue,
        promoCode: refreshed.requestedPromoCode,
      );
      final submittedAt = DateTime.now().toUtc();
      state = state.copyWith(
        submittedAt: submittedAt,
        expectedCustomerTotalMinor: request.expectedCustomerTotalMinor.toString(),
        paymentMethod: request.paymentMethod,
      );
      final order = await ref.read(ordersApiProvider).createOrder(request);
      await _afterSuccess();
      state = const OrderSubmissionState();
      return order;
    } on OrderReconfirmationException catch (error) {
      await _applyReconfirmation(error);
      return null;
    } on AppException catch (error) {
      if (isOrderSubmissionUncertain(error)) {
        final reconciled = await _reconcileUncertain();
        if (reconciled != null) {
          await _afterSuccess();
          state = const OrderSubmissionState();
          return reconciled;
        }
        state = OrderSubmissionState(
          phase: OrderSubmissionPhase.pendingVerification,
          submittedAt: state.submittedAt,
          expectedCustomerTotalMinor: state.expectedCustomerTotalMinor,
          paymentMethod: state.paymentMethod,
        );
        return null;
      }
      state = OrderSubmissionState(
        phase: OrderSubmissionPhase.failed,
        error: error.message,
        errorCode: error.code,
      );
      return null;
    } catch (_) {
      final reconciled = await _reconcileUncertain();
      if (reconciled != null) {
        await _afterSuccess();
        state = const OrderSubmissionState();
        return reconciled;
      }
      state = OrderSubmissionState(
        phase: OrderSubmissionPhase.pendingVerification,
        submittedAt: state.submittedAt,
        expectedCustomerTotalMinor: state.expectedCustomerTotalMinor,
        paymentMethod: state.paymentMethod,
      );
      return null;
    } finally {
      _inFlight = false;
    }
  }

  Future<OrderDetail?> retryVerification() async {
    if (_inFlight) {
      return null;
    }
    _inFlight = true;
    state = state.copyWith(
      phase: OrderSubmissionPhase.refreshing,
      clearError: true,
    );
    try {
      final reconciled = await _reconcileUncertain();
      if (reconciled != null) {
        await _afterSuccess();
        state = const OrderSubmissionState();
        return reconciled;
      }
      state = state.copyWith(phase: OrderSubmissionPhase.pendingVerification);
      return null;
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _applyReconfirmation(OrderReconfirmationException error) async {
    final checkout = ref.read(checkoutControllerProvider);
    final preview = checkout.preview;
    CheckoutPreview? authoritative;
    if (preview != null && error.current.totalsReconcile) {
      authoritative = error.current.applyTo(preview);
      ref.read(checkoutControllerProvider.notifier).applyPreview(
        authoritative,
        syncPromo: true,
      );
      _displayedFingerprint = checkoutPreviewFingerprint(authoritative);
    }
    state = OrderSubmissionState(
      phase: OrderSubmissionPhase.reconfirmationRequired,
      reconfirmationMessage: AppStrings.orderReconfirmationRequired,
    );
    await ref.read(checkoutControllerProvider.notifier).refresh();
    final next = ref.read(checkoutControllerProvider);
    if (next.hasCurrentTotals) {
      _displayedFingerprint = checkoutPreviewFingerprint(next.preview!);
      return;
    }
    if (isPromotionCheckoutError(next.errorCode)) {
      return;
    }
    if (authoritative != null) {
      ref.read(checkoutControllerProvider.notifier).applyPreview(
        authoritative,
        syncPromo: true,
      );
      _displayedFingerprint = checkoutPreviewFingerprint(authoritative);
    }
  }

  Future<OrderDetail?> _reconcileUncertain() async {
    final expectedTotal = state.expectedCustomerTotalMinor;
    final paymentMethod = state.paymentMethod;
    final submittedAt = state.submittedAt;
    if (expectedTotal == null ||
        paymentMethod == null ||
        submittedAt == null) {
      return null;
    }
    try {
      final page = await ref.read(ordersApiProvider).listOrders(limit: 5);
      OrderDetail? match;
      for (final summary in page.items) {
        if (summary.status != 'CREATED') {
          continue;
        }
        final detail = await ref.read(ordersApiProvider).getOrder(summary.id);
        if (detail.paymentMethod != paymentMethod) {
          continue;
        }
        if (detail.financial.customerTotalMinor != expectedTotal) {
          continue;
        }
        if (!detail.awaitingMerchantAcceptance) {
          continue;
        }
        final createdAt = DateTime.tryParse(detail.createdAt)?.toUtc();
        if (createdAt == null) {
          continue;
        }
        if (createdAt.isBefore(submittedAt.subtract(const Duration(seconds: 30)))) {
          continue;
        }
        if (match != null) {
          return null;
        }
        match = detail;
      }
      return match;
    } catch (_) {
      return null;
    }
  }

  Future<void> _afterSuccess() async {
    await Future.wait<void>([
      ref.read(cartControllerProvider.notifier).refresh(),
      ref.read(activeOrderControllerProvider.notifier).refresh(),
      ref.read(checkoutControllerProvider.notifier).refresh(),
    ]);
  }
}

final orderSubmissionControllerProvider =
    NotifierProvider<OrderSubmissionController, OrderSubmissionState>(
      OrderSubmissionController.new,
    );
