import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

/// Merchant rating summary only — no public review-list contract exists.
/// Visual hierarchy follows Stitch `avis_speedygo` (summary card first).
class MerchantReviewsScreen extends ConsumerWidget {
  const MerchantReviewsScreen({super.key, required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(storefrontDetailProvider(branchId));
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x14000000),
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: detail.maybeWhen(
          data: (storefront) => Text(
            AppStrings.ratingReviewsHeading(storefront.merchantName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 28 / 20,
            ),
          ),
          orElse: () => Text(
            AppStrings.ratingReviewsTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 28 / 20,
            ),
          ),
        ),
        // Stitch search affordance omitted — no review-search contract (D).
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => CatalogStatusView(
          message: error is AppException
              ? error.message
              : AppStrings.storefrontUnavailable,
          onRetry: () => ref.invalidate(storefrontDetailProvider(branchId)),
        ),
        data: (storefront) {
          final summaryAsync =
              ref.watch(merchantSummaryProvider(storefront.merchantId));
          return summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => CatalogStatusView(
              message: error is AppException
                  ? error.message
                  : AppStrings.ratingReviewsLoadError,
              onRetry: () => ref.invalidate(
                merchantSummaryProvider(storefront.merchantId),
              ),
            ),
            data: (summary) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _RatingSummaryCard(summary: summary),
                const SizedBox(height: 24),
                _HonestReviewsNote(hasRating: summary.hasDisplayableRating),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: summary.hasDisplayableRating
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      summary.displayAverage,
                      key: const Key('rating-reviews-average'),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                        height: 48 / 40,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _AverageStars(average: summary.average!),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.count} ${AppStrings.ratingCountLabel}',
                      key: const Key('rating-reviews-count'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    AppStrings.ratingDistributionUnavailable,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppStrings.ratingReviewsEmpty,
                key: const Key('rating-reviews-empty'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
    );
  }
}

class _AverageStars extends StatelessWidget {
  const _AverageStars({required this.average});

  final double average;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            average >= i
                ? Icons.star
                : average >= i - 0.5
                    ? Icons.star_half
                    : Icons.star_outline,
            size: 20,
            color: AppColors.tertiary,
          ),
      ],
    );
  }
}

class _HonestReviewsNote extends StatelessWidget {
  const _HonestReviewsNote({required this.hasRating});

  final bool hasRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasRating
                ? AppStrings.ratingReviewsUnsupported
                : AppStrings.ratingReviewsUnsupportedEmpty,
            key: const Key('rating-reviews-no-feed'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasRating
                ? AppStrings.ratingNoPublicFeed
                : AppStrings.ratingNoPublicFeedEmpty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}
