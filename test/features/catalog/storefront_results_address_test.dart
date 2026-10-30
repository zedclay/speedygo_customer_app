import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/favorites/application/favorites_controller.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';

const _verticalId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _addrA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _addrB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';

class _TestAddressSelection extends AddressSelectionController {
  _TestAddressSelection(this.initial);

  final AddressSelectionState initial;

  @override
  AddressSelectionState build() => initial;

  void setAddress(String? addressId) {
    state = AddressSelectionState(profileId: 'p', addressId: addressId);
  }
}

const _ownedPins = [
  CustomerAddress(
    id: _addrA,
    label: 'Hydra',
    addressText: 'Hydra',
    isDefault: true,
    latitude: 36.75,
    longitude: 3.05,
  ),
  CustomerAddress(
    id: _addrB,
    label: 'SBA',
    addressText: 'SBA',
    isDefault: false,
    latitude: 35.19,
    longitude: -0.64,
  ),
];

// Typed as a helper returning provider overrides; inference avoids importing
// riverpod's Override symbol which is not a public test-file type here.
_overrides({
  required FakeCatalogClient catalog,
  required _TestAddressSelection selection,
  List<CustomerAddress> addresses = _ownedPins,
}) {
  return [
    catalogApiProvider.overrideWithValue(catalog),
    catalogScopeProvider.overrideWithValue('1:p'),
    addressSelectionProvider.overrideWith(() => selection),
    addressApiProvider.overrideWithValue(FakeAddressClient(addresses: addresses)),
    favoritesApiProvider.overrideWithValue(FakeFavoritesClient()),
  ];
}

void main() {
  testWidgets('vertical results refresh when the selected address changes', (
    tester,
  ) async {
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [cafeStorefront()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
    );
    final selection = _TestAddressSelection(
      const AddressSelectionState(profileId: 'p', addressId: _addrA),
    );
    final container = ProviderContainer(
      overrides: _overrides(catalog: catalog, selection: selection),
    );
    addTearDown(container.dispose);

    container.read(storefrontResultsControllerProvider(_verticalId));
    await tester.pump();
    await tester.pump();
    expect(catalog.lastStorefrontQuery?.addressId, _addrA);
    expect(catalog.lastStorefrontQuery?.verticalId, _verticalId);

    selection.setAddress(_addrB);
    await tester.pump();
    await tester.pump();
    expect(catalog.lastStorefrontQuery?.addressId, _addrB);
    expect(catalog.lastStorefrontQuery?.wilayaCode, isNull);
  });

  testWidgets('stale address response is discarded for a newer pin', (
    tester,
  ) async {
    final catalog = FakeCatalogClient();
    catalog.storefrontsFor = (query) {
      final name = query.addressId == _addrB ? 'B-shop' : 'A-shop';
      return CatalogPage(
        items: [cafeStorefront(branchName: name)],
        limit: 50,
        offset: 0,
        total: 1,
      );
    };
    final selection = _TestAddressSelection(
      const AddressSelectionState(profileId: 'p', addressId: _addrA),
    );
    final container = ProviderContainer(
      overrides: _overrides(catalog: catalog, selection: selection),
    );
    addTearDown(container.dispose);

    container.read(storefrontResultsControllerProvider(_verticalId));
    await tester.pump();
    await tester.pump();
    expect(
      container.read(storefrontResultsControllerProvider(_verticalId)).items.single.branchName,
      'A-shop',
    );

    final gate = Completer<void>();
    catalog.gateList = gate;
    selection.setAddress(_addrB);
    await tester.pump();
    catalog.gateList = null;
    selection.setAddress(_addrA);
    await tester.pump();
    await tester.pump();
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(catalog.lastStorefrontQuery?.addressId, _addrA);
    expect(
      container.read(storefrontResultsControllerProvider(_verticalId)).items.single.branchName,
      'A-shop',
    );
  });

  testWidgets('vertical results refresh when launch wilaya changes', (
    tester,
  ) async {
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [cafeStorefront()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
    );
    final selection = _TestAddressSelection(
      const AddressSelectionState(profileId: 'p'),
    );
    final container = ProviderContainer(
      overrides: _overrides(
        catalog: catalog,
        selection: selection,
        addresses: const [],
      ),
    );
    addTearDown(container.dispose);

    container.read(storefrontResultsControllerProvider(_verticalId));
    await tester.pump();
    await tester.pump();
    expect(catalog.lastStorefrontQuery?.wilayaCode, '22');

    container.read(launchWilayaCodeProvider.notifier).select('16');
    await tester.pump();
    await tester.pump();
    expect(catalog.lastStorefrontQuery?.wilayaCode, '16');
  });
}
