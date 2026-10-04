import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

class AddressParseException implements Exception {
  const AddressParseException([this.message = 'Invalid address payload']);

  final String message;

  @override
  String toString() => message;
}

class AddressUncertainException extends UnexpectedException {
  const AddressUncertainException()
    : super(
        'L’enregistrement n’a pas pu être confirmé. Vos saisies ont été conservées.',
        code: 'ADDRESS_MUTATION_UNCERTAIN',
      );
}

class CreateAddressRequest {
  const CreateAddressRequest({
    required this.label,
    required this.addressText,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String addressText;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'label': label,
    'addressText': addressText,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class UpdateAddressRequest {
  const UpdateAddressRequest({
    this.label,
    this.addressText,
    this.latitude,
    this.longitude,
  });

  final String? label;
  final String? addressText;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
      if (addressText != null) 'addressText': addressText,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

List<CustomerAddress> parseAddressList(Map<String, dynamic> json) {
  final raw = json['addresses'];
  if (raw is! List) {
    throw const AddressParseException('addresses must be an array');
  }
  final addresses = <CustomerAddress>[];
  for (final item in raw) {
    if (item is! Map) {
      throw const AddressParseException('address must be an object');
    }
    final address = CustomerAddress.fromJson(Map<String, dynamic>.from(item));
    if (address.id.isEmpty) {
      throw const AddressParseException('id is required');
    }
    addresses.add(address);
  }
  return addresses;
}

CustomerAddress parseAddress(Map<String, dynamic> json) {
  final address = CustomerAddress.fromJson(json);
  if (address.id.isEmpty) {
    throw const AddressParseException('id is required');
  }
  return address;
}
