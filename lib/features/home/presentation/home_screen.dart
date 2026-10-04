import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/open_now_filter_chip.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_card.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_active_order_card.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_category_strip.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_inbox_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_providers.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _offerPreview(BuildContext context, WidgetRef ref) async {
    if (kReleaseMode) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.previewEnableTitle),
        content: const Text(AppStrings.previewEnableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.previewEnableAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    ref.read(navPreviewEnabledProvider.notifier).enable();
    context.push(AppRoutes.directory);
  }

  String _addressLabel(WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    return homeAddressLabel(
      book: ref.watch(addressBookProvider),
      selection: ref.watch(addressSelectionProvider),
      sessionFallback: session.customer?.deliverToLabel,
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(commerceVerticalsProvider);
    ref.invalidate(discoverablePromotionsProvider);
    await Future.wait([
      ref.read(storefrontListControllerProvider.notifier).refresh(),
      ref.read(activeOrderControllerProvider.notifier).refresh(),
      ref.read(merchantRatingsControllerProvider.notifier).refresh(),
      ref.read(notificationUnreadCountProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final name = session.customer?.displayName ?? AppStrings.appName;
    final feed = ref.watch(storefrontListControllerProvider);
    final catalog = ref.read(storefrontListControllerProvider.notifier);
    final openNow = ref.watch(openNowFilterProvider);
    final ratings = ref.watch(merchantRatingsControllerProvider);
    final verticals = switch (ref.watch(commerceVerticalsProvider)) {
      AsyncData(:final value) => value,
      _ => const <CommerceVertical>[],
    };
    final selectedVerticalId = ref.watch(selectedCommerceVerticalIdProvider);
    final DiscoverablePromotion? featuredPromotion = switch (ref.watch(
      discoverablePromotionsProvider,
    )) {
      AsyncData(:final value) when value.isNotEmpty => value.first,
      _ => null,
    };
    final activeOrder = switch (ref.watch(activeOrderControllerProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final unreadCount = ref.watch(notificationUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: activeOrder == null
                      ? HomeLayout.listBottomGap
                      : HomeLayout.listBottomGapWithOrder,
                ),
                children: [
                  HomeHeader(
                    addressLabel: _addressLabel(ref),
                    onLogoLongPress: () => _offerPreview(context, ref),
                    onAddressTap: () =>
                        context.push(AppRoutes.checkoutAddressPicker),
                    onAlertsTap: () => context.go(AppRoutes.alerts),
                    unreadCount: unreadCount,
                  ),
                  HomeGreeting(text: AppStrings.homeGreeting(name)),
                  HomeSearchField(onTap: () => context.go(AppRoutes.search)),
                  if (verticals.isNotEmpty) ...[
                    // Stitch categories section `mt-6`.
                    const SizedBox(height: 24),
                    HomeCategoryStrip(
                      verticals: verticals,
                      selectedId: selectedVerticalId,
                      onSelected: (id) {
                        ref
                            .read(selectedCommerceVerticalIdProvider.notifier)
                            .select(id);
                      },
                      onSeeAll: () => context.go(AppRoutes.homeCategories),
                    ),
                  ],
                  if (featuredPromotion != null) ...[
                    // Stitch promo section `mt-8`.
                    const SizedBox(height: 32),
                    HomePromoBanner(promotion: featuredPromotion),
                  ],
                  // Stitch merchant section `mt-8` (honest title — no proximity).
                  const SizedBox(height: 32),
                  const HomeSectionTitle(title: AppStrings.storefrontsTitle),
                  const SizedBox(height: 12),
                  const OpenNowFilterChip(),
                  const SizedBox(height: 16),
                  if (feed.loading && feed.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (feed.error != null && feed.items.isEmpty)
                    CatalogStatusView(
                      message: feed.error is AppException
                          ? feed.error!.message
                          : AppStrings.catalogLoadError,
                      onRetry: catalog.refresh,
                    )
                  else if (feed.isEmpty)
                    CatalogStatusView(
                      icon: Icons.storefront_outlined,
                      message: openNow
                          ? AppStrings.storefrontsOpenNowEmpty
                          : AppStrings.storefrontsEmpty,
                      retryLabel: openNow
                          ? AppStrings.storefrontsShowAll
                          : AppStrings.refresh,
                      onRetry: openNow
                          ? () => ref
                                .read(openNowFilterProvider.notifier)
                                .setEnabled(false)
                          : catalog.refresh,
                    )
                  else ...[
                    for (final storefront in feed.items) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HomeLayout.margin,
                        ),
                        child: StorefrontCard(
                          key: ValueKey(storefront.branchId),
                          storefront: storefront,
                          rating: ratings[storefront.merchantId],
                          onTap: () => context.push(
                            AppRoutes.merchant(storefront.branchId),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HomeLayout.margin,
                      ),
                      child: CatalogLoadMoreBar(
                        hasMore: feed.hasMore,
                        loadingMore: feed.loadingMore,
                        loadMoreError: feed.loadMoreError,
                        onLoadMore: catalog.loadMore,
                      ),
                    ),
                  ],
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HomeLayout.margin,
                      ),
                      child: Text(
                        session.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (activeOrder != null)
              Positioned(
                left: HomeLayout.margin,
                right: HomeLayout.margin,
                bottom: 16,
                child: HomeActiveOrderCard(
                  publicReference: activeOrder.publicReference,
                  statusLabel: activeOrder.statusLabel,
                  onTap: () => context.push(
                    AppRoutes.orderTracking(activeOrder.orderId),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
