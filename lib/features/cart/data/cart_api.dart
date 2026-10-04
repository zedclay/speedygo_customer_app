import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';

abstract class CartClient {
  Future<CartBootstrap> getCart();

  Future<CustomerCart> addItem(AddCartItemRequest request);

  Future<CustomerCart> updateItem({
    required String cartItemId,
    required UpdateCartItemRequest request,
  });

  Future<CartBootstrap> removeItem(String cartItemId);

  Future<CartBootstrap> clearCart();
}

class CartApi implements CartClient {
  CartApi(this._dio);

  final Dio _dio;

  @override
  Future<CartBootstrap> getCart() {
    return _send(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.customerCartPath),
      CartBootstrap.fromJson,
      additive: false,
    );
  }

  @override
  Future<CustomerCart> addItem(AddCartItemRequest request) {
    return _send(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerCartItemsPath,
        data: request.toJson(),
      ),
      CustomerCart.fromJson,
      additive: true,
    );
  }

  @override
  Future<CustomerCart> updateItem({
    required String cartItemId,
    required UpdateCartItemRequest request,
  }) {
    if (!CatalogIds.isLiveUuid(cartItemId)) {
      throw const CartParseException('cartItemId must be a live UUID');
    }
    return _send(
      () => _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.customerCartItemPath(cartItemId),
        data: request.toJson(),
      ),
      CustomerCart.fromJson,
      additive: false,
    );
  }

  @override
  Future<CartBootstrap> removeItem(String cartItemId) {
    if (!CatalogIds.isLiveUuid(cartItemId)) {
      throw const CartParseException('cartItemId must be a live UUID');
    }
    return _send(
      () => _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.customerCartItemPath(cartItemId),
      ),
      CartBootstrap.fromJson,
      additive: false,
    );
  }

  @override
  Future<CartBootstrap> clearCart() {
    return _send(
      () => _dio.delete<Map<String, dynamic>>(ApiEndpoints.customerCartPath),
      CartBootstrap.fromJson,
      additive: false,
    );
  }

  Future<T> _send<T>(
    Future<Response<Map<String, dynamic>>> Function() call,
    T Function(Map<String, dynamic> json) parse, {
    required bool additive,
  }) async {
    try {
      final response = await call();
      final data = response.data;
      if (data == null) {
        throw const CartParseException('Empty cart response');
      }
      return parse(data);
    } on CartParseException {
      rethrow;
    } on CartUncertainException {
      rethrow;
    } on AppException {
      rethrow;
    } catch (error) {
      if (additive && _isUncertain(error)) {
        throw const CartUncertainException();
      }
      throw mapDioError(error);
    }
  }

  bool _isUncertain(Object error) {
    if (error is! DioException) {
      return false;
    }
    return error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}
