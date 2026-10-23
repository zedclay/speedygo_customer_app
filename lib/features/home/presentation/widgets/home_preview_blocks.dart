import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_card.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';

// Design-preview widgets for accueil_speedygo. Fixture copy only; never sent to APIs.

class HomePreviewBannerStrip extends StatelessWidget {
  const HomePreviewBannerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tertiaryFixed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          AppStrings.previewBanner,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.tertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HomePreviewCategoryStrip extends StatelessWidget {
  const HomePreviewCategoryStrip({super.key});

  static List<(String, IconData, Color, Color)> get _items => [
    (
      AppStrings.categoryRestaurants,
      Icons.restaurant,
      const Color(0x1A0A4096),
      AppColors.primary,
    ),
    (
      AppStrings.categoryBakeries,
      Icons.bakery_dining,
      Color(0xFFE8F5E9),
      Color(0xFF2E7D32),
    ),
    (
      AppStrings.categoryGroceries,
      Icons.local_mall,
      Color(0xFFFFF3E0),
      Color(0xFFEF6C00),
    ),
    (
      AppStrings.categoryPharmacies,
      Icons.medical_services,
      Color(0xFFF3E5F5),
      Color(0xFF7B1FA2),
    ),
    (
      AppStrings.categoryDesserts,
      Icons.icecream,
      Color(0xFFE1F5FE),
      Color(0xFF0288D1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          title: AppStrings.categories,
          trailing: Text(
            AppStrings.seeAll,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              return SizedBox(
                width: 80,
                child: Column(
                  children: [
                    Container(
                      width: HomeLayout.categorySize,
                      height: HomeLayout.categorySize,
                      decoration: BoxDecoration(
                        color: item.$3,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.$2, color: item.$4, size: 32),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: index == 0
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HomePreviewPromoBanner extends StatelessWidget {
  const HomePreviewPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        child: SizedBox(
          height: HomeLayout.promoHeight,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: Color(0x66FFFFFF),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryFixed,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                AppStrings.specialOffer.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.tertiary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.promoHeadline,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                    height: 32 / 24,
                                  ),
                            ),
                            Text(
                              AppStrings.promoCondition,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    height: 20 / 14,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      AppStrings.promoCode,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            height: 24 / 16,
                                            letterSpacing: -0.4,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.content_copy,
                                    size: 20,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePreviewMerchantCard extends StatelessWidget {
  const HomePreviewMerchantCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
      child: StorefrontCardChrome(
        media: SizedBox(
          height: HomeLayout.previewMediaHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const HomePreviewCuisinePanel(),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.previewRating,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.previewMerchantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 28 / 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.previewMerchantCuisine,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                            height: 20 / 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppStrings.previewPopular,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0x4DC3C6D4)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.previewEta,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.delivery_dining,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.previewDeliveryFee,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Warm interior treatment for the preview photo band.
/// Not a photograph of a live merchant.
class HomePreviewCuisinePanel extends StatelessWidget {
  const HomePreviewCuisinePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B4A1F), Color(0xFFC47A3A), Color(0xFF6B2E12)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24,
            bottom: -32,
            child: _Glow(size: 180, color: Color(0x66FFD180)),
          ),
          Positioned(
            right: 24,
            top: 20,
            child: _Glow(size: 90, color: Color(0x55FFE082)),
          ),
          Center(
            child: Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Color(0x55FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class HomePreviewActiveOrderCard extends StatelessWidget {
  const HomePreviewActiveOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onBackground,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.two_wheeler,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.activeOrder,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                height: 16 / 11,
                              ),
                        ),
                      ),
                      Text(
                        AppStrings.previewOrderNumber,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          height: 16 / 11,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AppStrings.previewOrderStatus,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 4,
                      backgroundColor: Color(0x33FFFFFF),
                      color: AppColors.tertiaryFixedDim,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
