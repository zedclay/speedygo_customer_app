import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/address_form_screen.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';

import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

const _home = CustomerAddress(
  id: 'addr-home',
  label: 'Domicile',
  addressText: 'Cité 120 logements',
  isDefault: true,
  latitude: 36.75,
  longitude: 3.05,
);

const _work = CustomerAddress(
  id: 'addr-work',
  label: 'Bureau',
  addressText: 'Rue du Travail',
  isDefault: false,
  latitude: 36.76,
  longitude: 3.06,
);

FakeCustomerClient _customer({List<CustomerAddress> addresses = const []}) {
  String? defaultId;
  for (final address in addresses) {
    if (address.isDefault) {
      defaultId = address.id;
    }
  }
  return FakeCustomerClient()
    ..meResult = CustomerMe(
      customerProfileExists: true,
      profileComplete: true,
      addressReady: defaultId != null,
      profile: const CustomerProfile(id: 'p', fullName: 'Amel Benali'),
      defaultAddressId: defaultId,
      addresses: addresses,
    );
}

Finder _key(String value) => find.byKey(Key(value), skipOffstage: false);

void main() {
  testWidgets(
    'empty list offers add and Home stays usable without an address',
    (tester) async {
      await tester.pumpWidget(
        readyApp(customer: _customer(), addresses: FakeAddressClient()),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.deliverToUnset), findsOneWidget);
      expect(find.text(AppStrings.searchHint), findsOneWidget);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.addressesTitle));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addresses-empty')), findsOneWidget);
      expect(find.text(AppStrings.addressesEmpty), findsOneWidget);
    },
  );

  testWidgets('list error can be retried', (tester) async {
    final api = FakeAddressClient()
      ..listError = ApiException(
        AppStrings.addressesLoadError,
        code: 'NETWORK',
      );
    await tester.pumpWidget(readyApp(customer: _customer(), addresses: api));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressesLoadError), findsOneWidget);
    api.listError = null;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('addresses-empty')), findsOneWidget);
  });

  testWidgets('add edit select and delete keep Home in sync', (tester) async {
    final api = FakeAddressClient(addresses: [_home, _work]);
    final selection = MemoryAddressSelectionStore();
    await tester.pumpWidget(
      readyApp(
        customer: _customer(addresses: [_home, _work]),
        addresses: api,
        addressSelection: selection,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Domicile'), findsOneWidget);

    await tester.tap(find.text('Domicile'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('picker-address-addr-work')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Bureau'), findsOneWidget);
    expect(selection.value?.addressId, 'addr-work');
    expect(api.defaultCount, 0);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('address-label-field')),
      'Revue test Hydra',
    );
    await tester.enterText(
      find.byKey(const Key('address-text-field')),
      '12 chemin test Revue',
    );
    await tester.enterText(_key('address-latitude-field'), '36.7538');
    await tester.enterText(_key('address-longitude-field'), '3.0588');
    await tester.tap(find.byKey(const Key('address-save-button')));
    await tester.pumpAndSettle();
    expect(api.createCount, 1);
    expect(
      api.addresses.map((address) => address.label),
      contains('Revue test Hydra'),
    );
    expect(find.text('Revue test Hydra'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('address-label-field')),
      'Revue test Hydra edit',
    );
    await tester.tap(find.byKey(const Key('address-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('Revue test Hydra edit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-address-addr-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-address')));
    await tester.pumpAndSettle();
    expect(find.text('Bureau'), findsNothing);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    expect(find.text('Revue test Hydra edit'), findsOneWidget);
    expect(selection.value?.addressId, 'addr-created-1');
  });

  testWidgets('recoverable create failure keeps the typed form', (
    tester,
  ) async {
    final api = FakeAddressClient()
      ..createError = ApiException(
        AppStrings.addressInvalid,
        code: 'CUSTOMER_ADDRESS_INVALID',
      );
    await tester.pumpWidget(readyApp(customer: _customer(), addresses: api));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('address-label-field')),
      'Revue keep',
    );
    await tester.enterText(
      find.byKey(const Key('address-text-field')),
      'Texte conservé',
    );
    await tester.enterText(_key('address-latitude-field'), '36.75');
    await tester.enterText(_key('address-longitude-field'), '3.05');
    await tester.tap(find.byKey(const Key('address-save-button')));
    await tester.pumpAndSettle();
    expect(api.createCount, 1);
    expect(find.text(AppStrings.addressInvalid), findsOneWidget);
    expect(find.text('Revue keep'), findsOneWidget);
    expect(find.text('Texte conservé'), findsOneWidget);
  });

  testWidgets('location permission is requested only after a user action', (
    tester,
  ) async {
    final location = FakeLocationClient(access: LocationAccess.denied);
    await tester.pumpWidget(
      readyApp(customer: _customer(), location: location),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('use-my-location')),
      400,
      scrollable: find
          .descendant(
            of: find.byType(AddressFormScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('use-my-location')));
    await tester.pumpAndSettle();
    expect(location.requestCount, 0);
    await tester.tap(find.byKey(const Key('allow-location-button')));
    await tester.pumpAndSettle();
    expect(location.requestCount, 1);
    expect(location.readCount, 0);
    expect(find.byKey(const Key('location-permission-error')), findsOneWidget);
    expect(find.text(AppStrings.locationDenied), findsOneWidget);
  });

  testWidgets('disabled location services and missing fix are reported', (
    tester,
  ) async {
    final location = FakeLocationClient(
      access: LocationAccess.servicesDisabled,
    );
    await tester.pumpWidget(
      readyApp(customer: _customer(), location: location),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deliverToUnset));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addAddressShort));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('use-my-location')),
      400,
      scrollable: find
          .descendant(
            of: find.byType(AddressFormScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('use-my-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('allow-location-button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.locationServicesDisabled), findsOneWidget);

    location.access = LocationAccess.granted;
    location.readError = const LocationUnavailableException();
    await tester.tap(find.byKey(const Key('allow-location-button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.locationUnavailable), findsOneWidget);
  });

  testWidgets('permanently denied location is reported without reading GPS', (
    tester,
  ) async {
    final location = FakeLocationClient(access: LocationAccess.deniedForever);
    await tester.pumpWidget(
      readyApp(customer: _customer(), location: location),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('use-my-location')),
      400,
      scrollable: find
          .descendant(
            of: find.byType(AddressFormScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('use-my-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('allow-location-button')));
    await tester.pumpAndSettle();
    expect(location.requestCount, 1);
    expect(location.readCount, 0);
    expect(find.text(AppStrings.locationDeniedForever), findsOneWidget);
  });

  testWidgets('setting a second address as default leaves Home selection', (
    tester,
  ) async {
    final api = FakeAddressClient(addresses: [_home, _work]);
    final selection = MemoryAddressSelectionStore();
    await tester.pumpWidget(
      readyApp(
        customer: _customer(addresses: [_home, _work]),
        addresses: api,
        addressSelection: selection,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Domicile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker-address-addr-home')));
    await tester.pumpAndSettle();
    expect(find.text('Domicile'), findsOneWidget);
    expect(api.defaultCount, 0);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-default-addr-work')));
    await tester.pumpAndSettle();
    expect(api.defaultCount, 1);
    expect(
      api.addresses.firstWhere((item) => item.id == 'addr-work').isDefault,
      isTrue,
    );
    expect(
      api.addresses.firstWhere((item) => item.id == 'addr-home').isDefault,
      isFalse,
    );
    expect(selection.value?.addressId, 'addr-home');
    expect(find.text(AppStrings.selectedAddressBadge), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    expect(find.text('Domicile'), findsOneWidget);
  });

  testWidgets('editing the selected address updates Home', (tester) async {
    final api = FakeAddressClient(addresses: [_home, _work]);
    await tester.pumpWidget(
      readyApp(
        customer: _customer(addresses: [_home, _work]),
        addresses: api,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Domicile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker-address-addr-work')));
    await tester.pumpAndSettle();
    expect(find.text('Bureau'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('address-label-field')),
      'Bureau édité',
    );
    await tester.tap(find.byKey(const Key('address-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('Bureau édité'), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    expect(find.text('Bureau édité'), findsOneWidget);
    expect(find.text('Domicile'), findsNothing);
  });

  testWidgets('deleting the selected default address clears Home', (
    tester,
  ) async {
    final api = FakeAddressClient(addresses: [_home, _work]);
    final selection = MemoryAddressSelectionStore();
    await tester.pumpWidget(
      readyApp(
        customer: _customer(addresses: [_home, _work]),
        addresses: api,
        addressSelection: selection,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Domicile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker-address-addr-home')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-address-addr-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-address')));
    await tester.pumpAndSettle();
    expect(find.text('Domicile'), findsNothing);
    expect(selection.value, isNull);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deliverToUnset), findsOneWidget);
  });

  testWidgets('confirming GPS fills the form and does not save an address', (
    tester,
  ) async {
    final api = FakeAddressClient();
    final location = FakeLocationClient(
      access: LocationAccess.granted,
      position: const DeviceLocation(latitude: 36.7538, longitude: 3.0588),
    );
    await tester.pumpWidget(
      readyApp(customer: _customer(), addresses: api, location: location),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('use-my-location')),
      400,
      scrollable: find
          .descendant(
            of: find.byType(AddressFormScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('use-my-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('allow-location-button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.confirmLocationTitle), findsOneWidget);
    expect(find.byKey(const Key('confirm-latitude')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-location-button')));
    await tester.pumpAndSettle();
    expect(_key('address-latitude-field'), findsOneWidget);
    expect(api.createCount, 0);
    expect(
      tester.widget<TextField>(_key('address-latitude-field')).controller!.text,
      contains('36.7538'),
    );
  });

  testWidgets('save stays reachable with keyboard and large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final api = FakeAddressClient(addresses: [_home]);
    await tester.pumpWidget(
      readyApp(customer: _customer(addresses: [_home]), addresses: api),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('isDefault'), findsNothing);
    expect(find.text(AppStrings.addressCoordsHint), findsOneWidget);
    expect(find.text(AppStrings.addressDefaultHint), findsNothing);
    expect(find.byKey(const Key('address-save-button')), findsOneWidget);
    tester.view.viewInsets = FakeViewPadding(
      bottom: 280 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    final save = find.byKey(const Key('address-save-button'));
    expect(
      MediaQuery.viewInsetsOf(tester.element(save)).bottom,
      280,
    );
    expect(save.hitTestable(), findsOneWidget);
    final rect = tester.getRect(save);
    final viewHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(rect.bottom, lessThanOrEqualTo(viewHeight - 280 + 0.5));
  });

  testWidgets('save leave reopen keeps structured details and street text', (
    tester,
  ) async {
    final api = FakeAddressClient();
    await tester.pumpWidget(readyApp(customer: _customer(), addresses: api));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('address-label-field')),
      'Domicile détails',
    );
    await tester.enterText(
      find.byKey(const Key('address-text-field')),
      'Cité 1500 Logements',
    );
    await tester.enterText(_key('address-latitude-field'), '35.1939');
    await tester.enterText(_key('address-longitude-field'), '-0.6417');
    await tester.scrollUntilVisible(
      find.byKey(const Key('address-building-field')),
      300,
      scrollable: find
          .descendant(
            of: find.byType(AddressFormScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(_key('address-building-field'), 'Bloc Z');
    await tester.enterText(_key('address-floor-field'), '3');
    await tester.enterText(_key('address-entrance-field'), 'B');
    await tester.enterText(_key('address-landmark-field'), 'Mosquée');
    await tester.tap(find.byKey(const Key('address-save-button')));
    await tester.pumpAndSettle();
    expect(api.createCount, 1);
    expect(api.creates.single.toJson(), containsPair('building', 'Bloc Z'));
    expect(api.creates.single.toJson(), containsPair('addressText', 'Cité 1500 Logements'));
    expect(api.addresses.single.building, 'Bloc Z');
    expect(api.addresses.single.addressText, 'Cité 1500 Logements');

    await tester.tap(find.byKey(const Key('edit-address-addr-created-1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(const Key('address-text-field'))).controller?.text,
      'Cité 1500 Logements',
    );
    final formScrollable = find
        .descendant(
          of: find.byType(AddressFormScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('address-building-field')),
      300,
      scrollable: formScrollable,
    );
    expect(
      tester.widget<TextField>(_key('address-building-field')).controller?.text,
      'Bloc Z',
    );
    expect(
      tester.widget<TextField>(_key('address-floor-field')).controller?.text,
      '3',
    );
    expect(
      tester.widget<TextField>(_key('address-entrance-field')).controller?.text,
      'B',
    );
    expect(
      tester.widget<TextField>(_key('address-landmark-field')).controller?.text,
      'Mosquée',
    );
    await tester.enterText(_key('address-floor-field'), '');
    await tester.tap(find.byKey(const Key('address-save-button')));
    await tester.pumpAndSettle();
    expect(api.addresses.single.building, 'Bloc Z');
    expect(api.addresses.single.floor, isNull);
    expect(api.addresses.single.landmark, 'Mosquée');
  });

  testWidgets('wilaya chip does not move the confirmed pin', (tester) async {
    final api = FakeAddressClient(addresses: [_home]);
    await tester.pumpWidget(
      readyApp(customer: _customer(addresses: [_home]), addresses: api),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addressesTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-address-addr-home')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_key('address-latitude-field')).controller?.text,
      '36.75',
    );
    expect(
      tester.widget<TextField>(_key('address-longitude-field')).controller?.text,
      '3.05',
    );
    await tester.tap(find.byKey(const Key('address-wilaya-field')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_key('address-latitude-field')).controller?.text,
      '36.75',
    );
    expect(
      tester.widget<TextField>(_key('address-longitude-field')).controller?.text,
      '3.05',
    );
  });

  test('French and Arabic address detail labels stay distinct', () {
    AppStrings.bind('fr');
    expect(AppStrings.addressBuildingField, 'Bâtiment');
    expect(AppStrings.addressFloorField, 'Étage');
    expect(AppStrings.addressEntranceField, 'Entrée');
    expect(AppStrings.addressLandmarkField, 'Point de repère');
    AppStrings.bind('ar');
    expect(AppStrings.addressBuildingField, 'المبنى');
    expect(AppStrings.addressFloorField, 'الطابق');
    expect(AppStrings.addressEntranceField, 'المدخل');
    expect(AppStrings.addressLandmarkField, 'علامة مميّزة');
    AppStrings.bind('fr');
  });
}
