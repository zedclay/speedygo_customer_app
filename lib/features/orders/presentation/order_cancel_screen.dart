import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';
import 'package:speedygo_customer_app/core/widgets/money_text.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/orders/application/order_cancellation_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

/// Soft bento lift from Stitch `annuler_la_commande_speedygo`.
const _kBentoShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class OrderCancelScreen extends ConsumerStatefulWidget {
  const OrderCancelScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderCancelScreen> createState() => _OrderCancelScreenState();
}

class _OrderCancelScreenState extends ConsumerState<OrderCancelScreen> {
  static List<(String, IconData)> get _reasons => [
    (
      AppStrings.orderCancelReasonChangeOfMind,
      Icons.sentiment_dissatisfied_outlined,
    ),
    (
      AppStrings.orderCancelReasonWaitTooLong,
      Icons.schedule,
    ),
    (
      AppStrings.orderCancelReasonOrderError,
      Icons.edit_note,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderCancellationControllerProvider.notifier).bindOrder(
            widget.orderId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailControllerProvider(widget.orderId));
    final cancel = ref.watch(orderCancellationControllerProvider);

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
          AppStrings.orderCancelTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.orderLoadError),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(
                  orderDetailControllerProvider(widget.orderId),
                ),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (order) => _body(context, order, cancel),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    OrderDetail order,
    OrderCancellationState cancel,
  ) {
    final eligible = order.canCustomerCancel;
    final busy = cancel.phase == OrderCancellationPhase.submitting;
    final accepted = cancel.phase == OrderCancellationPhase.accepted;
    final pending =
        cancel.phase == OrderCancellationPhase.pendingVerification;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _eligibilityCard(context, order, eligible),
              const SizedBox(height: 16),
              _summaryCard(context, order),
              if (eligible && !accepted) ...[
                const SizedBox(height: 24),
                Text(
                  AppStrings.orderCancelReasonLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.orderCancelReasonOptionalHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final reason in _reasons) ...[
                  _reasonTile(
                    context,
                    reason.$1,
                    reason.$2,
                    cancel.selectedReason,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              if (order.paymentMethod == 'ELECTRONIC') ...[
                const SizedBox(height: 16),
                _infoBanner(
                  context,
                  AppStrings.orderCancelElectronicRefundBankHint,
                ),
              ],
              if (order.paymentMethod == 'COD') ...[
                const SizedBox(height: 16),
                _infoBanner(context, AppStrings.orderCancelCodNoRefund),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.orderCancelIrreversible,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (cancel.message != null) ...[
                const SizedBox(height: 16),
                Text(
                  cancel.message!,
                  key: Key(
                    accepted
                        ? 'order-cancel-accepted'
                        : pending
                        ? 'order-cancel-pending'
                        : 'order-cancel-message',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accepted
                        ? AppColors.primary
                        : pending
                        ? AppColors.onSurfaceVariant
                        : AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pending) ...[
                    FilledButton(
                      key: const Key('order-cancel-verify'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: busy
                          ? null
                          : () => ref
                                .read(
                                  orderCancellationControllerProvider.notifier,
                                )
                                .retryVerification(order),
                      child: Text(
                        busy
                            ? AppStrings.addressReconciling
                            : AppStrings.orderCancelCheckAgain,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else if (accepted) ...[
                    FilledButton(
                      key: const Key('order-cancel-view-detail'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          context.go(AppRoutes.order(widget.orderId)),
                      child: Text(AppStrings.orderConfirmationViewDetail),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.orders),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppStrings.orderSubmissionViewOrders),
                    ),
                  ] else if (eligible) ...[
                    FilledButton.icon(
                      key: const Key('order-cancel-confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: busy
                          ? null
                          : () => ref
                                .read(
                                  orderCancellationControllerProvider.notifier,
                                )
                                .confirm(order),
                      icon: const Icon(Icons.cancel),
                      label: Text(
                        busy
                            ? AppStrings.addressSaving
                            : AppStrings.orderCancelConfirmAction,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('order-cancel-keep'),
                      onPressed: busy ? null : () => popOrParent(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppStrings.orderCancelKeepOrder),
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed: () => popOrParent(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppStrings.back),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _eligibilityCard(
    BuildContext context,
    OrderDetail order,
    bool eligible,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: eligible
            ? AppColors.primaryContainer.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: eligible
              ? AppColors.primaryContainer.withValues(alpha: 0.2)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: eligible
                    ? AppColors.primaryContainer
                    : AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                eligible ? Icons.check_circle : Icons.cancel,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eligible
                        ? AppStrings.orderCancelEligibleTitle
                        : AppStrings.orderCancelNotEligible,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: eligible ? AppColors.primary : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eligible
                        ? AppStrings.orderCancelEligibleBody
                        : activeOrderStatusLabel(
                            fulfillmentStatus: order.fulfillmentStatus,
                            orderStatus: order.status,
                          ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, OrderDetail order) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [_kBentoShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BidiLtr(
                child: Text(
                  '${AppStrings.orderReferenceLabel} · ${order.publicReference}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  order.financial.customerTotalMinor,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  AppStrings.checkoutPayable,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonTile(
    BuildContext context,
    String reason,
    IconData leading,
    String? selected,
  ) {
    final isSelected = selected == reason;
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.05)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('order-cancel-reason-$reason'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final notifier = ref.read(
            orderCancellationControllerProvider.notifier,
          );
          notifier.selectReason(isSelected ? null : reason);
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isSelected || selected == null ? 1 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? null : const [_kBentoShadow],
            ),
            child: Row(
              children: [
                Icon(
                  leading,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBanner(BuildContext context, String text) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
