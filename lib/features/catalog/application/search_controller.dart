import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_feed.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_api.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

enum SearchPhase { idle, typing, loading, data, empty, error }

class CatalogSearchState {
  const CatalogSearchState({
    this.rawQuery = '',
    this.phase = SearchPhase.idle,
    this.page,
    this.error,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final String rawQuery;
  final SearchPhase phase;
  final CatalogPage<CatalogSearchHit>? page;
  final AppException? error;
  final bool loadingMore;
  final AppException? loadMoreError;

  bool get hasMore {
    final page = this.page;
    if (page == null) {
      return false;
    }
    return page.items.length < page.total;
  }

  CatalogSearchState copyWith({
    String? rawQuery,
    SearchPhase? phase,
    CatalogPage<CatalogSearchHit>? page,
    AppException? error,
    bool? loadingMore,
    AppException? loadMoreError,
    bool clearPage = false,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return CatalogSearchState(
      rawQuery: rawQuery ?? this.rawQuery,
      phase: phase ?? this.phase,
      page: clearPage ? null : page ?? this.page,
      error: clearError ? null : error ?? this.error,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}

class CatalogSearchController extends Notifier<CatalogSearchState> {
  Timer? _debounce;
  int _seq = 0;

  @override
  CatalogSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    ref.watch(catalogScopeProvider);
    return const CatalogSearchState();
  }

  void setQuery(String raw) {
    state = state.copyWith(rawQuery: raw, phase: SearchPhase.typing);
    _debounce?.cancel();
    final normalized = normalizeCatalogSearchQuery(raw);
    if (normalized.length < catalogSearchMinLength) {
      _seq += 1;
      state = state.copyWith(
        phase: SearchPhase.idle,
        loadingMore: false,
        clearPage: true,
        clearError: true,
        clearLoadMoreError: true,
      );
      return;
    }
    if (normalized.length > catalogSearchMaxLength) {
      _seq += 1;
      _debounce = null;
      state = state.copyWith(
        phase: SearchPhase.error,
        error: ApiException(
          AppStrings.searchQueryInvalid,
          code: 'CUSTOMER_SEARCH_QUERY_INVALID',
        ),
        clearPage: true,
      );
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_run(normalized));
    });
  }

  Future<void> retry() {
    return _run(normalizeCatalogSearchQuery(state.rawQuery));
  }

  Future<void> _run(String normalized) async {
    if (normalized.length < catalogSearchMinLength ||
        normalized.length > catalogSearchMaxLength) {
      return;
    }
    final seq = ++_seq;
    state = state.copyWith(
      phase: SearchPhase.loading,
      loadingMore: false,
      clearError: true,
      clearLoadMoreError: true,
    );
    try {
      final page = await ref
          .read(catalogApiProvider)
          .search(normalized, query: const CatalogQuery(limit: 50, offset: 0));
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        phase: page.items.isEmpty ? SearchPhase.empty : SearchPhase.data,
        page: page,
        loadingMore: false,
        clearError: true,
        clearLoadMoreError: true,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        phase: SearchPhase.error,
        error: error is AppException
            ? error
            : UnexpectedException(AppStrings.unexpected),
        loadingMore: false,
        clearPage: true,
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.page;
    if (state.phase != SearchPhase.data ||
        state.loadingMore ||
        current == null ||
        !state.hasMore) {
      return;
    }
    final normalized = normalizeCatalogSearchQuery(state.rawQuery);
    if (normalized.length < catalogSearchMinLength ||
        normalized.length > catalogSearchMaxLength) {
      return;
    }
    final seq = _seq;
    state = state.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final page = await ref
          .read(catalogApiProvider)
          .search(
            normalized,
            query: CatalogQuery(limit: 50, offset: current.items.length),
          );
      if (seq != _seq) {
        return;
      }
      final merged = appendUniqueById(current.items, page.items, _hitId);
      state = state.copyWith(
        phase: merged.isEmpty ? SearchPhase.empty : SearchPhase.data,
        page: CatalogPage(
          items: merged,
          limit: page.limit,
          offset: 0,
          total: page.total,
        ),
        loadingMore: false,
        clearLoadMoreError: true,
      );
    } catch (error) {
      if (seq != _seq) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: error is AppException
            ? error
            : UnexpectedException(AppStrings.unexpected),
      );
    }
  }
}

String _hitId(CatalogSearchHit hit) {
  if (hit.type == CatalogHitType.storefront) {
    return 's:${hit.storefront!.branchId}';
  }
  return 'p:${hit.product!.productId}';
}

final catalogSearchControllerProvider =
    NotifierProvider<CatalogSearchController, CatalogSearchState>(
      CatalogSearchController.new,
    );
