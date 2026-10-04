import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

abstract class RatingsClient {
  Future<RatingSummary> merchantSummary(String merchantId);

  Future<List<RatingSummary>> merchantSummaries(List<String> merchantIds);

  Future<OrderRating> rateMerchant(String orderId, CreateRatingRequest request);

  Future<OrderRating> rateDriver(String orderId, CreateRatingRequest request);

  Future<OrderRating?> getOwnMerchantRating(String orderId);

  Future<OrderRating?> getOwnDriverRating(String orderId);
}

class RatingsApi implements RatingsClient {
  RatingsApi(this._dio);

  final Dio _dio;

  @override
  Future<RatingSummary> merchantSummary(String merchantId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.customerMerchantRatingSummaryPath(merchantId),
      );
      final data = response.data;
      if (data == null) {
        throw const RatingParseException('Empty rating response');
      }
      return RatingSummary.fromJson(data);
    } catch (error) {
      if (error is RatingParseException || error is AppException) {
        rethrow;
      }
      throw mapDioError(error);
    }
  }

  @override
  Future<List<RatingSummary>> merchantSummaries(
    List<String> merchantIds,
  ) async {
    final unique = <String>{
      for (final id in merchantIds)
        if (id.isNotEmpty) id,
    }.toList();
    if (unique.isEmpty) {
      return const [];
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.customerMerchantRatingSummariesPath,
        queryParameters: {'merchantIds': unique.join(',')},
      );
      final data = response.data;
      if (data == null) {
        throw const RatingParseException('Empty rating batch response');
      }
      final raw = data['items'];
      if (raw is! List) {
        throw const RatingParseException('items must be a list');
      }
      return raw.map((item) {
        if (item is Map<String, dynamic>) {
          return RatingSummary.fromJson(item);
        }
        if (item is Map) {
          return RatingSummary.fromJson(Map<String, dynamic>.from(item));
        }
        throw const RatingParseException('summary must be an object');
      }).toList();
    } catch (error) {
      if (error is RatingParseException || error is AppException) {
        rethrow;
      }
      throw mapDioError(error);
    }
  }

  @override
  Future<OrderRating> rateMerchant(
    String orderId,
    CreateRatingRequest request,
  ) {
    return _postRating(
      ApiEndpoints.customerOrderMerchantRatingPath(orderId),
      request,
      uncertainCode: 'RATING_MERCHANT_UNCERTAIN',
    );
  }

  @override
  Future<OrderRating> rateDriver(
    String orderId,
    CreateRatingRequest request,
  ) {
    return _postRating(
      ApiEndpoints.customerOrderDriverRatingPath(orderId),
      request,
      uncertainCode: 'RATING_DRIVER_UNCERTAIN',
    );
  }

  @override
  Future<OrderRating?> getOwnMerchantRating(String orderId) {
    return _getOwn(ApiEndpoints.customerOrderMerchantRatingPath(orderId));
  }

  @override
  Future<OrderRating?> getOwnDriverRating(String orderId) {
    return _getOwn(ApiEndpoints.customerOrderDriverRatingPath(orderId));
  }

  Future<OrderRating> _postRating(
    String path,
    CreateRatingRequest request, {
    required String uncertainCode,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const RatingParseException('Empty rating create response');
      }
      return OrderRating.fromJson(data);
    } on RatingParseException {
      rethrow;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapMutationError(error, uncertainCode: uncertainCode);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<OrderRating?> _getOwn(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) {
        throw const RatingParseException('Empty own rating response');
      }
      return OrderRating.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw mapDioError(error);
    } catch (error) {
      if (error is RatingParseException || error is AppException) {
        rethrow;
      }
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
        AppStrings.ratingMutationUncertain,
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
}

bool isRatingMutationUncertain(AppException error) {
  return error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'RATING_MERCHANT_UNCERTAIN' ||
      error.code == 'RATING_DRIVER_UNCERTAIN';
}
