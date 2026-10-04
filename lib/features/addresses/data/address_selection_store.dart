import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddressSelectionRecord {
  const AddressSelectionRecord({
    required this.profileId,
    required this.addressId,
  });

  final String profileId;
  final String addressId;
}

/// Client-only Home selection. Scoped to a CustomerProfile id.
/// Does not call PUT /customer/addresses/:id/default.
abstract class AddressSelectionStore {
  Future<AddressSelectionRecord?> read();

  Future<void> write(AddressSelectionRecord record);

  Future<void> clear();
}

class SecureAddressSelectionStore implements AddressSelectionStore {
  SecureAddressSelectionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'speedygo.customer.address-selection.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<AddressSelectionRecord?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw);
      if (map is! Map) {
        await clear();
        return null;
      }
      final profileId = map['profileId']?.toString() ?? '';
      final addressId = map['addressId']?.toString() ?? '';
      if (profileId.isEmpty || addressId.isEmpty) {
        await clear();
        return null;
      }
      return AddressSelectionRecord(profileId: profileId, addressId: addressId);
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AddressSelectionRecord record) {
    return _storage.write(
      key: _key,
      value: jsonEncode({
        'profileId': record.profileId,
        'addressId': record.addressId,
      }),
    );
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _key);
  }
}

class MemoryAddressSelectionStore implements AddressSelectionStore {
  AddressSelectionRecord? value;

  @override
  Future<AddressSelectionRecord?> read() async => value;

  @override
  Future<void> write(AddressSelectionRecord record) async {
    value = record;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}
