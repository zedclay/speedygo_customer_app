import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';

abstract class PromotionsClient {
  Future<List<DiscoverablePromotion>> listDiscoverable();
}

class PromotionsApi implements PromotionsClient {
  PromotionsApi(this._dio);

  final Dio _dio;

  @override
  Future<List<DiscoverablePromotion>> listDiscoverable() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.customerPromotionsPath,
      );
      final data = response.data;
      if (data == null) {
        throw const PromotionParseException('Empty promotions response');
      }
      return parseDiscoverablePromotionList(data);
    } catch (error) {
      if (error is PromotionParseException) {
        rethrow;
      }
      throw mapDioError(error);
    }
  }
}
