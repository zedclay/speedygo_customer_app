import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_copy.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_providers.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';

/// Discoverable offers from GET /customer/promotions.
/// Does not apply codes — checkout remains discount authority.
class PromotionsListScreen extends ConsumerWidget {
  const PromotionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(discoverablePromotionsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppStrings.promotionsTitle),
      ),
      body: offers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is AppException
                      ? error.message
                      : AppStrings.catalogLoadError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(discoverablePromotionsProvider),
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(AppStrings.promotionsEmpty));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                AppStrings.promotionsCheckoutHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final offer in items) ...[
                _PromotionCard(offer: offer),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.offer});

  final DiscoverablePromotion offer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PromotionCopy.label(offer),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              PromotionCopy.headline(offer),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              offer.code,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.onPrimaryContainer,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: offer.code));
                  if (!context.mounted) {
                    return;
                  }
                  // Copy-only — information, never success (promo not applied).
                  SgSnack.info(context, message: AppStrings.promoCodeCopied);
                },
                child: Text(AppStrings.copyPromoCode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
