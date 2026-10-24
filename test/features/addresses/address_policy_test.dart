import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/addresses/domain/address_policy.dart';

void main() {
  test('rejects empty and oversized label and addressText', () {
    expect(AddressPolicy.validateLabel('  '), 'empty');
    expect(AddressPolicy.validateLabel('a' * 65), 'tooLong');
    expect(AddressPolicy.validateLabel('Domicile'), isNull);
    expect(AddressPolicy.validateAddressText(''), 'empty');
    expect(AddressPolicy.validateAddressText('x' * 501), 'tooLong');
    expect(AddressPolicy.validateAddressText('Cité 12'), isNull);
  });

  test('rejects coordinates outside the WGS84 range', () {
    expect(AddressPolicy.validateLatitude('91'), 'invalid');
    expect(AddressPolicy.validateLatitude('-90.1'), 'invalid');
    expect(AddressPolicy.validateLongitude('180.01'), 'invalid');
    expect(AddressPolicy.validateLatitude('36.7538'), isNull);
    expect(AddressPolicy.validateLongitude('3.0588'), isNull);
    expect(AddressPolicy.parseCoordinate('36,75'), 36.75);
  });

  test('rejects the 0,0 substitute and keeps street text unstuffed', () {
    expect(AddressPolicy.isUsablePoint(0, 0), isFalse);
    expect(AddressPolicy.isUsablePoint(35.1939, -0.6417), isTrue);
    expect(
      AddressPolicy.composeAddressText(
        street: 'Cité 1500 Logements',
        building: '12',
        floor: '3',
        entrance: 'B',
        landmark: 'Mosquée',
      ),
      'Cité 1500 Logements',
    );
  });

  test('sameDraft includes structured details', () {
    expect(
      AddressPolicy.sameDraft(
        label: 'Home',
        addressText: 'Cité 1500',
        latitude: 35.1939,
        longitude: -0.6417,
        building: '12',
        otherLabel: 'Home',
        otherAddressText: 'Cité 1500',
        otherLatitude: 35.1939,
        otherLongitude: -0.6417,
        otherBuilding: '12',
      ),
      isTrue,
    );
    expect(
      AddressPolicy.sameDraft(
        label: 'Home',
        addressText: 'Cité 1500',
        latitude: 35.1939,
        longitude: -0.6417,
        building: '12',
        otherLabel: 'Home',
        otherAddressText: 'Cité 1500',
        otherLatitude: 35.1939,
        otherLongitude: -0.6417,
        otherBuilding: '99',
      ),
      isFalse,
    );
  });
}
