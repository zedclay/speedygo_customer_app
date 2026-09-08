import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

abstract class AuthClient {
  Future<void> requestOtp(String identifier);
  Future<TokenPair> verifyOtp(OtpVerifyBody body);
  Future<TokenPair> refresh(String refreshToken);
  Future<void> logout();
  Future<void> logoutWithAccessToken(String accessToken);
  Future<AuthMe> me();
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
        throw const RefreshAmbiguousException();
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
}
