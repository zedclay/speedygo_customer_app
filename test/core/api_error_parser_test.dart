import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';

void main() {
  test('connection failures map to NETWORK with the offline copy', () {
    final error = mapDioError(
      DioException(
        requestOptions: RequestOptions(path: '/auth/otp/request'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    expect(error, isA<NetworkException>());
    expect(error.code, 'NETWORK');
    expect(error.message, AppStrings.offline);
  });

  test('I/O timeouts map to NETWORK_TIMEOUT with the same offline copy', () {
    final error = mapDioError(
      DioException(
        requestOptions: RequestOptions(path: '/auth/otp/request'),
        type: DioExceptionType.receiveTimeout,
      ),
    );
    expect(error, isA<NetworkException>());
    expect(error.code, 'NETWORK_TIMEOUT');
    expect(error.message, AppStrings.offline);
    expect(isRetryableNetwork(error), isFalse);
  });

  test('HTTP envelopes keep their status and business code', () {
    final error = mapDioError(
      DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 401,
          data: {
            'error': {'code': 'AUTH_INVALID_TOKEN'},
          },
        ),
      ),
    );
    expect(error, isA<ApiException>());
    expect(error.statusCode, 401);
    expect(error.code, 'AUTH_INVALID_TOKEN');
    expect(error.message, isNot(AppStrings.offline));
  });
}
