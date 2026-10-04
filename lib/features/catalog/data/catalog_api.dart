import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

class CatalogQuery {
  static const defaultLimit = 50;
  static const maxLimit = 100;
  static const maxOffset = 10000;
  static const sortName = 'name';

  const CatalogQuery({
    this.limit = defaultLimit,
    this.offset = 0,
    this.categoryId,
    this.verticalId,
    this.openNow = false,
  });

  final int limit;
  final int offset;
  final String? categoryId;
  final String? verticalId;
  final bool openNow;

  Map<String, dynamic> toParams() {
    final safeLimit = limit < 1 ? 1 : (limit > maxLimit ? maxLimit : limit);
    final safeOffset = offset < 0
        ? 0
        : (offset > maxOffset ? maxOffset : offset);
    return {
      'limit': safeLimit,
      'offset': safeOffset,
      'sort': sortName,
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': categoryId,
      if (verticalId != null && verticalId!.isNotEmpty)
        'verticalId': verticalId,
      if (openNow) 'openNow': true,
    };
  }
}

abstract class CatalogClient {
  Future<List<CommerceVertical>> listCommerceVerticals();

  Future<CatalogPage<StorefrontSummary>> listStorefronts({
    CatalogQuery query = const CatalogQuery(),
  });

  Future<StorefrontDetail> getStorefront(String branchId);

  Future<List<CatalogCategory>> listCategories(String branchId);

  Future<CatalogPage<CatalogProduct>> listProducts(
    String branchId, {
    CatalogQuery query = const CatalogQuery(),
  });

  Future<CatalogProductDetail> getProduct({
    required String branchId,
    required String productId,
  });

  Future<CatalogPage<CatalogSearchHit>> search(
    String q, {
    CatalogQuery query = const CatalogQuery(),
  });
}

class CatalogApi implements CatalogClient {
  CatalogApi(this._dio);

  final Dio _dio;

  @override
  Future<List<CommerceVertical>> listCommerceVerticals() {
    return _get(
      ApiEndpoints.customerCommerceVerticalsPath,
      const {},
      parseCommerceVerticalList,
    );
  }

  @override
  Future<CatalogPage<StorefrontSummary>> listStorefronts({
    CatalogQuery query = const CatalogQuery(),
  }) {
    return _get(
      ApiEndpoints.customerBranchesPath,
      query.toParams(),
      parseStorefrontPage,
    );
  }

  @override
  Future<StorefrontDetail> getStorefront(String branchId) {
    return _get(
      '${ApiEndpoints.customerBranchesPath}/$branchId',
      const {},
      StorefrontDetail.fromJson,
    );
  }

  @override
  Future<List<CatalogCategory>> listCategories(String branchId) {
    return _get(
      '${ApiEndpoints.customerBranchesPath}/$branchId/categories',
      const {},
      parseCategoryList,
    );
  }

  @override
  Future<CatalogPage<CatalogProduct>> listProducts(
    String branchId, {
    CatalogQuery query = const CatalogQuery(),
  }) {
    return _get(
      '${ApiEndpoints.customerBranchesPath}/$branchId/products',
      query.toParams(),
      parseProductPage,
    );
  }

  @override
  Future<CatalogProductDetail> getProduct({
    required String branchId,
    required String productId,
  }) {
    return _get(
      '${ApiEndpoints.customerBranchesPath}/$branchId/products/$productId',
      const {},
      CatalogProductDetail.fromJson,
    );
  }

  @override
  Future<CatalogPage<CatalogSearchHit>> search(
    String q, {
    CatalogQuery query = const CatalogQuery(),
  }) {
    return _get(ApiEndpoints.customerCatalogSearchPath, {
      'q': q,
      ...query.toParams(),
    }, parseSearchPage);
  }

  Future<T> _get<T>(
    String path,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: params,
      );
      final data = response.data;
      if (data == null) {
        throw const CatalogParseException('Empty catalog response');
      }
      return parse(data);
    } catch (error) {
      if (error is CatalogParseException) {
        rethrow;
      }
      throw mapDioError(error);
    }
  }
}
