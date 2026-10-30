import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/favorite_heart_button.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hours_badge.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_card.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_identity.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

class DiscoveryStorefrontCard extends StatelessWidget {
  const DiscoveryStorefrontCard({
    super.key,
    required this.storefront,
    required this.onTap,
    this.rating,
    this.saved = false,
    this.onFavorite,
    this.outOfZone = false,
  });

  final StorefrontSummary storefront;
  final VoidCallback onTap;
  final RatingSummary? rating;
  final bool saved;
  final VoidCallback? onFavorite;
  final bool outOfZone;

  @override
  Widget build(BuildContext context) {
    final showRating = rating != null && rating!.hasDisplayableRating;
    final closed = storefront.hours.hoursConfigured && !storefront.hours.isOpenNow;
    final showMerchant = !isRedundantMerchantName(
      storefront.branchName,
      storefront.merchantName,
    );
    return StorefrontCardChrome(
      onTap: onTap,
      media: SizedBox(
        height: HomeLayout.liveMediaHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AuthenticatedCoverImage(
              coverImageUrl: storefront.coverImageUrl,
              fallbackLabel: storefront.branchName,
              height: HomeLayout.liveMediaHeight,
            ),
            if (closed)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      hoursLabel(storefront.hours),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (showRating)
              Positioned(
                top: 12,
                left: 12,
                child: MerchantRatingChip(average: rating!.displayAverage),
              ),
            if (onFavorite != null)
              Positioned(
                top: 12,
                right: 12,
                child: FavoriteHeartButton(
                  saved: saved,
                  onPressed: onFavorite,
                ),
              ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    storefront.branchName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 28 / 20,
                    ),
                  ),
                ),
                if (storefront.hours.hoursConfigured &&
                    storefront.hours.isOpenNow) ...[
                  const SizedBox(width: 8),
                  const _OpenNowChip(),
                ],
              ],
            ),
            if (showMerchant) ...[
              const SizedBox(height: 4),
              Text(
                storefront.merchantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
            ],
            if (outOfZone || storefront.coverage != null)
              FavoriteCoverageNote(
                coverage: storefront.coverage,
                forceOutside: outOfZone,
              ),
          ],
        ),
      ),
    );
  }
}

class FavoriteCoverageNote extends StatelessWidget {
  const FavoriteCoverageNote({
    super.key,
    this.coverage,
    this.forceOutside = false,
  });

  final DeliveryCoverage? coverage;
  final bool forceOutside;

  @override
  Widget build(BuildContext context) {
    final outside = forceOutside || coverage?.reason == 'OUTSIDE';
    final unknown = !outside && (coverage?.isUnknown ?? false);
    if (!outside && !unknown) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            outside ? Icons.location_off_outlined : Icons.help_outline,
            size: 16,
            color: outside ? AppColors.error : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              outside
                  ? AppStrings.favoritesOutOfZone
                  : AppStrings.favoritesCoverageUnknown,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: outside ? AppColors.error : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenNowChip extends StatelessWidget {
  const _OpenNowChip();

  @override
  Widget build(BuildContext context) {
    final label = AppStrings.isArabic
        ? AppStrings.hoursOpen
        : AppStrings.hoursOpen.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.tertiary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 16 / 11,
        ),
      ),
    );
  }
}
