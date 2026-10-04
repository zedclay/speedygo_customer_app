import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_feed.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/open_now_filter_chip.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_card.dart';

class StorefrontListScreen extends ConsumerWidget {
  const StorefrontListScreen({super.key, this.verticalId});

  /// When set, loads `GET /customer/branches?verticalId=` without touching Home.
  final String? verticalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopedId = verticalId?.trim();
    final useScoped = scopedId != null && scopedId.isNotEmpty;
    final feed = useScoped
        ? ref.watch(storefrontResultsControllerProvider(scopedId))
        : ref.watch(storefrontListControllerProvider);
    final openNow = ref.watch(openNowFilterProvider);
    final title = useScoped
        ? _titleForVertical(ref, scopedId)
        : AppStrings.storefrontsTitle;

    Future<void> onRefresh() {
      if (useScoped) {
        return ref
            .read(storefrontResultsControllerProvider(scopedId).notifier)
            .refresh();
      }
      return ref.read(storefrontListControllerProvider.notifier).refresh();
    }

    Future<void> onLoadMore() {
      if (useScoped) {
        return ref
            .read(storefrontResultsControllerProvider(scopedId).notifier)
            .loadMore();
      }
      return ref.read(storefrontListControllerProvider.notifier).loadMore();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: _body(
          context,
          ref,
          feed,
          openNow: openNow,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
        ),
      ),
    );
  }

  String _titleForVertical(WidgetRef ref, String id) {
    final async = ref.watch(commerceVerticalsProvider);
    return async.maybeWhen(
      data: (items) {
        for (final item in items) {
          if (item.id == id) {
            return item.name;
          }
        }
        return AppStrings.storefrontsTitle;
      },
      orElse: () => AppStrings.storefrontsTitle,
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    CatalogFeedState<StorefrontSummary> feed, {
    required bool openNow,
    required Future<void> Function() onRefresh,
    required Future<void> Function() onLoadMore,
  }) {
    if (feed.loading && feed.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (feed.error != null && feed.items.isEmpty) {
      return CatalogStatusView(
        message: feed.error is AppException
            ? feed.error!.message
            : AppStrings.catalogLoadError,
        onRetry: onRefresh,
      );
    }

    const chip = OpenNowFilterChip(
      padding: EdgeInsets.fromLTRB(0, 12, 0, 8),
    );

    if (feed.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          chip,
          CatalogStatusView(
            icon: Icons.storefront_outlined,
            message: openNow
                ? AppStrings.storefrontsOpenNowEmpty
                : AppStrings.storefrontsEmpty,
            retryLabel: openNow
                ? AppStrings.storefrontsShowAll
                : AppStrings.refresh,
            onRetry: openNow
                ? () =>
                      ref.read(openNowFilterProvider.notifier).setEnabled(false)
                : onRefresh,
          ),
        ],
      );
    }

    final extra = feed.hasMore || feed.loadMoreError != null ? 1 : 0;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: feed.items.length + extra + 1,
      separatorBuilder: (context, index) {
        if (index == 0) {
          return const SizedBox(height: 8);
        }
        return const SizedBox(height: 16);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return chip;
        }
        final itemIndex = index - 1;
        if (itemIndex >= feed.items.length) {
          return CatalogLoadMoreBar(
            hasMore: feed.hasMore,
            loadingMore: feed.loadingMore,
            loadMoreError: feed.loadMoreError,
            onLoadMore: onLoadMore,
          );
        }
        final storefront = feed.items[itemIndex];
        return StorefrontCard(
          key: ValueKey(storefront.branchId),
          storefront: storefront,
          onTap: () => context.push(AppRoutes.merchant(storefront.branchId)),
        );
      },
    );
  }
}
