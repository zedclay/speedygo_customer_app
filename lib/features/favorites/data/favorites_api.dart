import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

class FavoriteIds {
  const FavoriteIds({
    this.branchIds = const {},
    this.productIds = const {},
  });

  final Set<String> branchIds;
  final Set<String> productIds;

  bool hasBranch(String branchId) => branchIds.contains(branchId);

  bool hasProduct(String productId) => productIds.contains(productId);
}

class FavoriteProduct {
  const FavoriteProduct({required this.product, required this.storefront});

  final CatalogProduct product;
  final StorefrontSummary storefront;
}

class FavoriteList {
  const FavoriteList({
    required this.kind,
    this.branches = const [],
    this.products = const [],
  });

  final String kind;
  final List<StorefrontSummary> branches;
  final List<FavoriteProduct> products;
}

abstract class FavoritesClient {
  Future<FavoriteIds> listIds();

  Future<FavoriteList> list({required String kind, String? addressId});

  Future<void> addBranch(String branchId);

  Future<void> removeBranch(String branchId);

  Future<void> addProduct(String productId);

  Future<void> removeProduct(String productId);
}

class FavoritesApi implements FavoritesClient {
  FavoritesApi(this._dio);

  final Dio _dio;

  @override
  Future<FavoriteIds> listIds() {
    return _get('/customer/favorites/ids', (json) {
      return FavoriteIds(
        branchIds: _idSet(json['branchIds']),
        productIds: _idSet(json['productIds']),
      );
    });
  }

  @override
  Future<FavoriteList> list({required String kind, String? addressId}) {
    return _get('/customer/favorites', (json) {
      final branches = <StorefrontSummary>[];
      final rawBranches = json['branches'];
      if (rawBranches is List) {
        for (final item in rawBranches) {
          if (item is Map<String, dynamic>) {
            branches.add(StorefrontSummary.fromJson(item));
          } else if (item is Map) {
            branches.add(
              StorefrontSummary.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
      final products = <FavoriteProduct>[];
      final rawProducts = json['products'];
      if (rawProducts is List) {
        for (final item in rawProducts) {
          if (item is! Map) {
            continue;
          }
          final map = Map<String, dynamic>.from(item);
          final productRaw = map['product'];
          final storefrontRaw = map['storefront'];
          if (productRaw is! Map || storefrontRaw is! Map) {
            continue;
          }
          products.add(
            FavoriteProduct(
              product: CatalogProduct.fromJson(
                Map<String, dynamic>.from(productRaw),
              ),
              storefront: StorefrontSummary.fromJson(
                Map<String, dynamic>.from(storefrontRaw),
              ),
            ),
          );
        }
      }
      return FavoriteList(
        kind: json['kind']?.toString() ?? kind,
        branches: branches,
        products: products,
      );
    }, params: {
      'kind': kind,
      if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
    });
  }

  @override
  Future<void> addBranch(String branchId) {
    return _put('/customer/favorites/branches/$branchId');
  }

  @override
  Future<void> removeBranch(String branchId) {
    return _delete('/customer/favorites/branches/$branchId');
  }

  @override
  Future<void> addProduct(String productId) {
    return _put('/customer/favorites/products/$productId');
  }

  @override
  Future<void> removeProduct(String productId) {
    return _delete('/customer/favorites/products/$productId');
  }

  Set<String> _idSet(Object? raw) {
    if (raw is! List) {
      return {};
    }
    return {
      for (final item in raw)
        if (item != null && item.toString().isNotEmpty) item.toString(),
    };
  }

  Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic> json) parse, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: params,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException('Empty favorites response');
      }
      return parse(data);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> _put(String path) async {
    try {
      await _dio.put<Map<String, dynamic>>(path);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> _delete(String path) async {
    try {
      await _dio.delete<Map<String, dynamic>>(path);
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
