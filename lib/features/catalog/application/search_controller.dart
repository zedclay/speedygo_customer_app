import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_feed.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_api.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/search_history_store.dart';

enum SearchPhase { idle, typing, loading, data, empty, error }

enum SearchHitTab { storefronts, products }

class CatalogSearchState {
  const CatalogSearchState({
    this.rawQuery = '',
    this.phase = SearchPhase.idle,
    this.page,
    this.error,
    this.loadingMore = false,
    this.loadMoreError,
    this.tab = SearchHitTab.storefronts,
    this.openNow = false,
    this.recents = const [],
  });

  final String rawQuery;
  final SearchPhase phase;
  final CatalogPage<CatalogSearchHit>? page;
  final AppException? error;
  final bool loadingMore;
  final AppException? loadMoreError;
  final SearchHitTab tab;
  final bool openNow;
  final List<String> recents;

  bool get hasMore {
    final page = this.page;
    if (page == null) {
      return false;
    }
    return page.items.length < page.total;
  }

  int get activeFilterCount => openNow ? 1 : 0;

  String? get hitType =>
      tab == SearchHitTab.storefronts ? 'STOREFRONT' : 'PRODUCT';

  CatalogSearchState copyWith({
    String? rawQuery,
    SearchPhase? phase,
    CatalogPage<CatalogSearchHit>? page,
    AppException? error,
    bool? loadingMore,
    AppException? loadMoreError,
    SearchHitTab? tab,
    bool? openNow,
    List<String>? recents,
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
      tab: tab ?? this.tab,
      openNow: openNow ?? this.openNow,
      recents: recents ?? this.recents,
    );
  }
}

final searchHistoryStoreProvider = Provider<SearchHistoryStore>((ref) {
  return SecureSearchHistoryStore();
});

class CatalogSearchController extends Notifier<CatalogSearchState> {
  Timer? _debounce;
  int _seq = 0;

  @override
  CatalogSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    ref.watch(catalogScopeProvider);
    ref.listen<AddressSelectionState>(addressSelectionProvider, (
      previous,
      next,
    ) {
      if (previous?.addressId == next.addressId) {
        return;
      }
      final normalized = normalizeCatalogSearchQuery(state.rawQuery);
      if (normalized.length >= catalogSearchMinLength) {
        unawaited(_run(normalized));
      }
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
      final normalized = normalizeCatalogSearchQuery(state.rawQuery);
      if (normalized.length >= catalogSearchMinLength) {
        unawaited(_run(normalized));
      }
    });
    Future<void>.microtask(_loadRecents);
    return const CatalogSearchState();
  }

  String _profileId() {
    return ref.read(sessionControllerProvider).customer?.profile?.id ?? '';
  }

  Future<void> _loadRecents() async {
    final items = await ref.read(searchHistoryStoreProvider).read(_profileId());
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(recents: items);
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

  /// Explicit submit (recent chip / committed query). Skips debounce so the
  /// results state is not left on the idle recents body.
  void submitQuery(String raw) {
    _debounce?.cancel();
    state = state.copyWith(rawQuery: raw);
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
    unawaited(_run(normalized));
  }

  void setTab(SearchHitTab tab) {
    if (state.tab == tab) {
      return;
    }
    state = state.copyWith(tab: tab);
    final normalized = normalizeCatalogSearchQuery(state.rawQuery);
    if (normalized.length >= catalogSearchMinLength) {
      unawaited(_run(normalized));
    }
  }

  void setOpenNow(bool enabled) {
    if (state.openNow == enabled) {
      return;
    }
    state = state.copyWith(openNow: enabled);
    final normalized = normalizeCatalogSearchQuery(state.rawQuery);
    if (normalized.length >= catalogSearchMinLength) {
      unawaited(_run(normalized));
    }
  }

  Future<void> clearRecents() async {
    await ref.read(searchHistoryStoreProvider).clear(_profileId());
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(recents: const []);
  }

  Future<void> retry() {
    return _run(normalizeCatalogSearchQuery(state.rawQuery));
  }

  CatalogQuery _query({int offset = 0}) {
    return CatalogQuery(
      limit: 50,
      offset: offset,
      openNow: state.openNow,
      addressId: effectiveCatalogAddressId(
        book: ref.read(addressBookProvider),
        selection: ref.read(addressSelectionProvider),
      ),
      hitType: state.hitType,
    );
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
          .search(normalized, query: _query());
      if (seq != _seq) {
        return;
      }
      final recents = await ref
          .read(searchHistoryStoreProvider)
          .record(_profileId(), normalized);
      if (seq != _seq || !ref.mounted) {
        return;
      }
      state = state.copyWith(
        phase: page.items.isEmpty ? SearchPhase.empty : SearchPhase.data,
        page: page,
        recents: recents,
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
            query: _query(offset: current.items.length),
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
