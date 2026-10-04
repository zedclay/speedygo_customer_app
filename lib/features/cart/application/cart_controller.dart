import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_api.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';

class CartUiState {
  const CartUiState({
    this.loading = false,
    this.mutating = false,
    this.reconciling = false,
    this.cart,
    this.error,
    this.actionError,
    this.scope = '',
  });

  final bool loading;
  final bool mutating;
  final bool reconciling;
  final CustomerCart? cart;
  final String? error;
  final String? actionError;
  final String scope;

  bool get cartExists => cart != null;
  int get badgeCount => cart?.itemCount ?? 0;

  CartUiState copyWith({
    bool? loading,
    bool? mutating,
    bool? reconciling,
    CustomerCart? cart,
    String? error,
    String? actionError,
    String? scope,
    bool clearCart = false,
    bool clearError = false,
    bool clearActionError = false,
  }) {
    return CartUiState(
      loading: loading ?? this.loading,
      mutating: mutating ?? this.mutating,
      reconciling: reconciling ?? this.reconciling,
      cart: clearCart ? null : (cart ?? this.cart),
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      scope: scope ?? this.scope,
    );
  }
}

final cartApiProvider = Provider<CartClient>((ref) {
  return CartApi(ref.watch(authInfrastructureProvider).dio);
});

class CartController extends Notifier<CartUiState> {
  Future<void> _queue = Future<void>.value();
  var _loadSeq = 0;

  @override
  CartUiState build() {
    final scope = ref.watch(catalogScopeProvider);
    _loadSeq += 1;
    _queue = Future<void>.value();
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh());
    });
    return CartUiState(loading: true, scope: scope);
  }

  String get _scope => ref.read(catalogScopeProvider);

  bool _isCurrent(String scope) {
    return ref.mounted && state.scope == scope && scope == _scope;
  }

  Future<T> _enqueue<T>(Future<T> Function() op) {
    final scope = _scope;
    late final Future<T> done;
    done = _queue.then((_) async {
      if (!_isCurrent(scope)) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      return op();
    });
    _queue = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  Future<void> refresh() async {
    final scope = _scope;
    final seq = ++_loadSeq;
    state = state.copyWith(
      loading: true,
      scope: scope,
      clearError: true,
      clearActionError: true,
    );
    try {
      final bootstrap = await ref.read(cartApiProvider).getCart();
      if (seq != _loadSeq || !_isCurrent(scope)) {
        return;
      }
      state = CartUiState(cart: bootstrap.cart, scope: scope);
    } catch (error) {
      if (seq != _loadSeq || !_isCurrent(scope)) {
        return;
      }
      state = state.copyWith(loading: false, error: _message(error));
    }
  }

  /// Returns true only after a confirmed server cart that includes the add.
  Future<bool> addItem(AddCartItemRequest request) {
    if (state.mutating) {
      return Future<bool>.value(false);
    }
    state = state.copyWith(mutating: true, clearActionError: true);
    return _enqueue(() => _addItem(request));
  }

  Future<bool> _addItem(AddCartItemRequest request) async {
    final scope = _scope;
    if (!CatalogIds.isLiveUuid(request.productId)) {
      if (_isCurrent(scope)) {
        state = state.copyWith(mutating: false);
      }
      return false;
    }
    final snapshot = state.cart;
    try {
      final cart = await ref.read(cartApiProvider).addItem(request);
      if (!_isCurrent(scope)) {
        return false;
      }
      state = CartUiState(cart: cart, scope: scope);
      return true;
    } on ApiException catch (error) {
      if (!_isCurrent(scope)) {
        return false;
      }
      state = state.copyWith(mutating: false, actionError: error.message);
      return false;
    } on CartUncertainException {
      if (!_isCurrent(scope)) {
        return false;
      }
      return _reconcileAdd(scope: scope, snapshot: snapshot, request: request);
    } catch (error) {
      if (!_isCurrent(scope)) {
        return false;
      }
      state = state.copyWith(mutating: false, actionError: _message(error));
      return false;
    }
  }

  Future<bool> _reconcileAdd({
    required String scope,
    required CustomerCart? snapshot,
    required AddCartItemRequest request,
  }) async {
    state = state.copyWith(mutating: true, reconciling: true);
    try {
      final bootstrap = await ref.read(cartApiProvider).getCart();
      if (!_isCurrent(scope)) {
        return false;
      }
      final cart = bootstrap.cart;
      state = CartUiState(
        cart: cart,
        reconciling: false,
        scope: scope,
        actionError: _addConfirmed(snapshot, cart, request)
            ? null
            : AppStrings.cartAddUnconfirmed,
      );
      return _addConfirmed(snapshot, cart, request);
    } catch (error) {
      if (!_isCurrent(scope)) {
        return false;
      }
      state = state.copyWith(
        mutating: false,
        reconciling: false,
        actionError: AppStrings.cartAddUnconfirmed,
      );
      return false;
    }
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) {
    return _enqueue(() async {
      final scope = _scope;
      if (!CatalogIds.isLiveUuid(cartItemId)) {
        return;
      }
      state = state.copyWith(mutating: true, clearActionError: true);
      try {
        final cart = await ref
            .read(cartApiProvider)
            .updateItem(
              cartItemId: cartItemId,
              request: UpdateCartItemRequest(quantity: quantity),
            );
        if (!_isCurrent(scope)) {
          return;
        }
        state = CartUiState(cart: cart, scope: scope);
      } catch (error) {
        if (!_isCurrent(scope)) {
          return;
        }
        state = state.copyWith(mutating: false, actionError: _message(error));
      }
    });
  }

  Future<void> removeItem(String cartItemId) {
    return _enqueue(() async {
      final scope = _scope;
      if (!CatalogIds.isLiveUuid(cartItemId)) {
        return;
      }
      state = state.copyWith(mutating: true, clearActionError: true);
      try {
        final bootstrap = await ref
            .read(cartApiProvider)
            .removeItem(cartItemId);
        if (!_isCurrent(scope)) {
          return;
        }
        state = CartUiState(cart: bootstrap.cart, scope: scope);
      } catch (error) {
        if (!_isCurrent(scope)) {
          return;
        }
        state = state.copyWith(mutating: false, actionError: _message(error));
      }
    });
  }

  Future<void> clearCart() {
    return _enqueue(() async {
      final scope = _scope;
      state = state.copyWith(mutating: true, clearActionError: true);
      try {
        final bootstrap = await ref.read(cartApiProvider).clearCart();
        if (!_isCurrent(scope)) {
          return;
        }
        state = CartUiState(cart: bootstrap.cart, scope: scope);
      } catch (error) {
        if (!_isCurrent(scope)) {
          return;
        }
        state = state.copyWith(mutating: false, actionError: _message(error));
      }
    });
  }

  void dismissActionError() {
    if (state.actionError == null) {
      return;
    }
    state = state.copyWith(clearActionError: true);
  }

  String _message(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return mapDioError(error).message;
  }
}

bool _addConfirmed(
  CustomerCart? before,
  CustomerCart? after,
  AddCartItemRequest request,
) {
  if (after == null) {
    return false;
  }
  CartItem? match;
  for (final item in after.items) {
    if (item.productId == request.productId &&
        sameOptionSet(
          item.selectedOptions.map((option) => option.optionId),
          request.optionIds,
        )) {
      match = item;
      break;
    }
  }
  if (match == null) {
    return false;
  }
  if (before == null) {
    return match.quantity >= request.quantity;
  }
  var previousQty = 0;
  for (final item in before.items) {
    if (item.productId == request.productId &&
        sameOptionSet(
          item.selectedOptions.map((option) => option.optionId),
          request.optionIds,
        )) {
      previousQty = item.quantity;
      break;
    }
  }
  return match.quantity >= previousQty + request.quantity;
}

final cartControllerProvider = NotifierProvider<CartController, CartUiState>(
  CartController.new,
);
