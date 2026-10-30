import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/widgets/money_text.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/application/search_controller.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/discovery_storefront_card.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/favorite_heart_button.dart';
import 'package:speedygo_customer_app/features/favorites/application/favorites_controller.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/discovery_overlay.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_category_strip.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_copy.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_providers.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery, this.showBack = false});

  final String? initialQuery;
  final bool showBack;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  late final ScrollController _scroll;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _scroll = ScrollController();
    _focus = FocusNode();
    final initial = widget.initialQuery;
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(catalogSearchControllerProvider.notifier).setQuery(initial);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _applyQuery(String value, {bool immediate = false}) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    final notifier = ref.read(catalogSearchControllerProvider.notifier);
    if (immediate) {
      notifier.submitQuery(value);
    } else {
      notifier.setQuery(value);
    }
  }

  Future<void> _toggleBranch(String branchId) async {
    final ok = await ref
        .read(favoritesControllerProvider.notifier)
        .toggleBranch(branchId);
    if (!ok && mounted) {
      SgSnack.error(context, message: AppStrings.favoritesSaveError);
    }
  }

  Future<void> _toggleProduct(String productId) async {
    final ok = await ref
        .read(favoritesControllerProvider.notifier)
        .toggleProduct(productId);
    if (!ok && mounted) {
      SgSnack.error(context, message: AppStrings.favoritesSaveError);
    }
  }

  Future<void> _openFilters(CatalogSearchState search) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.searchFilters,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  key: const Key('search-filter-open-now'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.storefrontsOpenNow),
                  value: search.openNow,
                  onChanged: (value) {
                    ref
                        .read(catalogSearchControllerProvider.notifier)
                        .setOpenNow(value);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(catalogSearchControllerProvider);
    final normalized = normalizeCatalogSearchQuery(_controller.text);
    final addressLabel = homeAddressLabel(
      book: ref.watch(addressBookProvider),
      selection: ref.watch(addressSelectionProvider),
      sessionFallback: ref.watch(sessionControllerProvider).customer?.deliverToLabel,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: DiscoveryOverlay(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    if (widget.showBack)
                      IconButton(
                        tooltip: AppStrings.back,
                        onPressed: () => popOrParent(context),
                        icon: const Icon(Icons.arrow_back),
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: _SearchField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: widget.showBack,
                        onChanged: (value) {
                          ref
                              .read(catalogSearchControllerProvider.notifier)
                              .setQuery(value);
                        },
                        onClear: () => _applyQuery(''),
                      ),
                    ),
                    if (normalized.length >= catalogSearchMinLength)
                      IconButton(
                        key: const Key('search-filters-button'),
                        tooltip: AppStrings.searchFilters,
                        onPressed: () => _openFilters(search),
                        icon: Badge(
                          isLabelVisible: search.activeFilterCount > 0,
                          label: Text('${search.activeFilterCount}'),
                          child: const Icon(Icons.tune),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HomeLayout.margin,
                  8,
                  HomeLayout.margin,
                  0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        addressLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, search, normalized)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    CatalogSearchState search,
    String normalized,
  ) {
    if (_controller.text.trim().isNotEmpty &&
        normalized.length < catalogSearchMinLength) {
      return CatalogStatusView(message: AppStrings.searchNeedTwoChars);
    }
    switch (search.phase) {
      case SearchPhase.idle:
      case SearchPhase.typing:
        return _IdleBody(
          recents: search.recents,
          onRecent: (item) => _applyQuery(item, immediate: true),
          onClearRecents: () =>
              ref.read(catalogSearchControllerProvider.notifier).clearRecents(),
        );
      case SearchPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchPhase.empty:
        return _ResultsChrome(
          search: search,
          child: CatalogStatusView(message: AppStrings.searchEmpty),
        );
      case SearchPhase.error:
        return _ResultsChrome(
          search: search,
          child: CatalogStatusView(
            message: search.error?.message ?? AppStrings.catalogLoadError,
            onRetry: () =>
                ref.read(catalogSearchControllerProvider.notifier).retry(),
          ),
        );
      case SearchPhase.data:
        final hits = search.page?.items ?? const <CatalogSearchHit>[];
        final favorites = ref.watch(favoritesControllerProvider);
        final ratings = ref.watch(merchantRatingsControllerProvider);
        return _ResultsChrome(
          search: search,
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              HomeLayout.margin,
              8,
              HomeLayout.margin,
              discoveryListBottomPadding(ref),
            ),
            children: [
              for (final hit in hits) ...[
                if (hit.type == CatalogHitType.storefront &&
                    hit.storefront != null)
                  DiscoveryStorefrontCard(
                    key: ValueKey(hit.storefront!.branchId),
                    storefront: hit.storefront!,
                    rating: ratings[hit.storefront!.merchantId],
                    saved: favorites.ids.hasBranch(hit.storefront!.branchId),
                    onFavorite: () => _toggleBranch(hit.storefront!.branchId),
                    onTap: () => context.push(
                      AppRoutes.merchant(hit.storefront!.branchId),
                    ),
                  )
                else if (hit.product != null)
                  _ProductResultCard(
                    hit: hit,
                    saved: favorites.ids.hasProduct(hit.product!.productId),
                    onFavorite: () => _toggleProduct(hit.product!.productId),
                    onTap: () => context.push(
                      AppRoutes.productInBranch(
                        hit.product!.branchId,
                        hit.product!.productId,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              CatalogLoadMoreBar(
                hasMore: search.hasMore,
                loadingMore: search.loadingMore,
                loadMoreError: search.loadMoreError,
                onLoadMore: () => ref
                    .read(catalogSearchControllerProvider.notifier)
                    .loadMore(),
              ),
            ],
          ),
        );
    }
  }
}

class _ResultsChrome extends ConsumerWidget {
  const _ResultsChrome({required this.search, required this.child});

  final CatalogSearchState search;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = search.page?.total ?? 0;
    final countLabel = search.tab == SearchHitTab.storefronts
        ? AppStrings.searchMerchantCount(total)
        : AppStrings.searchProductCount(total);
    return Column(
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
                selected: search.tab == SearchHitTab.storefronts,
                onTap: () => ref
                    .read(catalogSearchControllerProvider.notifier)
                    .setTab(SearchHitTab.storefronts),
              ),
              const SizedBox(width: 16),
              _Tab(
                label: AppStrings.searchProductsTab,
                selected: search.tab == SearchHitTab.products,
                onTap: () => ref
                    .read(catalogSearchControllerProvider.notifier)
                    .setTab(SearchHitTab.products),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            HomeLayout.margin,
            12,
            HomeLayout.margin,
            4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  countLabel,
                  key: const Key('search-result-count'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                AppStrings.searchSortName,
                key: const Key('search-sort-name'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
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

class _IdleBody extends ConsumerWidget {
  const _IdleBody({
    required this.recents,
    required this.onRecent,
    required this.onClearRecents,
  });

  final List<String> recents;
  final ValueChanged<String> onRecent;
  final VoidCallback onClearRecents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(storefrontListControllerProvider);
    final verticals = switch (ref.watch(commerceVerticalsProvider)) {
      AsyncData(:final value) => value,
      _ => const <CommerceVertical>[],
    };
    final DiscoverablePromotion? offer = switch (ref.watch(
      discoverablePromotionsProvider,
    )) {
      AsyncData(:final value) when value.isNotEmpty => value.first,
      _ => null,
    };
    final suggestions = feed.items.take(2).toList();
    final editorial = feed.items.length > 2 ? feed.items[2] : null;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        HomeLayout.margin,
        12,
        HomeLayout.margin,
        discoveryListBottomPadding(ref),
      ),
      children: [
        if (recents.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.searchRecent,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: const Key('search-clear-recents'),
                onPressed: onClearRecents,
                child: Text(AppStrings.searchClearAll),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in recents)
                ActionChip(
                  key: Key('search-recent-$item'),
                  label: Text(item),
                  onPressed: () => onRecent(item),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (suggestions.isNotEmpty) ...[
          Text(
            AppStrings.searchSuggestions,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < suggestions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _SuggestionCard(
                    storefront: suggestions[i],
                    onTap: () => context.push(
                      AppRoutes.merchant(suggestions[i].branchId),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (editorial != null) ...[
          _EditorialCard(
            storefront: editorial,
            onTap: () => context.push(AppRoutes.merchant(editorial.branchId)),
          ),
          const SizedBox(height: 24),
        ] else if (verticals.isNotEmpty) ...[
          _VerticalEditorial(
            vertical: verticals.first,
            onTap: () => context.go(
              AppRoutes.homeCategoryResults(verticals.first.id),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (verticals.isNotEmpty) ...[
          Text(
            AppStrings.searchPopularCategories,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final vertical in verticals.take(4))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _CategoryShortcut(
                      vertical: vertical,
                      onTap: () => context.go(
                        AppRoutes.homeCategoryResults(vertical.id),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _MoreShortcut(
                    onTap: () => context.go(AppRoutes.homeCategories),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (offer != null)
          _OfferCard(
            offer: offer,
            onTap: () => context.go(AppRoutes.promotions),
          ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.storefront, required this.onTap});

  final StorefrontSummary storefront;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthenticatedCoverImage(
              coverImageUrl: storefront.coverImageUrl,
              fallbackLabel: storefront.branchName,
              height: 96,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storefront.branchName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    storefront.merchantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
}

class _EditorialCard extends StatelessWidget {
  const _EditorialCard({required this.storefront, required this.onTap});

  final StorefrontSummary storefront;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storefront.branchName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storefront.addressText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.searchExplore,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 120,
              height: 112,
              child: AuthenticatedCoverImage(
                coverImageUrl: storefront.coverImageUrl,
                fallbackLabel: storefront.branchName,
                height: 112,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalEditorial extends StatelessWidget {
  const _VerticalEditorial({required this.vertical, required this.onTap});

  final CommerceVertical vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commerceVerticalDisplayName(vertical),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.searchExplore,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({required this.vertical, required this.onTap});

  final CommerceVertical vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = commerceVerticalStyle(
      vertical.iconKey,
      slug: vertical.slug,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: style.background,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.foreground),
            ),
            const SizedBox(height: 8),
            Text(
              commerceVerticalDisplayName(vertical),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreShortcut extends StatelessWidget {
  const _MoreShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apps, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.moreCategories,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onTap});

  final DiscoverablePromotion offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
      child: InkWell(
        key: const Key('search-offer-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.searchOfferOfDay,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                PromotionCopy.headline(offer),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                offer.code,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.tertiaryFixed,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({
    required this.hit,
    required this.onTap,
    required this.saved,
    required this.onFavorite,
  });

  final CatalogSearchHit hit;
  final VoidCallback onTap;
  final bool saved;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final product = hit.product!;
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
                    if (hit.storefront != null)
                      Text(
                        hit.storefront!.branchName,
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
                  ],
                ),
              ),
              FavoriteHeartButton(
                saved: saved,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.autofocus,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(HomeLayout.searchRadius),
        boxShadow: const [HomeLayout.searchShadow],
      ),
      child: TextField(
        key: const Key('search-query-field'),
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        maxLines: 1,
        autofocus: autofocus,
        scrollPadding: const EdgeInsets.only(bottom: 120),
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          hintMaxLines: 1,
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  key: const Key('search-clear-query'),
                  tooltip: AppStrings.searchClearQuery,
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
