import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/widgets/money_text.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/discovery_storefront_card.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/favorite_heart_button.dart';
import 'package:speedygo_customer_app/features/favorites/application/favorites_controller.dart';
import 'package:speedygo_customer_app/features/favorites/data/favorites_api.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/discovery_overlay.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _toggleBranch(BuildContext context, WidgetRef ref, String id) async {
    final ok = await ref.read(favoritesControllerProvider.notifier).toggleBranch(id);
    if (!ok && context.mounted) {
      SgSnack.error(context, message: AppStrings.favoritesSaveError);
    }
  }

  Future<void> _toggleProduct(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await ref.read(favoritesControllerProvider.notifier).toggleProduct(id);
    if (!ok && context.mounted) {
      SgSnack.error(context, message: AppStrings.favoritesSaveError);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesControllerProvider);
    final ratings = ref.watch(merchantRatingsControllerProvider);
    return Scaffold(
      key: const Key('favorites-screen'),
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppStrings.favoritesTitle),
      ),
      body: DiscoveryOverlay(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HomeLayout.margin,
                8,
                HomeLayout.margin,
                0,
              ),
              child: Row(
                children: [
                  _Tab(
                    label: AppStrings.searchMerchantsTab,
                    selected: state.tab == FavoriteTab.storefronts,
                    onTap: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .setTab(FavoriteTab.storefronts),
                  ),
                  const SizedBox(width: 16),
                  _Tab(
                    label: AppStrings.searchProductsTab,
                    selected: state.tab == FavoriteTab.products,
                    onTap: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .setTab(FavoriteTab.products),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, ref, state, ratings)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    FavoritesState state,
    Map<String, RatingSummary> ratings,
  ) {
    if (state.loading && state.list == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.list == null) {
      return CatalogStatusView(
        message: state.error!.message,
        onRetry: () => ref.read(favoritesControllerProvider.notifier).reload(),
      );
    }
    final list = state.list;
    final isBranches = state.tab == FavoriteTab.storefronts;
    final isEmpty = list == null ||
        (isBranches ? list.branches.isEmpty : list.products.isEmpty);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        HomeLayout.margin,
        12,
        HomeLayout.margin,
        discoveryListBottomPadding(ref),
      ),
      children: [
        if (isEmpty) ...[
          const SizedBox(height: 24),
          const Icon(Icons.favorite_border, size: 56, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            AppStrings.favoritesEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.favoritesDiscoverHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('favorites-discover'),
            onPressed: () => context.go(AppRoutes.search),
            child: Text(AppStrings.favoritesDiscover),
          ),
        ] else if (isBranches)
          for (final storefront in list.branches) ...[
            DiscoveryStorefrontCard(
              key: ValueKey(storefront.branchId),
              storefront: storefront,
              rating: ratings[storefront.merchantId],
              saved: true,
              onFavorite: () => _toggleBranch(context, ref, storefront.branchId),
              onTap: () => context.push(AppRoutes.merchant(storefront.branchId)),
            ),
            const SizedBox(height: 16),
          ]
        else
          for (final item in list.products) ...[
            _ProductFavoriteCard(
              item: item,
              onFavorite: () =>
                  _toggleProduct(context, ref, item.product.productId),
              onTap: () => context.push(
                AppRoutes.productInBranch(
                  item.product.branchId,
                  item.product.productId,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        if (!isEmpty) ...[
          const SizedBox(height: 8),
          _DiscoverCallout(
            onTap: () => context.go(AppRoutes.search),
          ),
        ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2,
              width: 88,
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFavoriteCard extends StatelessWidget {
  const _ProductFavoriteCard({
    required this.item,
    required this.onTap,
    required this.onFavorite,
  });

  final FavoriteProduct item;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: AuthenticatedCatalogImage(
                  imageUrl: product.imageUrl,
                  fallbackLabel: product.name,
                  height: 88,
                  width: 88,
                  radius: 12,
                  icon: Icons.lunch_dining_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.storefront.branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MoneyText(
                      product.priceMinor,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FavoriteCoverageNote(coverage: item.storefront.coverage),
                  ],
                ),
              ),
              FavoriteHeartButton(
                saved: true,
                light: false,
                onPressed: onFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverCallout extends StatelessWidget {
  const _DiscoverCallout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Icon(Icons.favorite_border, size: 40, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            AppStrings.favoritesMoreTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.favoritesDiscoverHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('favorites-discover'),
            onPressed: onTap,
            child: Text(AppStrings.favoritesDiscover),
          ),
        ],
      ),
    );
  }
}
