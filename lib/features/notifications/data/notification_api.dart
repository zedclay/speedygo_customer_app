import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';

abstract class NotificationsClient {
  Future<NotificationPage> list({int limit = 20, int offset = 0});

  Future<UnreadCountResponse> unreadCount();

  Future<NotificationItem> markRead(String notificationId);

  Future<MarkAllReadResponse> markAllRead();

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });

  Future<void> deactivateDeviceToken({required String token});
}

class NotificationsApi implements NotificationsClient {
  NotificationsApi(this._dio);

  final Dio _dio;

  @override
  Future<NotificationPage> list({int limit = 20, int offset = 0}) {
    return _get(
      ApiEndpoints.notificationsPath,
      {'limit': limit, 'offset': offset},
      NotificationPage.fromJson,
    );
  }

  @override
  Future<UnreadCountResponse> unreadCount() {
    return _get(
      ApiEndpoints.notificationsUnreadCountPath,
      const {},
      UnreadCountResponse.fromJson,
    );
  }

  @override
  Future<NotificationItem> markRead(String notificationId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationReadPath(notificationId),
      );
      final data = response.data;
      if (data == null) {
        throw const NotificationParseException('Empty mark-read response');
      }
      return NotificationItem.fromJson(data);
    } on NotificationParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapMutationError(error, uncertainCode: 'NOTIFICATION_READ_UNCERTAIN');
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<MarkAllReadResponse> markAllRead() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsReadAllPath,
      );
      final data = response.data;
      if (data == null) {
        throw const NotificationParseException('Empty mark-all response');
      }
      return MarkAllReadResponse.fromJson(data);
    } on NotificationParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapMutationError(
        error,
        uncertainCode: 'NOTIFICATION_READ_ALL_UNCERTAIN',
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  AppException _mapMutationError(
    DioException error, {
    required String uncertainCode,
  }) {
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
        AppStrings.notificationsMarkReadError,
        code: uncertainCode,
        statusCode: response.statusCode,
      );
    }
    if (response.data is Map) {
      final err = (response.data as Map)['error'];
      if (err is Map) {
        final code = err['code']?.toString();
        return ApiException(
          AppStrings.errorForCode(code),
          code: code,
          statusCode: response.statusCode,
        );
      }
    }
    return ApiException(
      AppStrings.unexpected,
      code: 'HTTP_ERROR',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.deviceTokensPath,
        data: {'token': token, 'platform': platform},
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> deactivateDeviceToken({required String token}) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.deviceTokensPath,
        data: {'token': token},
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<T> _get<T>(
    String path,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: params.isEmpty ? null : params,
      );
      final data = response.data;
      if (data == null) {
        throw const NotificationParseException('Empty notifications response');
      }
      return parse(data);
    } catch (error) {
      if (error is NotificationParseException || error is AppException) {
        rethrow;
      }
      throw mapDioError(error);
    }
  }
}

class NotificationParseException implements Exception {
  const NotificationParseException(this.message);
  final String message;
}

bool isNotificationMutationUncertain(AppException error) {
  return error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'NOTIFICATION_READ_UNCERTAIN' ||
      error.code == 'NOTIFICATION_READ_ALL_UNCERTAIN';
}
