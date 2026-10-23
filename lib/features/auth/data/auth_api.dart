import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

abstract class AuthClient {
  Future<void> requestOtp(String identifier);
  Future<TokenPair> verifyOtp(OtpVerifyBody body);
  Future<TokenPair> refresh(String refreshToken);
  Future<void> logout();
  Future<void> logoutWithAccessToken(String accessToken);
  Future<void> logoutAll();
  Future<AuthMe> me();
  Future<List<AuthSession>> listSessions();
  Future<void> revokeSession(String sessionId);
}

class AuthApi implements AuthClient {
  AuthApi({required this._dio, required this._refreshDio});

  final Dio _dio;
  final Dio _refreshDio;

  @override
  Future<void> requestOtp(String identifier) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.otpRequestPath,
        data: OtpRequestBody(identifier: identifier).toJson(),
      );
      final accepted = response.data?['accepted'];
      if (accepted != true) {
        throw const ApiException(
          'La demande n’a pas été acceptée.',
          code: 'OTP_NOT_ACCEPTED',
        );
      }
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TokenPair> verifyOtp(OtpVerifyBody body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.otpVerifyPath,
        data: body.toJson(),
      );
      return TokenPair.fromJson(response.data ?? {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  /// Uses [refreshDio] so the auth interceptor cannot recurse.
  @override
  Future<TokenPair> refresh(String refreshToken) async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshPath,
        data: {'refreshToken': refreshToken},
      );
      return TokenPair.fromJson(response.data ?? {});
    } on DioException catch (error) {
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw RefreshAmbiguousException();
      }
      throw mapDioError(error);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>(ApiEndpoints.logoutPath);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  /// Logout without the auth interceptor (no refresh recursion).
  @override
  Future<void> logoutWithAccessToken(String accessToken) async {
    try {
      await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.logoutPath,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<AuthMe> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.authMePath,
      );
      return AuthMe.fromJson(response.data ?? {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<List<AuthSession>> listSessions() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.authSessionsPath,
      );
      final raw = response.data;
      if (raw == null) {
        return const [];
      }
      return [
        for (final item in raw)
          if (item is Map)
            AuthSession.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.authSessionPath(sessionId),
      );
    } on DioException catch (error) {
      throw _mapSessionMutationError(
        error,
        uncertainCode: 'SESSION_REVOKE_UNCERTAIN',
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> logoutAll() async {
    try {
      await _dio.post<Map<String, dynamic>>(ApiEndpoints.logoutAllPath);
    } on DioException catch (error) {
      throw _mapSessionMutationError(
        error,
        uncertainCode: 'SESSION_LOGOUT_ALL_UNCERTAIN',
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  AppException _mapSessionMutationError(
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
        AppStrings.securityRevokeUncertain,
        code: uncertainCode,
        statusCode: response.statusCode,
      );
    }
    return mapDioError(error);
  }
}

bool isSessionMutationUncertain(AppException error) {
  return error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'SESSION_REVOKE_UNCERTAIN' ||
      error.code == 'SESSION_LOGOUT_ALL_UNCERTAIN';
}
