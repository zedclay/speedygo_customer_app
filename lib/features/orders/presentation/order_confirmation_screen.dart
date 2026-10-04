import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/orders/application/last_created_order.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/order_payment_snapshot.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cached = ref.watch(lastCreatedOrderProvider);
    final detail = ref.watch(orderDetailControllerProvider(orderId));
    final OrderDetail? order =
        (cached != null && cached.id == orderId) ? cached : detail.asData?.value;

    final paymentAsync = order?.paymentMethod == 'ELECTRONIC'
        ? ref.watch(orderPaymentSnapshotProvider(orderId))
        : null;
    final CustomerPayment? payment = paymentAsync?.asData?.value;
    final paymentLoading =
        order?.paymentMethod == 'ELECTRONIC' &&
        (paymentAsync?.isLoading ?? false);
    final needsContinue = _needsContinuePayment(
      order: order,
      payment: payment,
      paymentLoading: paymentLoading,
    );
    // Extra scroll inset so payment-status clears the sticky action column.
    final bottomClearance = needsContinue ? 180.0 : 140.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.orderConfirmationTitle),
      ),
      body: order != null
          ? _SuccessBody(
              order: order,
              payment: payment,
              paymentLoading: paymentLoading,
              bottomClearance: bottomClearance,
            )
          : detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _ErrorBody(
                onRetry: () =>
                    ref.invalidate(orderDetailControllerProvider(orderId)),
              ),
              data: (_) => _ErrorBody(
                onRetry: () =>
                    ref.invalidate(orderDetailControllerProvider(orderId)),
              ),
            ),
      bottomNavigationBar: order == null
          ? null
          : _ConfirmationActions(
              order: order,
              payment: payment,
              paymentLoading: paymentLoading,
            ),
    );
  }
}

bool _needsContinuePayment({
  required OrderDetail? order,
  required CustomerPayment? payment,
  required bool paymentLoading,
}) {
  if (order?.paymentMethod != 'ELECTRONIC') {
    return false;
  }
  if (paymentLoading) {
    return false;
  }
  if (payment?.isSucceeded == true) {
    return false;
  }
  return true;
}

class _ConfirmationActions extends StatelessWidget {
  const _ConfirmationActions({
    required this.order,
    required this.payment,
    required this.paymentLoading,
  });

  final OrderDetail order;
  final CustomerPayment? payment;
  final bool paymentLoading;

  bool get _showContinuePayment => _needsContinuePayment(
        order: order,
        payment: payment,
        paymentLoading: paymentLoading,
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showContinuePayment) ...[
                FilledButton(
                  key: const Key('order-confirmation-continue-payment'),
                  onPressed: () =>
                      context.push(AppRoutes.orderPayment(order.id)),
                  child: const Text(AppStrings.paymentContinue),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                key: const Key('order-confirmation-detail'),
                onPressed: () => context.go(AppRoutes.order(order.id)),
                style: _showContinuePayment
                    ? FilledButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        foregroundColor: AppColors.primary,
                      )
                    : null,
                child: const Text(AppStrings.orderConfirmationViewDetail),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('order-confirmation-home'),
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(AppStrings.orderConfirmationBackHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.order,
    required this.payment,
    required this.paymentLoading,
    required this.bottomClearance,
  });

  final OrderDetail order;
  final CustomerPayment? payment;
  final bool paymentLoading;
  final double bottomClearance;

  /// Payment status from payment aggregate only — never from fulfillment.
  String get _paymentStatusCopy {
    if (order.paymentMethod == 'COD') {
      return AppStrings.orderConfirmationNoPaymentCollected;
    }
    if (paymentLoading) {
      return AppStrings.orderConfirmationPaymentPending;
    }
    final status = payment?.status;
    switch (status) {
      case 'SUCCEEDED':
        return AppStrings.orderConfirmationPaymentSucceeded;
      case 'FAILED':
        return AppStrings.orderConfirmationPaymentFailed;
      case 'CANCELLED':
        return AppStrings.orderConfirmationPaymentCancelled;
      case 'PENDING':
      case 'PROCESSING':
        return AppStrings.orderConfirmationPaymentPending;
      default:
        // Missing GET / unknown — no paid claim.
        return AppStrings.orderConfirmationPaymentPending;
    }
  }

  /// Amount caption from authoritative payment state only.
  String get _amountCaption {
    if (order.paymentMethod == 'COD') {
      return AppStrings.orderConfirmationAmountCod;
    }
    if (payment?.isSucceeded == true) {
      return AppStrings.orderConfirmationAmountPaid;
    }
    // Pending / failed / cancelled / unknown electronic — no paid claim.
    return AppStrings.orderConfirmationAmountDue;
  }

  String get _itemsLine {
    if (order.items.isEmpty) {
      return AppStrings.orderItemsLabel;
    }
    final first = order.items.first.productNameSnapshot;
    if (order.items.length == 1) {
      final qty = order.items.first.quantity;
      return qty > 1 ? '$first × $qty' : first;
    }
    return '$first +${order.items.length - 1}';
  }

  String get _paymentMethodLabel {
    if (order.paymentMethod == 'COD') {
      return AppStrings.orderPaymentCod;
    }
    return AppStrings.orderPaymentElectronic;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const Key('order-confirmation-scroll'),
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomClearance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 36,
                color: AppColors.onTertiary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.orderConfirmationSent,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.orderReferenceLabel}: ${order.publicReference}',
            key: const Key('order-confirmation-reference'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.brandGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.orderConfirmationAwaitingMerchantShort,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.orderItemsLabel,
                              key: const Key('order-confirmation-articles'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _itemsLine,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            MoneyFormat.dzd(order.financial.customerTotalMinor),
                            key: const Key('order-confirmation-total'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _amountCaption,
                            key: const Key('order-confirmation-amount-caption'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _summaryRow(
                    context,
                    Icons.payments_outlined,
                    AppStrings.orderPaymentMethodLabel,
                    _paymentMethodLabel,
                  ),
                  const SizedBox(height: 10),
                  _summaryRow(
                    context,
                    Icons.home_outlined,
                    AppStrings.orderDeliveryAddressLabel,
                    order.deliveryAddress.addressText,
                  ),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: const Key('order-confirmation-payment-status'),
                    child: _summaryRow(
                      context,
                      Icons.info_outline,
                      AppStrings.paymentStatusLabel,
                      _paymentStatusCopy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.orderLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
