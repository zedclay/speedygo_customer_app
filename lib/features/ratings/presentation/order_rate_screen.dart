import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/ratings/application/order_rating_controller.dart';
import 'package:speedygo_customer_app/features/ratings/presentation/star_rating_bar.dart';

/// Soft lift from Stitch `noter_la_commande_speedygo`.
const _kRatingCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class OrderRateScreen extends ConsumerWidget {
  const OrderRateScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderRatingControllerProvider(orderId));
    final order = state.order;
    final storefront = order == null
        ? null
        : ref.watch(storefrontDetailProvider(order.merchantBranchId));
    final merchantName = storefront?.asData?.value.merchantName;
    final showSticky = state.phase == OrderRatingPhase.ready ||
        state.phase == OrderRatingPhase.submitting ||
        state.phase == OrderRatingPhase.pendingVerification;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.ratingTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            if (order != null)
              BidiLtr(
                child: Text(
                  '${AppStrings.orderReferenceLabel} #${order.publicReference}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: state.phase == OrderRatingPhase.loading
          ? const Center(child: CircularProgressIndicator())
          : state.phase == OrderRatingPhase.error
          ? _error(context, ref, state)
          : state.phase == OrderRatingPhase.ineligible
          ? _message(
              context,
              state.errorMessage ?? AppStrings.ratingOrderIneligible,
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, showSticky ? 140 : 32),
              children: [
                if (state.alreadyFullyRated ||
                    state.phase == OrderRatingPhase.succeeded) ...[
                  DecoratedBox(
                    decoration: _cardDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 48,
                            color: AppColors.brandGreen,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.ratingAlreadyDone,
                            key: const Key('rating-already-done'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (state.existingMerchant != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              '${AppStrings.ratingAverageLabel} · ${state.existingMerchant!.score}/5',
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (state.existingMerchant?.comment != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              state.existingMerchant!.comment!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  DecoratedBox(
                    decoration: _cardDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  merchantName ?? AppStrings.ratingTitle,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppStrings.ratingMerchantPrompt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          StarRatingBar(
                            key: const Key('rating-merchant-stars'),
                            value: state.merchantScore,
                            enabled: state.merchantNeedsWrite && !state.busy,
                            size: 44,
                            onChanged: (score) => ref
                                .read(
                                  orderRatingControllerProvider(orderId).notifier,
                                )
                                .setMerchantScore(score),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: _cardDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: Column(
                        children: [
                          Text(
                            AppStrings.ratingDriverLabel,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.ratingDriverPrompt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          if (state.driverUnavailable)
                            Text(
                              AppStrings.errorForCode('RATING_INTEGRITY'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            )
                          else
                            StarRatingBar(
                              key: const Key('rating-driver-stars'),
                              value: state.driverScore,
                              enabled: state.driverNeedsWrite && !state.busy,
                              size: 44,
                              onChanged: (score) => ref
                                  .read(
                                    orderRatingControllerProvider(
                                      orderId,
                                    ).notifier,
                                  )
                                  .setDriverScore(score),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    key: const Key('rating-write-detailed'),
                    onPressed: state.busy
                        ? null
                        : () => context.push(AppRoutes.orderReview(orderId)),
                    icon: const Icon(Icons.edit_note, color: AppColors.primary),
                    label: Text(
                      AppStrings.ratingWriteDetailed,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      key: const Key('rating-error'),
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (state.phase == OrderRatingPhase.pendingVerification)
                    OutlinedButton(
                      key: const Key('rating-reconcile'),
                      onPressed: () => ref
                          .read(orderRatingControllerProvider(orderId).notifier)
                          .reconcileAfterUncertain(),
                      child: Text(AppStrings.supportRefresh),
                    ),
                ],
              ],
            ),
      bottomNavigationBar: showSticky
          ? _StickyRatingActions(orderId: orderId, state: state)
          : null,
    );
  }

  Widget _error(BuildContext context, WidgetRef ref, OrderRatingState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? AppStrings.ratingLoadError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(orderRatingControllerProvider(orderId).notifier)
                  .refresh(),
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  static BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: const [_kRatingCardShadow],
    );
  }
}

class _StickyRatingActions extends ConsumerWidget {
  const _StickyRatingActions({
    required this.orderId,
    required this.state,
  });

  final String orderId;
  final OrderRatingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: AppColors.surface.withValues(alpha: 0.88),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const Key('rating-submit-scores'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: state.busy ||
                            state.phase ==
                                OrderRatingPhase.pendingVerification ||
                            !state.canSubmit
                        ? null
                        : () async {
                            final ok = await ref
                                .read(
                                  orderRatingControllerProvider(
                                    orderId,
                                  ).notifier,
                                )
                                .submit();
                            if (ok && context.mounted) {
                              SgSnack.success(
                                context,
                                message: AppStrings.ratingSuccess,
                              );
                            }
                          },
                    child: Text(
                      state.busy
                          ? AppStrings.ratingSending
                          : AppStrings.ratingSendScores,
                    ),
                  ),
                  TextButton(
                    onPressed: state.busy ? null : () => popOrParent(context),
                    child: Text(
                      AppStrings.ratingSkip,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
