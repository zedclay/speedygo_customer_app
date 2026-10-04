import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_api.dart';

class CatalogFeedState<T> {
  const CatalogFeedState({
    this.items = const [],
    this.total = 0,
    this.limit = CatalogQuery.defaultLimit,
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.loadMoreError,
  });

  final List<T> items;
  final int total;
  final int limit;
  final bool loading;
  final bool loadingMore;
  final AppException? error;
  final AppException? loadMoreError;

  bool get hasMore => items.length < total;
  bool get isEmpty => !loading && error == null && items.isEmpty;

  CatalogFeedState<T> copyWith({
    List<T>? items,
    int? total,
    int? limit,
    bool? loading,
    bool? loadingMore,
    AppException? error,
    AppException? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return CatalogFeedState<T>(
      items: items ?? this.items,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : error ?? this.error,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}

List<T> appendUniqueById<T>(
  List<T> current,
  List<T> incoming,
  String Function(T item) idOf,
) {
  final seen = {for (final item in current) idOf(item)};
  final merged = [...current];
  for (final item in incoming) {
    final id = idOf(item);
    if (seen.add(id)) {
      merged.add(item);
    }
  }
  return merged;
}

AppException mapCatalogError(Object error) {
  if (error is AppException) {
    return error;
  }
  return const UnexpectedException(AppStrings.unexpected);
}
