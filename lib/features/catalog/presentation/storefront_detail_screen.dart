import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/widgets/money_text.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hero_overlay_button.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hours_badge.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_identity.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

class StorefrontDetailScreen extends ConsumerStatefulWidget {
  const StorefrontDetailScreen({super.key, required this.branchId});

  final String branchId;

  @override
  ConsumerState<StorefrontDetailScreen> createState() =>
      _StorefrontDetailScreenState();
}

class _StorefrontDetailScreenState
    extends ConsumerState<StorefrontDetailScreen> {
  String? _categoryId;

  static const _heroHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(storefrontDetailProvider(widget.branchId));
    final categories = ref.watch(storefrontCategoriesProvider(widget.branchId));
    final productsArgs = StorefrontProductsArgs(
      branchId: widget.branchId,
      categoryId: _categoryId,
    );
    final products = ref.watch(
      storefrontProductsControllerProvider(productsArgs),
    );
    final productsCtl = ref.read(
      storefrontProductsControllerProvider(productsArgs).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: AppStrings.back,
              onPressed: () => popOrParent(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: CatalogStatusView(
            message: error is AppException
                ? error.message
                : AppStrings.storefrontUnavailable,
            onRetry: () =>
                ref.invalidate(storefrontDetailProvider(widget.branchId)),
          ),
        ),
        data: (storefront) {
          unawaited(
            ref
                .read(merchantRatingsControllerProvider.notifier)
                .ensure([storefront.merchantId]),
          );
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _heroHeight + 120,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: _heroHeight,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AuthenticatedCoverImage(
                              coverImageUrl: storefront.coverImageUrl,
                              fallbackLabel: storefront.branchName,
                              height: _heroHeight,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x66000000),
                                    Color(0x00000000),
                                    Color(0x00000000),
                                    Color(0x80000000),
                                  ],
                                  stops: [0, 0.4, 0.6, 1],
                                ),
                              ),
                            ),
                            HeroOverlayBar(
                              leading: HeroOverlayButton(
                                tooltip: AppStrings.back,
                                icon: Icons.arrow_back,
                                onPressed: () => popOrParent(context),
                              ),
                              actions: [
                                HeroOverlayButton(
                                  tooltip: AppStrings.storefrontInfo,
                                  icon: Icons.info_outline,
                                  onPressed: () => context.push(
                                    AppRoutes.merchantInfo(widget.branchId),
                                  ),
                                ),
                                HeroOverlayButton(
                                  key: const Key('storefront-reviews-entry'),
                                  tooltip: AppStrings.ratingReviewsTitle,
                                  icon: Icons.rate_review_outlined,
                                  onPressed: () => context.push(
                                    AppRoutes.merchantReviews(widget.branchId),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        top: _heroHeight - 48,
                        child: _StorefrontIdentityCard(
                          storefront: storefront,
                          summary: ref.watch(
                            merchantRatingsControllerProvider,
                          )[storefront.merchantId],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: categories.when(
                  loading: () => const SizedBox(height: 48),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (items) {
                    if (items.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        children: [
                          _CategoryTab(
                            label: AppStrings.allProducts,
                            selected: _categoryId == null,
                            onTap: () => setState(() => _categoryId = null),
                          ),
                          for (final category in items)
                            _CategoryTab(
                              label: category.name,
                              selected: _categoryId == category.categoryId,
                              onTap: () => setState(
                                () => _categoryId = category.categoryId,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (products.loading && products.items.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (products.error != null && products.items.isEmpty)
                SliverToBoxAdapter(
                  child: CatalogStatusView(
                    message: products.error is AppException
                        ? products.error!.message
                        : AppStrings.catalogLoadError,
                    onRetry: productsCtl.refresh,
                  ),
                )
              else if (products.isEmpty)
                SliverToBoxAdapter(
                  child: CatalogStatusView(
                    message: _categoryId == null
                        ? AppStrings.productsEmptyUnfiltered
                        : AppStrings.productsEmpty,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList.separated(
                    itemCount:
                        products.items.length +
                        (products.hasMore || products.loadMoreError != null
                            ? 1
                            : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= products.items.length) {
                        return CatalogLoadMoreBar(
                          hasMore: products.hasMore,
                          loadingMore: products.loadingMore,
                          loadMoreError: products.loadMoreError,
                          onLoadMore: productsCtl.loadMore,
                        );
                      }
                      final product = products.items[index];
                      return _ProductRow(
                        key: ValueKey(product.productId),
                        product: product,
                        onTap: () => context.push(
                          AppRoutes.productInBranch(
                            widget.branchId,
                            product.productId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StorefrontIdentityCard extends StatelessWidget {
  const _StorefrontIdentityCard({
    required this.storefront,
    this.summary,
  });

  final StorefrontDetail storefront;
  final RatingSummary? summary;

  static const _cardShadow = BoxShadow(
    color: Color(0x140A4096),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = storefront.hours;
    final rating = summary != null && summary!.hasDisplayableRating
        ? summary!
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [_cardShadow],
      ),
      child: Padding(
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.displayAverage,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (!isRedundantMerchantName(
              storefront.branchName,
              storefront.merchantName,
            )) ...[
              const SizedBox(height: 4),
              Text(
                storefront.merchantName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: !hours.hoursConfigured
                        ? AppColors.outline
                        : hours.isOpenNow
                        ? AppColors.tertiaryFixedDim
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hoursLine(hours),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (hours.hoursConfigured && !hours.isOpenNow) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.closedBrowseHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _hoursLine(StorefrontHours hours) {
    if (!hours.hoursConfigured) {
      return AppStrings.hoursUnconfigured;
    }
    if (hours.isOpenNow) {
      final closes = hours.currentClosesAt;
      if (closes != null) {
        return '${AppStrings.hoursOpenUntil} ${_formatHm(closes)}';
      }
      return hoursLabel(hours);
    }
    return hoursLabel(hours);
  }

  String _formatHm(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({super.key, required this.product, required this.onTap});

  final CatalogProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 8),
                    MoneyText(
                      product.priceMinor,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AuthenticatedCatalogImage(
                imageUrl: product.imageUrl,
                fallbackLabel: product.name,
                height: 88,
                width: 88,
                radius: 8,
                icon: Icons.lunch_dining_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
