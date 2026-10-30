import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/favorites/data/favorites_api.dart';

enum FavoriteTab { storefronts, products }

class FavoritesState {
  const FavoritesState({
    this.ids = const FavoriteIds(),
    this.list,
    this.tab = FavoriteTab.storefronts,
    this.loading = true,
    this.error,
    this.pending = const {},
  });

  final FavoriteIds ids;
  final FavoriteList? list;
  final FavoriteTab tab;
  final bool loading;
  final AppException? error;
  final Set<String> pending;

  String get kind =>
      tab == FavoriteTab.storefronts ? 'BRANCH' : 'PRODUCT';

  FavoritesState copyWith({
    FavoriteIds? ids,
    FavoriteList? list,
    FavoriteTab? tab,
    bool? loading,
    AppException? error,
    Set<String>? pending,
    bool clearList = false,
    bool clearError = false,
  }) {
    return FavoritesState(
      ids: ids ?? this.ids,
      list: clearList ? null : list ?? this.list,
      tab: tab ?? this.tab,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      pending: pending ?? this.pending,
    );
  }
}

final favoritesApiProvider = Provider<FavoritesClient>((ref) {
  return FavoritesApi(ref.watch(authInfrastructureProvider).dio);
});

class FavoritesController extends Notifier<FavoritesState> {
  int _seq = 0;

  @override
  FavoritesState build() {
    ref.watch(catalogScopeProvider);
    ref.listen<AddressSelectionState>(addressSelectionProvider, (
      previous,
      next,
    ) {
      if (previous?.addressId == next.addressId) {
        return;
      }
      unawaited(reload());
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
      unawaited(reload());
    });
    Future<void>.microtask(reload);
    return const FavoritesState();
  }

  Future<void> reload() async {
    final seq = ++_seq;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(favoritesApiProvider);
      final ids = await api.listIds();
      final list = await api.list(
        kind: state.kind,
        addressId: effectiveCatalogAddressId(
          book: ref.read(addressBookProvider),
          selection: ref.read(addressSelectionProvider),
        ),
      );
      if (seq != _seq || !ref.mounted) {
        return;
      }
      state = state.copyWith(
        ids: ids,
        list: list,
        loading: false,
        clearError: true,
      );
    } catch (error) {
      if (seq != _seq || !ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        error: error is AppException
            ? error
            : UnexpectedException(AppStrings.unexpected),
        clearList: true,
      );
    }
  }

  Future<void> setTab(FavoriteTab tab) async {
    if (state.tab == tab) {
      return;
    }
    state = state.copyWith(tab: tab);
    await reload();
  }

  Future<bool> toggleBranch(String branchId) {
    return _toggle(
      id: branchId,
      saved: state.ids.hasBranch(branchId),
      add: () => ref.read(favoritesApiProvider).addBranch(branchId),
      remove: () => ref.read(favoritesApiProvider).removeBranch(branchId),
      apply: (ids, saved) => FavoriteIds(
        branchIds: saved
            ? {...ids.branchIds, branchId}
            : ({...ids.branchIds}..remove(branchId)),
        productIds: ids.productIds,
      ),
    );
  }

  Future<bool> toggleProduct(String productId) {
    return _toggle(
      id: productId,
      saved: state.ids.hasProduct(productId),
      add: () => ref.read(favoritesApiProvider).addProduct(productId),
      remove: () => ref.read(favoritesApiProvider).removeProduct(productId),
      apply: (ids, saved) => FavoriteIds(
        branchIds: ids.branchIds,
        productIds: saved
            ? {...ids.productIds, productId}
            : ({...ids.productIds}..remove(productId)),
      ),
    );
  }

  Future<bool> _toggle({
    required String id,
    required bool saved,
    required Future<void> Function() add,
    required Future<void> Function() remove,
    required FavoriteIds Function(FavoriteIds ids, bool saved) apply,
  }) async {
    if (id.isEmpty || state.pending.contains(id)) {
      return false;
    }
    final previous = state.ids;
    state = state.copyWith(
      ids: apply(previous, !saved),
      pending: {...state.pending, id},
      clearError: true,
    );
    try {
      if (saved) {
        await remove();
      } else {
        await add();
      }
      if (!ref.mounted) {
        return true;
      }
      await reload();
      if (!ref.mounted) {
        return true;
      }
      state = state.copyWith(pending: {...state.pending}..remove(id));
      return true;
    } catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        ids: previous,
        pending: {...state.pending}..remove(id),
        error: error is AppException
            ? error
            : UnexpectedException(AppStrings.favoritesSaveError),
      );
      return false;
    }
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesState>(
      FavoritesController.new,
    );
