import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_feed.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_scope.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_api.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

export 'package:speedygo_customer_app/features/catalog/application/catalog_scope.dart';

final catalogApiProvider = Provider<CatalogClient>((ref) {
  return CatalogApi(ref.watch(authInfrastructureProvider).dio);
});

class SelectedCommerceVertical extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(catalogScopeProvider);
    return null;
  }

  void select(String? verticalId) {
    state = verticalId;
  }
}

final selectedCommerceVerticalIdProvider =
    NotifierProvider<SelectedCommerceVertical, String?>(
      SelectedCommerceVertical.new,
    );

/// Account-scoped “Ouverts maintenant” filter for Home + category results.
class OpenNowFilter extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(catalogScopeProvider);
    return false;
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }

  void toggle() {
    state = !state;
  }
}

final openNowFilterProvider = NotifierProvider<OpenNowFilter, bool>(
  OpenNowFilter.new,
);

final commerceVerticalsProvider = FutureProvider<List<CommerceVertical>>((
  ref,
) async {
  ref.watch(catalogScopeProvider);
  return ref.read(catalogApiProvider).listCommerceVerticals();
});

class StorefrontListController
    extends Notifier<CatalogFeedState<StorefrontSummary>> {
  int _seq = 0;
  var _loadMoreInFlight = false;

  @override
  CatalogFeedState<StorefrontSummary> build() {
    ref.watch(catalogScopeProvider);
    ref.listen<String?>(selectedCommerceVerticalIdProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(refresh());
    });
    ref.listen<bool>(openNowFilterProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(refresh());
    });
    ref.listen<AddressSelectionState>(addressSelectionProvider, (
      previous,
      next,
    ) {
      if (previous?.addressId == next.addressId) {
        return;
      }
      unawaited(refresh());
    });
    ref.listen<AddressUiState>(addressBookProvider, (previous, next) {
      final selection = ref.read(addressSelectionProvider);
      final before = previous == null
          ? null
          : effectiveCatalogAddressId(book: previous, selection: selection);
      final after = effectiveCatalogAddressId(
        book: next,
        selection: selection,
      );
      if (before == after) {
        return;
      }
      unawaited(refresh());
    });
    ref.listen<String>(launchWilayaCodeProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(refresh());
    });
    _loadMoreInFlight = false;
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh());
    });
    return const CatalogFeedState();
  }

  CatalogQuery _query({int offset = 0}) {
    final addressId = effectiveCatalogAddressId(
      book: ref.read(addressBookProvider),
      selection: ref.read(addressSelectionProvider),
    );
    return CatalogQuery(
      offset: offset,
      verticalId: ref.read(selectedCommerceVerticalIdProvider),
      openNow: ref.read(openNowFilterProvider),
      addressId: addressId,
      // Wilaya is discovery-only and must not AND-filter same-zone branches.
      wilayaCode: (addressId == null || addressId.isEmpty)
          ? ref.read(launchWilayaCodeProvider)
          : null,
    );
  }

  Future<void> refresh() async {
    final seq = ++_seq;
    _loadMoreInFlight = false;
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      items: const [],
      total: 0,
      clearError: true,
      clearLoadMoreError: true,
      clearCoverage: true,
    );
    try {
      final page = await ref
          .read(catalogApiProvider)
          .listStorefronts(query: _query());
      if (seq != _seq) {
        return;
      }
      state = CatalogFeedState(
        items: page.items,
        total: page.total,
        limit: page.limit,
        loading: false,
        coverage: page.coverage,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(loading: false, error: mapCatalogError(error));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || _loadMoreInFlight) {
      return;
    }
    _loadMoreInFlight = true;
    final seq = _seq;
    state = state.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final page = await ref
          .read(catalogApiProvider)
          .listStorefronts(query: _query(offset: state.items.length));
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        items: appendUniqueById(
          state.items,
          page.items,
          (item) => item.branchId,
        ),
        total: page.total,
        limit: page.limit,
        loadingMore: false,
        clearLoadMoreError: true,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: mapCatalogError(error),
      );
    } finally {
      if (seq == _seq) {
        _loadMoreInFlight = false;
      }
    }
  }
}

final storefrontListControllerProvider =
    NotifierProvider<
      StorefrontListController,
      CatalogFeedState<StorefrontSummary>
    >(StorefrontListController.new);

/// Storefront results scoped by `verticalId` (empty = unfiltered).
/// Independent of [selectedCommerceVerticalIdProvider] / Home chips.
class StorefrontResultsController
    extends Notifier<CatalogFeedState<StorefrontSummary>> {
  StorefrontResultsController(this.verticalId);

  final String verticalId;
  int _seq = 0;
  var _loadMoreInFlight = false;

  @override
  CatalogFeedState<StorefrontSummary> build() {
    ref.watch(catalogScopeProvider);
    ref.listen<bool>(openNowFilterProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(refresh());
    });
    ref.listen<AddressSelectionState>(addressSelectionProvider, (
      previous,
      next,
    ) {
      if (previous?.addressId == next.addressId) {
        return;
      }
      unawaited(refresh());
    });
    ref.listen<AddressUiState>(addressBookProvider, (previous, next) {
      final selection = ref.read(addressSelectionProvider);
      final before = previous == null
          ? null
          : effectiveCatalogAddressId(book: previous, selection: selection);
      final after = effectiveCatalogAddressId(
        book: next,
        selection: selection,
      );
      if (before == after) {
        return;
      }
      unawaited(refresh());
    });
    ref.listen<String>(launchWilayaCodeProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(refresh());
    });
    _loadMoreInFlight = false;
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh());
    });
    return const CatalogFeedState();
  }

  CatalogQuery _query({int offset = 0}) {
    final id = verticalId.trim();
    final addressId = effectiveCatalogAddressId(
      book: ref.read(addressBookProvider),
      selection: ref.read(addressSelectionProvider),
    );
    return CatalogQuery(
      offset: offset,
      verticalId: id.isEmpty ? null : id,
      openNow: ref.read(openNowFilterProvider),
      addressId: addressId,
      wilayaCode: (addressId == null || addressId.isEmpty)
          ? ref.read(launchWilayaCodeProvider)
          : null,
    );
  }

  Future<void> refresh() async {
    final seq = ++_seq;
    _loadMoreInFlight = false;
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      items: const [],
      total: 0,
      clearError: true,
      clearLoadMoreError: true,
      clearCoverage: true,
    );
    try {
      final page = await ref
          .read(catalogApiProvider)
          .listStorefronts(query: _query());
      if (seq != _seq) {
        return;
      }
      state = CatalogFeedState(
        items: page.items,
        total: page.total,
        limit: page.limit,
        loading: false,
        coverage: page.coverage,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(loading: false, error: mapCatalogError(error));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || _loadMoreInFlight) {
      return;
    }
    _loadMoreInFlight = true;
    final seq = _seq;
    state = state.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final page = await ref
          .read(catalogApiProvider)
          .listStorefronts(query: _query(offset: state.items.length));
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        items: appendUniqueById(
          state.items,
          page.items,
          (item) => item.branchId,
        ),
        total: page.total,
        limit: page.limit,
        loadingMore: false,
        clearLoadMoreError: true,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: mapCatalogError(error),
      );
    } finally {
      if (seq == _seq) {
        _loadMoreInFlight = false;
      }
    }
  }
}

final storefrontResultsControllerProvider =
    NotifierProvider.family<
      StorefrontResultsController,
      CatalogFeedState<StorefrontSummary>,
      String
    >(StorefrontResultsController.new);

final storefrontDetailProvider = FutureProvider.autoDispose
    .family<StorefrontDetail, String>((ref, branchId) async {
      ref.watch(catalogScopeProvider);
      return ref.read(catalogApiProvider).getStorefront(branchId);
    });

final storefrontCategoriesProvider = FutureProvider.autoDispose
    .family<List<CatalogCategory>, String>((ref, branchId) async {
      ref.watch(catalogScopeProvider);
      return ref.read(catalogApiProvider).listCategories(branchId);
    });

class StorefrontProductsArgs {
  const StorefrontProductsArgs({required this.branchId, this.categoryId});

  final String branchId;
  final String? categoryId;

  @override
  bool operator ==(Object other) {
    return other is StorefrontProductsArgs &&
        other.branchId == branchId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(branchId, categoryId);
}

class StorefrontProductsController
    extends Notifier<CatalogFeedState<CatalogProduct>> {
  StorefrontProductsController(this.args);

  final StorefrontProductsArgs args;
  int _seq = 0;
  var _loadMoreInFlight = false;

  @override
  CatalogFeedState<CatalogProduct> build() {
    ref.watch(catalogScopeProvider);
    _loadMoreInFlight = false;
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh());
    });
    return const CatalogFeedState();
  }

  Future<void> refresh() async {
    final seq = ++_seq;
    _loadMoreInFlight = false;
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      items: const [],
      total: 0,
      clearError: true,
      clearLoadMoreError: true,
    );
    try {
      final page = await ref
          .read(catalogApiProvider)
          .listProducts(
            args.branchId,
            query: CatalogQuery(categoryId: args.categoryId),
          );
      if (seq != _seq) {
        return;
      }
      state = CatalogFeedState(
        items: page.items,
        total: page.total,
        limit: page.limit,
        loading: false,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(loading: false, error: mapCatalogError(error));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || _loadMoreInFlight) {
      return;
    }
    _loadMoreInFlight = true;
    final seq = _seq;
    state = state.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final page = await ref
          .read(catalogApiProvider)
          .listProducts(
            args.branchId,
            query: CatalogQuery(
              offset: state.items.length,
              categoryId: args.categoryId,
            ),
          );
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        items: appendUniqueById(
          state.items,
          page.items,
          (item) => item.productId,
        ),
        total: page.total,
        limit: page.limit,
        loadingMore: false,
        clearLoadMoreError: true,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: mapCatalogError(error),
      );
    } finally {
      if (seq == _seq) {
        _loadMoreInFlight = false;
      }
    }
  }
}

final storefrontProductsControllerProvider =
    NotifierProvider.family<
      StorefrontProductsController,
      CatalogFeedState<CatalogProduct>,
      StorefrontProductsArgs
    >(StorefrontProductsController.new);

class ProductDetailArgs {
  const ProductDetailArgs({required this.branchId, required this.productId});

  final String branchId;
  final String productId;

  @override
  bool operator ==(Object other) {
    return other is ProductDetailArgs &&
        other.branchId == branchId &&
        other.productId == productId;
  }

  @override
  int get hashCode => Object.hash(branchId, productId);
}

final productDetailProvider = FutureProvider.autoDispose
    .family<CatalogProductDetail, ProductDetailArgs>((ref, args) async {
      ref.watch(catalogScopeProvider);
      return ref
          .read(catalogApiProvider)
          .getProduct(branchId: args.branchId, productId: args.productId);
    });
