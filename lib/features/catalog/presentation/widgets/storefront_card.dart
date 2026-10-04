import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hours_badge.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_identity.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

class StorefrontCardChrome extends StatelessWidget {
  const StorefrontCardChrome({
    super.key,
    required this.media,
    required this.body,
    this.onTap,
  });

  final Widget media;
  final Widget body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(HomeLayout.cardRadius),
          ),
          child: media,
        ),
        body,
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        boxShadow: const [HomeLayout.cardShadow],
      ),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
                child: content,
              ),
      ),
    );
  }
}

class MerchantRatingChip extends StatelessWidget {
  const MerchantRatingChip({super.key, required this.average});

  final String average;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Text(
            average,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class StorefrontCard extends StatelessWidget {
  const StorefrontCard({
    super.key,
    required this.storefront,
    required this.onTap,
    this.rating,
  });

  final StorefrontSummary storefront;
  final VoidCallback onTap;
  final RatingSummary? rating;

  @override
  Widget build(BuildContext context) {
    final showRating = rating != null && rating!.hasDisplayableRating;
    final showMerchant = !isRedundantMerchantName(
      storefront.branchName,
      storefront.merchantName,
    );
    final showAddress = storefront.addressText.isNotEmpty;
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
            if (showRating)
              Positioned(
                top: 12,
                right: 12,
                child: MerchantRatingChip(average: rating!.displayAverage),
              ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StorefrontTitleBlock(
              name: storefront.branchName,
              hours: storefront.hours,
            ),
            if (showMerchant) ...[
              const SizedBox(height: 4),
              Text(
                storefront.merchantName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
            ],
            if (showAddress) ...[
              const SizedBox(height: 12),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0x4DC3C6D4),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      storefront.addressText,
                      maxLines: storefrontCardPreviewMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StorefrontTitleBlock extends StatelessWidget {
  const StorefrontTitleBlock({
    super.key,
    required this.name,
    required this.hours,
  });

  final String name;
  final StorefrontHours hours;

  static const _spacing = 8.0;
  static const _minNameWidth = 160.0;

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 20, height: 28 / 20);
    final nameText = Text(name, style: nameStyle);
    final badge = HoursBadge(hours: hours);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final namePainter = TextPainter(
          text: TextSpan(text: name, style: nameStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final badgePainter = TextPainter(
          text: TextSpan(
            text: hoursLabel(hours),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final badgeWidth = badgePainter.width + 16;
        final remaining = constraints.maxWidth - badgeWidth - _spacing;
        final fitsBeside =
            remaining >= _minNameWidth &&
            namePainter.width + badgeWidth + _spacing <= constraints.maxWidth;
        namePainter.dispose();
        badgePainter.dispose();
        if (fitsBeside) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: nameText),
              const SizedBox(width: _spacing),
              badge,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameText,
            const SizedBox(height: _spacing),
            badge,
          ],
        );
      },
    );
  }
}
