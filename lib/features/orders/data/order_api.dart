import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';

abstract class OrdersClient {
  Future<OrderPage> listOrders({int limit = 20, int offset = 0});

  Future<OrderDetail> getOrder(String orderId);

  Future<OrderDetail> createOrder(CreateOrderRequest request);

  Future<OrderCancellationResult> cancelOrder(
    String orderId, {
    String? reason,
  });

  Future<CustomerOrderRefunds> listRefunds(String orderId);

  /// Owned order without Delivery → null (`DELIVERY_NOT_FOUND`).
  Future<CustomerDeliveryDetail?> getDelivery(String orderId);

  /// Requires an existing Delivery. `DELIVERY_NOT_FOUND` → null.
  Future<TrackingSnapshot?> getTracking(String orderId);

  Future<CustomerPayment> getPayment(String orderId);

  /// Empty body. Reuses open attempt when contract allows.
  Future<CustomerPaymentInitiate> initiatePayment(String orderId);
}

class OrdersApi implements OrdersClient {
  OrdersApi(this._dio);

  final Dio _dio;

  @override
  Future<OrderPage> listOrders({int limit = 20, int offset = 0}) {
    return _get(ApiEndpoints.customerOrdersPath, {
      'limit': limit,
      'offset': offset,
    }, OrderPage.fromJson);
  }

  @override
  Future<OrderDetail> getOrder(String orderId) {
    return _get(
      ApiEndpoints.customerOrderPath(orderId),
      const {},
      OrderDetail.fromJson,
    );
  }

  @override
  Future<OrderDetail> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerOrdersPath,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const OrderParseException('Empty order response');
      }
      return OrderDetail.fromJson(data);
    } on OrderParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapCreateError(error);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<OrderCancellationResult> cancelOrder(
    String orderId, {
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{};
      final trimmed = reason?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        body['reason'] = trimmed;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerOrderCancelPath(orderId),
        data: body,
      );
      final data = response.data;
      if (data == null) {
        throw const OrderParseException('Empty cancellation response');
      }
      return OrderCancellationResult.fromJson(data);
    } on OrderParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapCancelError(error);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<CustomerOrderRefunds> listRefunds(String orderId) {
    return _get(
      ApiEndpoints.customerOrderRefundsPath(orderId),
      const {},
      CustomerOrderRefunds.fromJson,
    );
  }

  @override
  Future<CustomerDeliveryDetail?> getDelivery(String orderId) async {
    try {
      return await _get(
        ApiEndpoints.customerOrderDeliveryPath(orderId),
        const {},
        CustomerDeliveryDetail.fromJson,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404 && error.code == 'DELIVERY_NOT_FOUND') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<TrackingSnapshot?> getTracking(String orderId) async {
    try {
      return await _get(
        ApiEndpoints.customerOrderTrackingPath(orderId),
        const {},
        TrackingSnapshot.fromJson,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404 &&
          (error.code == 'DELIVERY_NOT_FOUND' ||
              error.code == 'TRACKING_DELIVERY_NOT_FOUND')) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CustomerPayment> getPayment(String orderId) {
    return _get(
      ApiEndpoints.customerOrderPaymentPath(orderId),
      const {},
      CustomerPayment.fromJson,
    );
  }

  @override
  Future<CustomerPaymentInitiate> initiatePayment(String orderId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerOrderPaymentInitiatePath(orderId),
        data: const <String, dynamic>{},
      );
      final data = response.data;
      if (data == null) {
        throw const OrderParseException('Empty payment initiate response');
      }
      return CustomerPaymentInitiate.fromJson(data);
    } on OrderParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapPaymentInitiateError(error);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  AppException _mapPaymentInitiateError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return mapDioError(error);
    }
    final response = error.response;
    if (response == null) {
      return mapDioError(error);
    }
    if (response.statusCode != null && response.statusCode! >= 500) {
      return ApiException(
        AppStrings.paymentInitiateUncertain,
        code: 'PAYMENT_INITIATE_SERVER_UNCERTAIN',
        statusCode: response.statusCode,
      );
    }
    return parseOrderCancelException(response.statusCode, response.data);
  }

  AppException _mapCreateError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return mapDioError(error);
    }
    final response = error.response;
    if (response == null) {
      return mapDioError(error);
    }
    return parseOrderCreateException(response.statusCode, response.data);
  }

  AppException _mapCancelError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return mapDioError(error);
    }
    final response = error.response;
    if (response == null) {
      return mapDioError(error);
    }
    return parseOrderCancelException(response.statusCode, response.data);
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
        throw const OrderParseException('Empty order response');
      }
      return parse(data);
    } catch (error) {
      if (error is OrderParseException || error is AppException) {
        rethrow;
      }
      throw mapDioError(error);
    }
  }
}

AppException parseOrderCreateException(int? statusCode, Object? data) {
  if (data is Map) {
    final error = data['error'];
    if (error is Map) {
      final code = error['code']?.toString();
      if (code == 'ORDER_RECONFIRMATION_REQUIRED') {
        final rawChanges = error['changes'];
        final rawCurrent = error['current'];
        if (rawChanges is List && rawCurrent is Map) {
          return OrderReconfirmationException(
            message: AppStrings.orderReconfirmationRequired,
            changes: rawChanges.map((item) => item.toString()).toList(),
            current: OrderReconfirmationCurrent.fromJson(
              Map<String, dynamic>.from(rawCurrent),
            ),
          );
        }
      }
      return ApiException(
        AppStrings.errorForCode(code),
        code: code,
        statusCode: statusCode,
      );
    }
  }
  if (statusCode != null && statusCode >= 500) {
    return ApiException(
      AppStrings.orderSubmissionServerUncertain,
      code: 'ORDER_SUBMISSION_SERVER_UNCERTAIN',
      statusCode: statusCode,
    );
  }
  return ApiException(
    AppStrings.unexpected,
    code: 'HTTP_ERROR',
    statusCode: statusCode,
  );
}

AppException parseOrderCancelException(int? statusCode, Object? data) {
  if (data is Map) {
    final error = data['error'];
    if (error is Map) {
      final code = error['code']?.toString();
      return ApiException(
        AppStrings.errorForCode(code),
        code: code,
        statusCode: statusCode,
      );
    }
  }
  if (statusCode != null && statusCode >= 500) {
    return ApiException(
      AppStrings.orderCancelPendingVerification,
      code: 'ORDER_CANCELLATION_SERVER_UNCERTAIN',
      statusCode: statusCode,
    );
  }
  return ApiException(
    AppStrings.unexpected,
    code: 'HTTP_ERROR',
    statusCode: statusCode,
  );
}

bool isOrderSubmissionUncertain(AppException error) {
  return error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'ORDER_SUBMISSION_SERVER_UNCERTAIN';
}

bool isOrderCancellationUncertain(AppException error) {
  return error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'ORDER_CANCELLATION_SERVER_UNCERTAIN';
}
