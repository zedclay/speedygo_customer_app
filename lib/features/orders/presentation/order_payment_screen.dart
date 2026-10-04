import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';
import 'package:speedygo_customer_app/features/orders/application/electronic_payment_controller.dart';

/// Electronic payment status + initiate (paiement / soumission references).
class OrderPaymentScreen extends ConsumerStatefulWidget {
  const OrderPaymentScreen({
    super.key,
    required this.orderId,
    this.autoRedirect = false,
  });

  final String orderId;
  final bool autoRedirect;

  @override
  ConsumerState<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends ConsumerState<OrderPaymentScreen>
    with WidgetsBindingObserver {
  var _didAutoRedirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(
      electronicPaymentControllerProvider(widget.orderId).notifier,
    );
    if (state == AppLifecycleState.resumed) {
      notifier.onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      notifier.onAppBackgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(
      electronicPaymentControllerProvider(widget.orderId),
    );
    ref.listen(electronicPaymentControllerProvider(widget.orderId), (
      previous,
      next,
    ) {
      if (widget.autoRedirect &&
          !_didAutoRedirect &&
          next.phase == ElectronicPaymentPhase.ready &&
          next.payment?.canInitiate == true) {
        _didAutoRedirect = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref
              .read(
                electronicPaymentControllerProvider(widget.orderId).notifier,
              )
              .initiateAndOpenCheckout();
        });
      }
      if (next.phase == ElectronicPaymentPhase.succeeded &&
          previous?.phase != ElectronicPaymentPhase.succeeded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          context.go(AppRoutes.orderConfirmation(widget.orderId));
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.autoRedirect
              ? AppStrings.paymentRedirectTitle
              : AppStrings.paymentTitle,
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.paymentRefresh,
            onPressed: payment.busy
                ? null
                : () => ref
                      .read(
                        electronicPaymentControllerProvider(
                          widget.orderId,
                        ).notifier,
                      )
                      .refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: payment.phase == ElectronicPaymentPhase.loading &&
              payment.payment == null
          ? const Center(child: CircularProgressIndicator())
          : _body(context, payment),
      bottomNavigationBar: _actions(context, payment),
    );
  }

  Widget _body(BuildContext context, ElectronicPaymentState payment) {
    final status = payment.payment?.status;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (payment.order != null) ...[
          Text(
            payment.order!.publicReference,
            key: const Key('payment-order-reference'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _statusHero(context, payment),
        const SizedBox(height: 16),
        if (payment.payment != null) ...[
          _row(
            context,
            AppStrings.paymentAmountLabel,
            MoneyFormat.dzd(payment.payment!.amountMinor),
            key: 'payment-amount',
          ),
          const SizedBox(height: 8),
          _row(
            context,
            AppStrings.paymentStatusLabel,
            _statusLabel(status),
            key: 'payment-status',
          ),
          if (payment.attemptId != null) ...[
            const SizedBox(height: 8),
            _row(
              context,
              AppStrings.paymentAttemptLabel,
              payment.attemptId!,
              key: 'payment-attempt',
            ),
          ],
          if (payment.payment!.provider != null) ...[
            const SizedBox(height: 8),
            _row(
              context,
              AppStrings.paymentProviderLabel,
              payment.payment!.provider!,
            ),
          ],
        ],
        if (payment.browserReturnHint) ...[
          const SizedBox(height: 16),
          _banner(AppStrings.paymentBrowserReturnHint, AppColors.primary),
        ],
        if (payment.errorMessage != null) ...[
          const SizedBox(height: 16),
          _banner(
            payment.errorMessage!,
            payment.errorCode == 'PAYMENT_TEST_CHECKOUT'
                ? AppColors.primary
                : AppColors.error,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          AppStrings.paymentSuccessDistinctHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _statusHero(BuildContext context, ElectronicPaymentState payment) {
    final (icon, title, body) = switch (payment.phase) {
      ElectronicPaymentPhase.succeeded => (
        Icons.check_circle,
        AppStrings.paymentSucceededTitle,
        AppStrings.paymentSucceededBody,
      ),
      ElectronicPaymentPhase.cancelled => (
        Icons.cancel,
        AppStrings.paymentCancelledTitle,
        AppStrings.paymentCancelledBody,
      ),
      ElectronicPaymentPhase.failed => (
        Icons.error_outline,
        AppStrings.paymentFailedTitle,
        AppStrings.paymentFailedBody,
      ),
      ElectronicPaymentPhase.awaitingProvider ||
      ElectronicPaymentPhase.polling ||
      ElectronicPaymentPhase.initiating => (
        Icons.account_balance,
        AppStrings.paymentPendingTitle,
        AppStrings.paymentPendingBody,
      ),
      _ => (
        Icons.credit_card,
        AppStrings.paymentReadyTitle,
        AppStrings.paymentReadyBody,
      ),
    };
    return DecoratedBox(
      key: const Key('payment-status-hero'),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _actions(BuildContext context, ElectronicPaymentState payment) {
    if (payment.phase == ElectronicPaymentPhase.succeeded) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            key: const Key('payment-go-confirmation'),
            onPressed: () =>
                context.go(AppRoutes.orderConfirmation(widget.orderId)),
            child: const Text(AppStrings.paymentGoConfirmation),
          ),
        ),
      );
    }
    final availability = ref.watch(electronicPaymentAvailabilityProvider);
    final canPay = availability.enabledForCheckout &&
        payment.payment?.canInitiate == true &&
        !payment.busy &&
        payment.phase != ElectronicPaymentPhase.initiating;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              key: const Key('payment-initiate'),
              onPressed: canPay
                  ? () => ref
                        .read(
                          electronicPaymentControllerProvider(
                            widget.orderId,
                          ).notifier,
                        )
                        .initiateAndOpenCheckout()
                  : null,
              child: Text(
                payment.phase == ElectronicPaymentPhase.initiating
                    ? AppStrings.paymentInitiating
                    : AppStrings.paymentPayNow,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('payment-check-status'),
              onPressed: payment.busy
                  ? null
                  : () => ref
                        .read(
                          electronicPaymentControllerProvider(
                            widget.orderId,
                          ).notifier,
                        )
                        .refresh(),
              child: const Text(AppStrings.paymentCheckStatus),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'PENDING':
        return AppStrings.paymentStatusPending;
      case 'PROCESSING':
        return AppStrings.paymentStatusProcessing;
      case 'SUCCEEDED':
        return AppStrings.paymentStatusSucceeded;
      case 'FAILED':
        return AppStrings.paymentStatusFailed;
      case 'CANCELLED':
        return AppStrings.paymentStatusCancelled;
      default:
        return status ?? AppStrings.paymentStatusUnknown;
    }
  }

  Widget _banner(String message, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    String? key,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            key: key == null ? null : Key(key),
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
