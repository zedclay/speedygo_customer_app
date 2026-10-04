import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_models.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

import '../../helpers/fakes.dart';

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

const _tokens = TokenPair(
  accessToken: 'access-1',
  refreshToken: 'refresh-1-token-value',
  expiresIn: 900,
  tokenType: 'Bearer',
);

CustomerMe _me(List<CustomerAddress> addresses) {
  String? defaultId;
  for (final address in addresses) {
    if (address.isDefault) {
      defaultId = address.id;
      break;
    }
  }
  return CustomerMe(
    customerProfileExists: true,
    profileComplete: true,
    addressReady: defaultId != null,
    profile: const CustomerProfile(id: 'p1', fullName: 'Revue Client'),
    defaultAddressId: defaultId,
    addresses: addresses,
  );
}

Future<ProviderContainer> _ready({
  required FakeAddressClient api,
  MemoryAddressSelectionStore? selection,
  FakeCustomerClient? customer,
}) async {
  final resolvedCustomer =
      customer ?? (FakeCustomerClient()..meResult = _me(api.addresses));
  final container = ProviderContainer(
    overrides: [
      sessionStoreProvider.overrideWithValue(
        MemorySessionStore()..value = _tokens,
      ),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(onboardingSeen: true, languageSeen: true),
      ),
      authApiProvider.overrideWithValue(FakeAuthClient()),
      customerApiProvider.overrideWithValue(resolvedCustomer),
      addressApiProvider.overrideWithValue(api),
      addressSelectionStoreProvider.overrideWithValue(
        selection ?? MemoryAddressSelectionStore(),
      ),
      locationClientProvider.overrideWithValue(FakeLocationClient()),
    ],
  );
  await container.read(sessionControllerProvider.notifier).restore();
  container.listen(addressBookProvider, (previous, next) {});
  container.listen(addressSelectionProvider, (previous, next) {});
  await container.read(addressBookProvider.notifier).refresh();
  return container;
}

CreateAddressRequest get _draft => const CreateAddressRequest(
  label: 'Revue test Hydra',
  addressText: '12 chemin test Revue',
  latitude: 36.7538,
  longitude: 3.0588,
);

void main() {
  test('create update default and delete follow the address book', () async {
    final api = FakeAddressClient();
    final container = await _ready(api: api);
    addTearDown(container.dispose);
    final book = container.read(addressBookProvider.notifier);

    expect(await book.create(_draft), isTrue);
    expect(api.createCount, 1);
    expect(
      container.read(addressBookProvider).addresses.single.isDefault,
      isTrue,
    );
    expect(
      container.read(sessionControllerProvider).customer?.addressReady,
      isTrue,
    );

    final id = container.read(addressBookProvider).addresses.single.id;
    expect(
      await book.update(
        addressId: id,
        request: const UpdateAddressRequest(label: 'Revue test Hydra 2'),
      ),
      isTrue,
    );
    expect(
      container.read(addressBookProvider).addresses.single.label,
      'Revue test Hydra 2',
    );

    expect(await book.create(_draft), isTrue);
    expect(
      container.read(addressBookProvider).addresses.last.isDefault,
      isFalse,
    );
    final second = container.read(addressBookProvider).addresses.last.id;
    expect(await book.setDefault(second), isTrue);
    expect(container.read(addressBookProvider).defaultAddress?.id, second);

    expect(await book.delete(second), isTrue);
    expect(container.read(addressBookProvider).defaultAddress, isNull);
    expect(
      container.read(sessionControllerProvider).customer?.addressReady,
      isFalse,
    );
  });

  test('foreign address ids surface CUSTOMER_ADDRESS_NOT_FOUND', () async {
    final api = FakeAddressClient(addresses: [_home]);
    final container = await _ready(api: api);
    addTearDown(container.dispose);
    final book = container.read(addressBookProvider.notifier);
    expect(
      await book.update(
        addressId: 'addr-other-account',
        request: const UpdateAddressRequest(label: 'Stolen'),
      ),
      isFalse,
    );
    expect(api.updateCount, 1);
    expect(
      container.read(addressBookProvider).actionError,
      AppStrings.addressNotFound,
    );
    expect(
      container.read(addressBookProvider).byId('addr-home')?.label,
      'Domicile',
    );
  });

  test('double tap does not start a second create', () async {
    final api = FakeAddressClient()..gateCreate = Completer<void>();
    final container = await _ready(api: api);
    addTearDown(container.dispose);
    final book = container.read(addressBookProvider.notifier);
    final first = book.create(_draft);
    final second = await book.create(_draft);
    expect(second, isFalse);
    expect(api.createCount, 1);
    api.gateCreate!.complete();
    expect(await first, isTrue);
    expect(api.createCount, 1);
  });

  test(
    'uncertain create reconciles with GET and does not POST again',
    () async {
      final api = FakeAddressClient(
        addresses: [
          CustomerAddress(
            id: 'addr-created-1',
            label: _draft.label,
            addressText: _draft.addressText,
            isDefault: true,
            latitude: _draft.latitude,
            longitude: _draft.longitude,
          ),
        ],
      )..createError = const AddressUncertainException();
      final container = await _ready(api: api);
      addTearDown(container.dispose);
      final book = container.read(addressBookProvider.notifier);
      expect(await book.create(_draft), isTrue);
      expect(api.createCount, 1);
      expect(api.listCount, greaterThan(1));
      expect(container.read(addressBookProvider).actionError, isNull);
    },
  );

  test('selecting an address does not call PUT default', () async {
    final api = FakeAddressClient(addresses: [_home, _work]);
    final selection = MemoryAddressSelectionStore();
    final container = await _ready(api: api, selection: selection);
    addTearDown(container.dispose);
    await container.read(addressSelectionProvider.notifier).select('addr-work');
    expect(api.defaultCount, 0);
    expect(selection.value?.addressId, 'addr-work');
    expect(selection.value?.profileId, 'p1');
    expect(
      homeAddressLabel(
        book: container.read(addressBookProvider),
        selection: container.read(addressSelectionProvider),
      ),
      'Bureau',
    );
    expect(
      container.read(addressBookProvider).defaultAddress?.label,
      'Domicile',
    );
  });

  test('deleting the selected address clears the Home selection', () async {
    final api = FakeAddressClient(addresses: [_home, _work]);
    final container = await _ready(api: api);
    addTearDown(container.dispose);
    await container.read(addressSelectionProvider.notifier).select('addr-work');
    expect(
      await container.read(addressBookProvider.notifier).delete('addr-work'),
      isTrue,
    );
    expect(container.read(addressSelectionProvider).addressId, isNull);
    expect(
      homeAddressLabel(
        book: container.read(addressBookProvider),
        selection: container.read(addressSelectionProvider),
      ),
      'Domicile',
    );
  });

  test('editing the selected address updates the Home label', () async {
    final api = FakeAddressClient(addresses: [_home, _work]);
    final container = await _ready(api: api);
    addTearDown(container.dispose);
    await container.read(addressSelectionProvider.notifier).select('addr-work');
    expect(
      await container
          .read(addressBookProvider.notifier)
          .update(
            addressId: 'addr-work',
            request: const UpdateAddressRequest(label: 'Bureau édité'),
          ),
      isTrue,
    );
    expect(api.defaultCount, 0);
    expect(
      container.read(addressBookProvider).defaultAddress?.label,
      'Domicile',
    );
    expect(
      homeAddressLabel(
        book: container.read(addressBookProvider),
        selection: container.read(addressSelectionProvider),
      ),
      'Bureau édité',
    );
  });

  test(
    'deleting the selected default address clears stale Home state',
    () async {
      final api = FakeAddressClient(addresses: [_home, _work]);
      final container = await _ready(api: api);
      addTearDown(container.dispose);
      await container
          .read(addressSelectionProvider.notifier)
          .select('addr-home');
      expect(
        await container.read(addressBookProvider.notifier).delete('addr-home'),
        isTrue,
      );
      expect(container.read(addressSelectionProvider).addressId, isNull);
      expect(container.read(addressBookProvider).defaultAddress, isNull);
      expect(
        homeAddressLabel(
          book: container.read(addressBookProvider),
          selection: container.read(addressSelectionProvider),
        ),
        AppStrings.deliverToUnset,
      );
      expect(
        container.read(addressBookProvider).byId('addr-work')?.label,
        'Bureau',
      );
    },
  );

  test(
    'logout and another profile cannot reuse the previous selection',
    () async {
      final api = FakeAddressClient(addresses: [_home, _work]);
      final selection = MemoryAddressSelectionStore()
        ..value = const AddressSelectionRecord(
          profileId: 'other-profile',
          addressId: 'addr-work',
        );
      final container = await _ready(api: api, selection: selection);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(selection.value, isNull);
      await container
          .read(addressSelectionProvider.notifier)
          .select('addr-home');
      expect(selection.value?.profileId, 'p1');
      await container.read(sessionControllerProvider.notifier).logout();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(addressSelectionProvider).addressId, isNull);
      expect(selection.value, isNull);
    },
  );
}
