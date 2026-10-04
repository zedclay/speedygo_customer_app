import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/config/electronic_payment_config.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';
import 'package:url_launcher/url_launcher.dart';

enum ElectronicPaymentPhase {
  loading,
  ready,
  initiating,
  awaitingProvider,
  polling,
  succeeded,
  failed,
  cancelled,
  error,
}

class ElectronicPaymentState {
  const ElectronicPaymentState({
    this.phase = ElectronicPaymentPhase.loading,
    this.order,
    this.payment,
    this.attemptId,
    this.checkoutUrl,
    this.errorMessage,
    this.errorCode,
    this.offline = false,
    this.browserReturnHint = false,
  });

  final ElectronicPaymentPhase phase;
  final OrderDetail? order;
  final CustomerPayment? payment;
  final String? attemptId;
  final String? checkoutUrl;
  final String? errorMessage;
  final String? errorCode;
  final bool offline;
  final bool browserReturnHint;

  bool get busy =>
      phase == ElectronicPaymentPhase.loading ||
      phase == ElectronicPaymentPhase.initiating ||
      phase == ElectronicPaymentPhase.polling;

  bool get isTerminal =>
      phase == ElectronicPaymentPhase.succeeded ||
      phase == ElectronicPaymentPhase.failed ||
      phase == ElectronicPaymentPhase.cancelled;

  ElectronicPaymentState copyWith({
    ElectronicPaymentPhase? phase,
    OrderDetail? order,
    CustomerPayment? payment,
    String? attemptId,
    String? checkoutUrl,
    bool clearCheckout = false,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    bool? offline,
    bool? browserReturnHint,
  }) {
    return ElectronicPaymentState(
      phase: phase ?? this.phase,
      order: order ?? this.order,
      payment: payment ?? this.payment,
      attemptId: attemptId ?? this.attemptId,
      checkoutUrl: clearCheckout ? null : (checkoutUrl ?? this.checkoutUrl),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      offline: offline ?? this.offline,
      browserReturnHint: browserReturnHint ?? this.browserReturnHint,
    );
  }
}

class ElectronicPaymentController extends Notifier<ElectronicPaymentState> {
  ElectronicPaymentController(this.orderId);

  final String orderId;

  var _generation = 0;
  var _initiateInFlight = false;
  var _backgrounded = false;
  Timer? _pollTimer;
  var _pollCount = 0;

  static const _pollInterval = Duration(seconds: 4);
  static const _maxPolls = 45;

  @override
  ElectronicPaymentState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _pollTimer?.cancel();
    _pollTimer = null;
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh(initial: true));
    });
    return const ElectronicPaymentState();
  }

  void onAppResumed() {
    _backgrounded = false;
    state = state.copyWith(browserReturnHint: true);
    unawaited(refresh());
  }

  void onAppBackgrounded() {
    _backgrounded = true;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh({bool initial = false}) async {
    final generation = _generation;
    if (initial || state.order == null) {
      state = state.copyWith(
        phase: ElectronicPaymentPhase.loading,
        clearError: true,
      );
    }
    try {
      final order = await ref.read(ordersApiProvider).getOrder(orderId);
      if (generation != _generation) {
        return;
      }
      if (order.paymentMethod != 'ELECTRONIC') {
        state = state.copyWith(
          phase: ElectronicPaymentPhase.error,
          order: order,
          errorMessage: AppStrings.paymentNotElectronic,
          errorCode: 'PAYMENT_METHOD_NOT_ELECTRONIC',
        );
        _stopPolling();
        return;
      }
      final payment = await ref.read(ordersApiProvider).getPayment(orderId);
      if (generation != _generation) {
        return;
      }
      _applyPayment(order: order, payment: payment, generation: generation);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: ElectronicPaymentPhase.error,
        errorMessage: error.message,
        errorCode: error.code,
        offline: error.code == 'NETWORK_TIMEOUT' || error.code == 'OFFLINE',
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: ElectronicPaymentPhase.error,
        errorMessage: AppStrings.paymentLoadError,
      );
    }
  }

  Future<void> initiateAndOpenCheckout() async {
    if (_initiateInFlight || state.isTerminal) {
      return;
    }
    if (state.payment != null && !state.payment!.canInitiate) {
      return;
    }
    final availability = ref.read(electronicPaymentAvailabilityProvider);
    if (!availability.enabledForCheckout) {
      // Existing electronic orders stay readable; do not start another attempt.
      state = state.copyWith(
        errorMessage: AppStrings.paymentInitiateDisabled,
        errorCode: 'PAYMENT_INITIATE_DISABLED',
      );
      return;
    }
    _initiateInFlight = true;
    final generation = _generation;
    state = state.copyWith(
      phase: ElectronicPaymentPhase.initiating,
      clearError: true,
      browserReturnHint: false,
    );
    try {
      final initiated =
          await ref.read(ordersApiProvider).initiatePayment(orderId);
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        payment: initiated.asPayment,
        attemptId: initiated.attemptId,
        checkoutUrl: initiated.checkoutUrl,
        clearCheckout: initiated.checkoutUrl == null,
      );
      if (initiated.isSucceeded) {
        state = state.copyWith(phase: ElectronicPaymentPhase.succeeded);
        _stopPolling();
        return;
      }
      final decision = evaluateCheckoutUrl(
        initiated.checkoutUrl,
        availability,
      );
      if (checkoutUrlIsLaunchable(decision)) {
        final opened = await _openCheckout(initiated.checkoutUrl!);
        state = state.copyWith(
          phase: ElectronicPaymentPhase.awaitingProvider,
          browserReturnHint: opened,
        );
      } else {
        state = state.copyWith(
          phase: ElectronicPaymentPhase.awaitingProvider,
          errorMessage: _checkoutRejectionMessage(decision),
          errorCode: _checkoutRejectionCode(decision),
        );
      }
      _schedulePolling(generation);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      if (error.code == 'PAYMENT_ALREADY_SUCCEEDED') {
        await refresh();
        return;
      }
      // Uncertain initiate: do not invent a second order; reconcile via GET.
      if (_isUncertainPaymentMutation(error)) {
        state = state.copyWith(
          phase: ElectronicPaymentPhase.polling,
          errorMessage: AppStrings.paymentInitiateUncertain,
          errorCode: error.code,
        );
        _schedulePolling(generation);
        return;
      }
      state = state.copyWith(
        phase: ElectronicPaymentPhase.error,
        errorMessage: error.message,
        errorCode: error.code,
        offline: error.code == 'NETWORK_TIMEOUT' || error.code == 'OFFLINE',
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: ElectronicPaymentPhase.polling,
        errorMessage: AppStrings.paymentInitiateUncertain,
      );
      _schedulePolling(generation);
    } finally {
      _initiateInFlight = false;
    }
  }

  String _checkoutRejectionMessage(CheckoutUrlDecision decision) {
    switch (decision) {
      case CheckoutUrlDecision.acknowledgeTestScheme:
        return AppStrings.paymentTestCheckoutHint;
      case CheckoutUrlDecision.rejectTestScheme:
        return AppStrings.paymentCheckoutRejectedTest;
      case CheckoutUrlDecision.rejectHttp:
        return AppStrings.paymentCheckoutRejectedHttp;
      case CheckoutUrlDecision.rejectUnapprovedHost:
        return AppStrings.paymentCheckoutRejectedHost;
      case CheckoutUrlDecision.rejectMissing:
      case CheckoutUrlDecision.rejectInvalid:
      case CheckoutUrlDecision.openHttps:
        return AppStrings.paymentCheckoutMissing;
    }
  }

  String _checkoutRejectionCode(CheckoutUrlDecision decision) {
    switch (decision) {
      case CheckoutUrlDecision.acknowledgeTestScheme:
        return 'PAYMENT_TEST_CHECKOUT';
      case CheckoutUrlDecision.rejectTestScheme:
        return 'PAYMENT_CHECKOUT_REJECTED_TEST';
      case CheckoutUrlDecision.rejectHttp:
        return 'PAYMENT_CHECKOUT_REJECTED_HTTP';
      case CheckoutUrlDecision.rejectUnapprovedHost:
        return 'PAYMENT_CHECKOUT_REJECTED_HOST';
      case CheckoutUrlDecision.rejectMissing:
      case CheckoutUrlDecision.rejectInvalid:
      case CheckoutUrlDecision.openHttps:
        return 'PAYMENT_CHECKOUT_MISSING';
    }
  }

  Future<bool> _openCheckout(String url) async {
    final uri = Uri.parse(url);
    // Never attach SpeedyGo auth headers — external launch only.
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _applyPayment({
    required OrderDetail order,
    required CustomerPayment payment,
    required int generation,
  }) {
    final phase = switch (payment.status) {
      'SUCCEEDED' => ElectronicPaymentPhase.succeeded,
      'CANCELLED' => ElectronicPaymentPhase.cancelled,
      'FAILED' => ElectronicPaymentPhase.failed,
      'PROCESSING' => ElectronicPaymentPhase.awaitingProvider,
      'PENDING' => ElectronicPaymentPhase.ready,
      _ => ElectronicPaymentPhase.ready,
    };
    state = state.copyWith(
      phase: phase,
      order: order,
      payment: payment,
      offline: false,
      clearError: phase == ElectronicPaymentPhase.succeeded,
    );
    if (paymentStatusIsTerminal(payment.status)) {
      _stopPolling();
      return;
    }
    if (payment.status == 'PROCESSING' ||
        state.checkoutUrl != null ||
        state.browserReturnHint) {
      _schedulePolling(generation);
    }
  }

  void _schedulePolling(int generation) {
    if (_backgrounded || generation != _generation) {
      return;
    }
    if (state.isTerminal) {
      return;
    }
    _pollTimer?.cancel();
    _pollCount = 0;
    state = state.copyWith(phase: ElectronicPaymentPhase.polling);
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_pollOnce(generation));
    });
  }

  Future<void> _pollOnce(int generation) async {
    if (generation != _generation || _backgrounded) {
      return;
    }
    _pollCount += 1;
    if (_pollCount > _maxPolls) {
      _stopPolling();
      state = state.copyWith(
        phase: ElectronicPaymentPhase.awaitingProvider,
        errorMessage: AppStrings.paymentPollingPaused,
      );
      return;
    }
    try {
      final payment = await ref.read(ordersApiProvider).getPayment(orderId);
      if (generation != _generation) {
        return;
      }
      final order = state.order ??
          await ref.read(ordersApiProvider).getOrder(orderId);
      if (generation != _generation) {
        return;
      }
      _applyPayment(order: order, payment: payment, generation: generation);
    } catch (_) {
      // Keep last known state; next tick retries.
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}

bool _isUncertainPaymentMutation(AppException error) {
  return error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'PAYMENT_INITIATE_SERVER_UNCERTAIN' ||
      (error.statusCode != null && error.statusCode! >= 500);
}

final electronicPaymentControllerProvider = NotifierProvider.family<
  ElectronicPaymentController,
  ElectronicPaymentState,
  String
>(ElectronicPaymentController.new);
