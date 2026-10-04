import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/orders/application/order_cancellation_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

/// Soft lift from Stitch `d_tails_de_la_commande_speedygo`.
const _kOrderCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailControllerProvider(orderId));
    final refunds = ref.watch(orderRefundsControllerProvider(orderId));
    final order = detail.asData?.value;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          AppStrings.orderDetailTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('order-detail-support-entry'),
            tooltip: AppStrings.supportReportProblem,
            onPressed: () => context.push(
              '${AppRoutes.supportNew}?orderId=${Uri.encodeQueryComponent(orderId)}',
            ),
            icon: const Icon(Icons.support_agent, color: AppColors.primary),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(AppStrings.orderLoadError),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(orderDetailControllerProvider(orderId)),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (order) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusHeader(order: order),
                const SizedBox(height: 24),
                _ItemsSection(order: order),
                const SizedBox(height: 24),
                _DeliveryCard(order: order),
                const SizedBox(height: 16),
                _TotalsCard(order: order),
                if (order.isCancelled) ...[
                  const SizedBox(height: 16),
                  _CancellationOutcome(order: order, refunds: refunds),
                ],
                if (order.awaitingMerchantAcceptance) ...[
                  const SizedBox(height: 16),
                  _AwaitingMerchantNote(order: order),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: order == null
          ? null
          : _StickyActions(order: order, orderId: orderId),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final status = activeOrderStatusLabel(
      fulfillmentStatus: order.fulfillmentStatus,
      orderStatus: order.status,
    );
    final icon = order.isCancelled
        ? Icons.cancel
        : order.status == 'COMPLETED'
        ? Icons.check_circle
        : Icons.schedule;
    final iconColor = order.isCancelled
        ? AppColors.error
        : order.status == 'COMPLETED'
        ? AppColors.tertiary
        : AppColors.primary;
    final iconBg = order.isCancelled
        ? AppColors.error.withValues(alpha: 0.12)
        : order.status == 'COMPLETED'
        ? AppColors.tertiaryFixed
        : AppColors.primary.withValues(alpha: 0.1);
    final dateLabel = _formatOrderDateTime(order.createdAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_kOrderCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              status,
              key: const Key('order-detail-status'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#${order.publicReference}',
              key: const Key('order-detail-reference'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AwaitingMerchantNote extends StatelessWidget {
  const _AwaitingMerchantNote({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.orderConfirmationAwaitingMerchant,
              key: const Key('order-detail-awaiting-merchant'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.paymentMethod == 'COD'
                  ? AppStrings.orderConfirmationNoPaymentCollected
                  : AppStrings.orderConfirmationPaymentPending,
              key: const Key('order-detail-no-payment'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              AppStrings.orderItemsOrderedLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [_kOrderCardShadow],
          ),
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ItemRow(
                    item: order.items[i],
                    merchantBranchId: order.merchantBranchId,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.merchantBranchId,
  });

  final OrderItemDetail item;
  final String merchantBranchId;

  @override
  Widget build(BuildContext context) {
    // Order DTO has no imageUrl snapshot; same path derivation as cart when
    // merchantBranchId + productId remain available (productId is nullable).
    final imageUrl = item.productId == null
        ? null
        : cartItemImageUrl(
            branchId: merchantBranchId,
            productId: item.productId!,
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthenticatedCatalogImage(
          imageUrl: imageUrl,
          fallbackLabel: item.productNameSnapshot,
          height: 64,
          width: 64,
          radius: 8,
          icon: Icons.fastfood_outlined,
          imageKey: Key('order-detail-item-image-${item.id}'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.productNameSnapshot}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    MoneyFormat.dzd(item.lineTotalMinor),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (item.options.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.options
                      .map((option) => option.optionNameSnapshot)
                      .join(', '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${MoneyFormat.dzd(item.unitPriceMinor)} ${AppStrings.orderUnitPriceLabel}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_kOrderCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.orderDeliveryPlaceLabel.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.deliveryAddress.addressText,
                    key: const Key('order-detail-address'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final paymentLabel = order.paymentMethod == 'COD'
        ? AppStrings.orderPaymentCod
        : AppStrings.orderPaymentElectronic;
    return DecoratedBox(
      key: const Key('order-detail-totals'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_kOrderCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.orderPaymentDetailsTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.payments, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  paymentLabel,
                  key: const Key('order-detail-payment'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Divider(
              height: 24,
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
            _MoneyRow(
              label: AppStrings.checkoutMerchandise,
              amountMinor: order.financial.merchandiseSubtotalMinor,
            ),
            const SizedBox(height: 8),
            _MoneyRow(
              label: AppStrings.checkoutDeliveryFee,
              amountMinor: order.financial.deliveryFeeMinor,
            ),
            Divider(
              height: 32,
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.checkoutPayable,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  MoneyFormat.dzd(order.financial.customerTotalMinor),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.amountMinor});

  final String label;
  final String amountMinor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          MoneyFormat.dzd(amountMinor),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CancellationOutcome extends StatelessWidget {
  const _CancellationOutcome({
    required this.order,
    required this.refunds,
  });

  final OrderDetail order;
  final AsyncValue<CustomerOrderRefunds?> refunds;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('order-detail-cancellation'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_kOrderCardShadow],
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.orderStatusCancelled,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (order.paymentMethod == 'COD')
              Text(
                AppStrings.orderCancelCodNoRefund,
                key: const Key('order-detail-cod-no-refund'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            if (order.paymentMethod == 'ELECTRONIC')
              Text(
                AppStrings.orderCancelElectronicRefundIntent,
                key: const Key('order-detail-refund-intent-hint'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              AppStrings.orderRefundsTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            refunds.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const Text(AppStrings.orderRefundsLoadError),
              data: (payload) {
                if (payload == null || !payload.hasRefunds) {
                  return Text(
                    order.paymentMethod == 'COD'
                        ? AppStrings.orderCancelCodNoRefund
                        : AppStrings.orderRefundsEmpty,
                    key: const Key('order-detail-refunds-empty'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in payload.refunds) ...[
                      Text(
                        '${customerRefundStatusLabel(item.status)} · ${MoneyFormat.dzd(item.amountMinor)}',
                        key: Key('order-detail-refund-${item.refundId}'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.isCompletedRepayment
                            ? AppStrings.orderRefundCompletedHint
                            : AppStrings.orderRefundNotCompletedHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (item != payload.refunds.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({required this.order, required this.orderId});

  final OrderDetail order;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final secondary = <Widget>[];
    if (order.status == 'COMPLETED') {
      secondary.add(
        Expanded(
          child: FilledButton.tonal(
            key: const Key('order-detail-rate-entry'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.push(AppRoutes.orderRate(orderId)),
            child: const Text(AppStrings.ratingEntry),
          ),
        ),
      );
    }
    if (order.canCustomerCancel) {
      if (secondary.isNotEmpty) secondary.add(const SizedBox(width: 12));
      secondary.add(
        Expanded(
          child: OutlinedButton(
            key: const Key('order-detail-cancel-entry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.push(AppRoutes.orderCancel(orderId)),
            child: const Text(AppStrings.orderCancelEntry),
          ),
        ),
      );
    }
    if (!order.isCancelled &&
        order.paymentMethod == 'ELECTRONIC') {
      if (secondary.isNotEmpty) secondary.add(const SizedBox(width: 12));
      secondary.add(
        Expanded(
          child: OutlinedButton(
            key: const Key('order-detail-payment-entry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.push(AppRoutes.orderPayment(orderId)),
            child: const Text(AppStrings.paymentContinue),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const Key('order-detail-tracking-entry'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      context.push(AppRoutes.orderTracking(orderId)),
                  icon: const Icon(Icons.route),
                  label: const Text(AppStrings.trackingEntry),
                ),
                if (secondary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: secondary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatOrderDateTime(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) {
    return '';
  }
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}, $hour:$minute';
}
