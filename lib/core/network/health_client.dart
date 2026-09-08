import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/network/api_config.dart';

class HealthClient {
  HealthClient(this._config)
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

  final ApiConfig _config;
  final Dio _dio;

  Future<bool> ping() async {
    try {
      final response = await _dio.getUri<Map<String, dynamic>>(
        _config.healthUri,
      );
      return response.statusCode == 200 && response.data?['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }
}
