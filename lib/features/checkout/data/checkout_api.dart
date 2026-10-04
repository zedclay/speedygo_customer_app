import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';

abstract class CheckoutClient {
  Future<CheckoutPreview> preview(CheckoutPreviewRequest request);
}

class CheckoutApi implements CheckoutClient {
  CheckoutApi(this._dio);

  final Dio _dio;

  @override
  Future<CheckoutPreview> preview(CheckoutPreviewRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerCheckoutPreviewPath,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const CheckoutParseException('Empty checkout preview response');
      }
      return CheckoutPreview.fromJson(data);
    } on CheckoutParseException {
      rethrow;
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
