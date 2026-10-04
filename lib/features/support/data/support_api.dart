import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

abstract class SupportClient {
  Future<SupportTicketPage> listTickets({int limit = 50, int offset = 0});

  Future<SupportTicketDetail> getTicket(
    String ticketId, {
    int limit = 50,
    int offset = 0,
  });

  Future<SupportTicketDetail> createTicket(CreateSupportTicketRequest request);

  Future<SupportMessage> reply(String ticketId, String body);
}

class SupportApi implements SupportClient {
  SupportApi(this._dio);

  final Dio _dio;

  @override
  Future<SupportTicketPage> listTickets({int limit = 50, int offset = 0}) {
    return _get(
      ApiEndpoints.customerSupportPath,
      {'limit': limit, 'offset': offset},
      SupportTicketPage.fromJson,
    );
  }

  @override
  Future<SupportTicketDetail> getTicket(
    String ticketId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _get(
      ApiEndpoints.customerSupportTicketPath(ticketId),
      {'limit': limit, 'offset': offset},
      SupportTicketDetail.fromJson,
    );
  }

  @override
  Future<SupportTicketDetail> createTicket(
    CreateSupportTicketRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerSupportPath,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const SupportParseException('Empty support create response');
      }
      return SupportTicketDetail.fromJson(data);
    } on SupportParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapMutationError(error, uncertainCode: 'SUPPORT_CREATE_UNCERTAIN');
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<SupportMessage> reply(String ticketId, String body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerSupportTicketMessagesPath(ticketId),
        data: {'body': body},
      );
      final data = response.data;
      if (data == null) {
        throw const SupportParseException('Empty support reply response');
      }
      return SupportMessage.fromJson(data);
    } on SupportParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapMutationError(error, uncertainCode: 'SUPPORT_REPLY_UNCERTAIN');
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
        AppStrings.supportMutationUncertain,
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
        throw const SupportParseException('Empty support response');
      }
      return parse(data);
    } catch (error) {
      if (error is SupportParseException || error is AppException) {
        rethrow;
      }
      throw mapDioError(error);
    }
  }
}

class SupportParseException implements Exception {
  const SupportParseException(this.message);
  final String message;
}

bool isSupportMutationUncertain(AppException error) {
  return error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'SUPPORT_CREATE_UNCERTAIN' ||
      error.code == 'SUPPORT_REPLY_UNCERTAIN';
}
