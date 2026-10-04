import 'package:dio/dio.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_models.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';

abstract class AddressClient {
  Future<List<CustomerAddress>> list();

  Future<CustomerAddress> create(CreateAddressRequest request);

  Future<CustomerAddress> update({
    required String addressId,
    required UpdateAddressRequest request,
  });

  Future<void> delete(String addressId);

  Future<CustomerAddress> setDefault(String addressId);
}

class AddressApi implements AddressClient {
  AddressApi(this._dio);

  final Dio _dio;

  @override
  Future<List<CustomerAddress>> list() {
    return _send(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.customerAddressesPath),
      parseAddressList,
      additive: false,
    );
  }

  @override
  Future<CustomerAddress> create(CreateAddressRequest request) {
    return _send(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.customerAddressesPath,
        data: request.toJson(),
      ),
      parseAddress,
      additive: true,
    );
  }

  @override
  Future<CustomerAddress> update({
    required String addressId,
    required UpdateAddressRequest request,
  }) {
    _assertMutableId(addressId);
    return _send(
      () => _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.customerAddressPath(addressId),
        data: request.toJson(),
      ),
      parseAddress,
      additive: false,
    );
  }

  @override
  Future<void> delete(String addressId) async {
    _assertMutableId(addressId);
    await _send(
      () => _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.customerAddressPath(addressId),
      ),
      _parseDeleted,
      additive: false,
    );
  }

  @override
  Future<CustomerAddress> setDefault(String addressId) {
    _assertMutableId(addressId);
    return _send(
      () => _dio.put<Map<String, dynamic>>(
        ApiEndpoints.customerAddressDefaultPath(addressId),
      ),
      parseAddress,
      additive: false,
    );
  }

  void _assertMutableId(String addressId) {
    if (CatalogIds.isFixture(addressId) || addressId.isEmpty) {
      throw const AddressParseException('addressId is not mutable');
    }
  }

  Future<T> _send<T>(
    Future<Response<Map<String, dynamic>>> Function() call,
    T Function(Map<String, dynamic> json) parse, {
    required bool additive,
  }) async {
    try {
      final response = await call();
      final data = response.data;
      if (data == null) {
        throw const AddressParseException('Empty address response');
      }
      return parse(data);
    } on AddressParseException {
      rethrow;
    } on AddressUncertainException {
      rethrow;
    } on AppException {
      rethrow;
    } catch (error) {
      if (additive && _isUncertain(error)) {
        throw const AddressUncertainException();
      }
      throw mapDioError(error);
    }
  }

  bool _isUncertain(Object error) {
    if (error is! DioException) {
      return false;
    }
    return error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}

bool _parseDeleted(Map<String, dynamic> json) {
  if (json['deleted'] != true) {
    throw const AddressParseException('deleted must be true');
  }
  return true;
}
