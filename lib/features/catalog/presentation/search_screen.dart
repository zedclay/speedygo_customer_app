import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/catalog/application/search_controller.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hours_badge.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery, this.showBack = false});

  final String? initialQuery;
  final bool showBack;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(catalogSearchControllerProvider);
    final normalized = normalizeCatalogSearchQuery(_controller.text);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.showBack
          ? AppBar(
              leading: IconButton(
                tooltip: AppStrings.back,
                onPressed: () => popOrParent(context),
                icon: const Icon(Icons.arrow_back),
              ),
              titleSpacing: 0,
              title: _SearchField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) {
                  ref
                      .read(catalogSearchControllerProvider.notifier)
                      .setQuery(value);
                },
              ),
            )
          : AppBar(title: const Text(AppStrings.tabSearch)),
      body: Column(
        children: [
          if (!widget.showBack)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SearchField(
                controller: _controller,
                autofocus: false,
                onChanged: (value) {
                  ref
                      .read(catalogSearchControllerProvider.notifier)
                      .setQuery(value);
                },
              ),
            ),
          Expanded(child: _body(context, search, normalized)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    CatalogSearchState search,
    String normalized,
  ) {
    if (_controller.text.trim().isNotEmpty && normalized.length < 2) {
      return const CatalogStatusView(message: AppStrings.searchNeedTwoChars);
    }
    switch (search.phase) {
      case SearchPhase.idle:
      case SearchPhase.typing:
        return const SizedBox.shrink();
      case SearchPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchPhase.empty:
        return const CatalogStatusView(message: AppStrings.searchEmpty);
      case SearchPhase.error:
        return CatalogStatusView(
          message: search.error?.message ?? AppStrings.catalogLoadError,
          onRetry: () =>
              ref.read(catalogSearchControllerProvider.notifier).retry(),
        );
      case SearchPhase.data:
        final hits = search.page?.items ?? const <CatalogSearchHit>[];
        final children = <Widget>[];
        CatalogHitType? lastType;
        for (final hit in hits) {
          if (hit.type != lastType) {
            if (children.isNotEmpty) {
              children.add(const SizedBox(height: 16));
            }
            children.add(
              Text(
                hit.type == CatalogHitType.storefront
                    ? AppStrings.searchStorefronts
                    : AppStrings.searchProducts,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            );
            children.add(const SizedBox(height: 8));
            lastType = hit.type;
          }
          if (hit.type == CatalogHitType.storefront) {
            children.add(
              _StorefrontHit(
                storefront: hit.storefront!,
                onTap: () =>
                    context.push(AppRoutes.merchant(hit.storefront!.branchId)),
              ),
            );
          } else {
            children.add(
              _ProductHit(
                hit: hit,
                onTap: () => context.push(
                  AppRoutes.productInBranch(
                    hit.product!.branchId,
                    hit.product!.productId,
                  ),
                ),
              ),
            );
          }
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            ...children,
            CatalogLoadMoreBar(
              hasMore: search.hasMore,
              loadingMore: search.loadingMore,
              loadMoreError: search.loadMoreError,
              onLoadMore: () =>
                  ref.read(catalogSearchControllerProvider.notifier).loadMore(),
            ),
          ],
        );
    }
  }
}

class _StorefrontHit extends StatelessWidget {
  const _StorefrontHit({required this.storefront, required this.onTap});

  final StorefrontSummary storefront;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: AuthenticatedCatalogImage(
          imageUrl: storefront.coverImageUrl,
          fallbackLabel: storefront.branchName,
          height: 48,
          width: 48,
          radius: 12,
          icon: Icons.storefront_outlined,
        ),
      ),
      title: Text(
        storefront.branchName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        storefront.merchantName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: HoursBadge(hours: storefront.hours),
      onTap: onTap,
    );
  }
}

class _ProductHit extends StatelessWidget {
  const _ProductHit({required this.hit, required this.onTap});

  final CatalogSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = hit.product!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: AuthenticatedCatalogImage(
          imageUrl: product.imageUrl,
          fallbackLabel: product.name,
          height: 48,
          width: 48,
          radius: 12,
          icon: Icons.lunch_dining_outlined,
        ),
      ),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        hit.storefront?.branchName ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        MoneyFormat.dzd(product.priceMinor),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.autofocus,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('search-query-field'),
      controller: controller,
      textInputAction: TextInputAction.search,
      maxLines: 1,
      autofocus: autofocus,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      decoration: const InputDecoration(
        hintText: AppStrings.searchHint,
        hintMaxLines: 1,
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: onChanged,
    );
  }
}
