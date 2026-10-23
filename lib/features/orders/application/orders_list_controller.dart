import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_feed.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

enum OrdersListFilter { inProgress, completed, cancelled }

class OrdersListState {
  const OrdersListState({
    this.items = const [],
    this.total = 0,
    this.loading = true,
    this.loadingMore = false,
    this.errorMessage,
    this.loadMoreError,
  });

  final List<OrderSummary> items;
  final int total;
  final bool loading;
  final bool loadingMore;
  final String? errorMessage;
  final AppException? loadMoreError;

  bool get hasMore => items.length < total;

  List<OrderSummary> filtered(OrdersListFilter filter) {
    return items.where((order) {
      switch (filter) {
        case OrdersListFilter.inProgress:
          return !order.isCompleted && !order.isCancelled;
        case OrdersListFilter.completed:
          return order.isCompleted;
        case OrdersListFilter.cancelled:
          return order.isCancelled;
      }
    }).toList();
  }

  OrdersListState copyWith({
    List<OrderSummary>? items,
    int? total,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
    AppException? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return OrdersListState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }
}

final ordersListControllerProvider =
    NotifierProvider<OrdersListController, OrdersListState>(
      OrdersListController.new,
    );

class OrdersListController extends Notifier<OrdersListState> {
  static const _pageSize = 20;
  var _generation = 0;
  var _loadMoreInFlight = false;

  @override
  OrdersListState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _loadMoreInFlight = false;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return const OrdersListState();
  }

  Future<void> refresh() async {
    final generation = _generation;
    _loadMoreInFlight = false;
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      clearError: true,
      clearLoadMoreError: true,
    );
    try {
      final page = await ref.read(ordersApiProvider).listOrders(
        limit: _pageSize,
        offset: 0,
      );
      if (generation != _generation) {
        return;
      }
      state = OrdersListState(items: page.items, total: page.total);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = OrdersListState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = OrdersListState(
        loading: false,
        errorMessage: AppStrings.ordersLoadError,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading ||
        state.loadingMore ||
        !state.hasMore ||
        _loadMoreInFlight) {
      return;
    }
    final generation = _generation;
    _loadMoreInFlight = true;
    state = state.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final page = await ref.read(ordersApiProvider).listOrders(
        limit: _pageSize,
        offset: state.items.length,
      );
      if (generation != _generation) {
        return;
      }
      state = OrdersListState(
        items: appendUniqueById(state.items, page.items, (item) => item.id),
        total: page.total,
      );
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(loadingMore: false, loadMoreError: error);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: UnexpectedException(AppStrings.ordersLoadError),
      );
    } finally {
      if (generation == _generation) {
        _loadMoreInFlight = false;
      }
    }
  }
}
