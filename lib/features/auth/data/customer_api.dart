import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

abstract class CustomerClient {
  Future<CustomerMe> me();
  Future<CustomerProfile> createProfile({required String fullName});
}

class CustomerApi implements CustomerClient {
  CustomerApi(this._dio);

  final Dio _dio;

  @override
  Future<CustomerMe> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.customerMePath,
      );
      return CustomerMe.fromJson(response.data ?? {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<CustomerProfile> createProfile({required String fullName}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerProfilePath,
        data: {'fullName': fullName},
      );
      return CustomerProfile.fromJson(response.data ?? {});
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
