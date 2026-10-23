import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';

AppException mapDioError(Object error) {
  if (error is AppException) {
    return error;
  }
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return NetworkException(AppStrings.offline, code: 'NETWORK');
    }
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        AppStrings.offline,
        code: 'NETWORK_TIMEOUT',
        statusCode: error.response?.statusCode,
      );
    }
    final response = error.response;
    if (response != null) {
      return parseApiException(response.statusCode, response.data);
    }
    return NetworkException(AppStrings.offline, code: 'NETWORK');
  }
  return UnexpectedException(AppStrings.unexpected);
}

ApiException parseApiException(int? statusCode, Object? data) {
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
  return ApiException(
    AppStrings.unexpected,
    code: 'HTTP_ERROR',
    statusCode: statusCode,
  );
}

bool isRetryableNetwork(AppException error) {
  return error is NetworkException && error.code != 'NETWORK_TIMEOUT';
}
