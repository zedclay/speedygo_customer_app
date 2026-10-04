import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_controller.dart';
import 'package:speedygo_customer_app/features/checkout/domain/checkout_address.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';

const _tokens = TokenPair(
  accessToken: 'access-1',
  refreshToken: 'refresh-1-token-value',
  expiresIn: 900,
  tokenType: 'Bearer',
);

CustomerMe _me({
  List<CustomerAddress> addresses = const [checkoutHomeAddress],
  bool addressReady = false,
}) {
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
    addressReady: addressReady,
    profile: const CustomerProfile(id: 'p', fullName: 'Amel Benali'),
    defaultAddressId: defaultId,
    addresses: addresses,
  );
}

Future<ProviderContainer> _ready({
  required FakeCheckoutClient checkout,
  FakeCartClient? cart,
  FakeAddressClient? addresses,
  MemoryAddressSelectionStore? selection,
  bool addressReady = false,
}) async {
  final cartClient =
      cart ??
      (FakeCartClient()
        ..bootstrap = CartBootstrap(
          cartExists: true,
          cart: espressoCheckoutCart(),
        ));
  final addressClient =
      addresses ?? FakeAddressClient(addresses: const [checkoutHomeAddress]);
  final container = ProviderContainer(
    overrides: [
      sessionStoreProvider.overrideWithValue(
        MemorySessionStore()..value = _tokens,
      ),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(onboardingSeen: true, languageSeen: true),
      ),
      authApiProvider.overrideWithValue(FakeAuthClient()),
      customerApiProvider.overrideWithValue(
        FakeCustomerClient()
          ..meResult = _me(
            addresses: addressClient.addresses,
            addressReady: addressReady,
          ),
      ),
      cartApiProvider.overrideWithValue(cartClient),
      checkoutApiProvider.overrideWithValue(checkout),
      addressApiProvider.overrideWithValue(addressClient),
      addressSelectionStoreProvider.overrideWithValue(
        selection ?? MemoryAddressSelectionStore(),
      ),
      locationClientProvider.overrideWithValue(FakeLocationClient()),
    ],
  );
  await container.read(sessionControllerProvider.notifier).restore();
  container.listen(cartControllerProvider, (previous, next) {});
  container.listen(addressBookProvider, (previous, next) {});
  container.listen(addressSelectionProvider, (previous, next) {});
  await container.read(cartControllerProvider.notifier).refresh();
  await container.read(addressBookProvider.notifier).refresh();
  container.listen(checkoutControllerProvider, (previous, next) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  test('Home selection wins over server default without PUT default', () async {
    final checkout = FakeCheckoutClient(
      builder: (request) => espressoCheckoutPreview(
        addressId: request.addressId,
        label: request.addressId == checkoutWorkAddressId
            ? 'Bureau'
            : 'Domicile',
      ),
    );
    final addresses = FakeAddressClient(
      addresses: const [checkoutHomeAddress, checkoutWorkAddress],
    );
    final selection = MemoryAddressSelectionStore()
      ..value = const AddressSelectionRecord(
        profileId: 'p',
        addressId: checkoutWorkAddressId,
      );
    final container = await _ready(
      checkout: checkout,
      addresses: addresses,
      selection: selection,
      addressReady: false,
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(checkout.requests, isNotEmpty);
    expect(checkout.requests.last.addressId, checkoutWorkAddressId);
    expect(addresses.defaultCount, 0);
    expect(
      container.read(checkoutControllerProvider).preview?.address.id,
      checkoutWorkAddressId,
    );
  });

  test('server default is used when Home selection is missing', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final container = await _ready(checkout: checkout, addressReady: false);
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(checkout.requests.single.addressId, checkoutHomeAddressId);
    expect(checkout.requests.single.promoCode, isNull);
    expect(
      container.read(checkoutControllerProvider).preview?.customerTotalMinor,
      '1900',
    );
  });

  test(
    'missing selection and default requires an address and skips preview',
    () {
      const book = AddressUiState(
        addresses: [
          CustomerAddress(
            id: 'not-a-uuid',
            label: 'X',
            addressText: 'Y',
            isDefault: true,
          ),
        ],
      );
      expect(
        resolveCheckoutAddressId(
          book: book,
          selection: const AddressSelectionState(),
        ),
        isNull,
      );
    },
  );

  test('apply promo only after preview confirms it', () async {
    final checkout = FakeCheckoutClient(
      builder: (request) {
        if (request.promoCode == 'SAVE10') {
          return espressoCheckoutPreview(
            discountMinor: '100',
            promoCode: 'SAVE10',
            customerTotalMinor: '1800',
          );
        }
        if (request.promoCode != null) {
          throw const ApiException(
            'Ce code promo a expiré.',
            code: 'PROMOTION_EXPIRED',
            statusCode: 409,
          );
        }
        return espressoCheckoutPreview();
      },
    );
    final container = await _ready(checkout: checkout);
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(checkoutControllerProvider).preview?.promoApplied,
      isFalse,
    );

    await container
        .read(checkoutControllerProvider.notifier)
        .applyPromo('SAVE10');
    expect(checkout.requests.last.promoCode, 'SAVE10');
    expect(
      container.read(checkoutControllerProvider).preview?.promoCode,
      'SAVE10',
    );
    expect(
      container.read(checkoutControllerProvider).preview?.customerTotalMinor,
      '1800',
    );

    await container.read(checkoutControllerProvider.notifier).applyPromo('OLD');
    expect(container.read(checkoutControllerProvider).preview, isNull);
    expect(
      container.read(checkoutControllerProvider).error,
      AppStrings.errorForCode('PROMOTION_EXPIRED'),
    );
    expect(
      container.read(checkoutControllerProvider).requestedPromoCode,
      isNull,
    );
  });

  test('stale preview cannot overwrite a newer selection', () async {
    final holdFirst = Completer<void>();
    final checkout = FakeCheckoutClient();
    checkout.holdFirst = holdFirst;
    checkout.firstHeldResult = espressoCheckoutPreview(
      customerTotalMinor: '1900',
    );
    checkout.result = espressoCheckoutPreview(
      addressId: checkoutWorkAddressId,
      label: 'Bureau',
      addressText: 'Rue du Travail',
      customerTotalMinor: '2100',
    );
    final addresses = FakeAddressClient(
      addresses: const [checkoutHomeAddress, checkoutWorkAddress],
    );
    final container = await _ready(checkout: checkout, addresses: addresses);
    addTearDown(container.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(checkout.previewCount, 1);

    await container
        .read(addressSelectionProvider.notifier)
        .select(checkoutWorkAddressId);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(checkout.previewCount, greaterThanOrEqualTo(2));
    expect(
      container.read(checkoutControllerProvider).preview?.customerTotalMinor,
      '2100',
    );

    holdFirst.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(checkoutControllerProvider).preview?.address.id,
      checkoutWorkAddressId,
    );
    expect(
      container.read(checkoutControllerProvider).preview?.customerTotalMinor,
      '2100',
    );
  });

  test('failed refresh drops stale totals and keeps the cart', () async {
    final cart = FakeCartClient()
      ..bootstrap = CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(),
      );
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final container = await _ready(checkout: checkout, cart: cart);
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(checkoutControllerProvider).preview, isNotNull);

    checkout.error = const ApiException(
      'Certains articles du panier ne sont plus valides.',
      code: 'CHECKOUT_CART_NOT_READY',
      statusCode: 409,
    );
    await container.read(checkoutControllerProvider.notifier).refresh();
    expect(container.read(checkoutControllerProvider).preview, isNull);
    expect(
      container.read(checkoutControllerProvider).errorCode,
      'CHECKOUT_CART_NOT_READY',
    );
    expect(container.read(cartControllerProvider).cartExists, isTrue);
    expect(cart.clearCount, 0);
  });

  test('implemented checkout errors keep the cart and drop totals', () async {
    const codes = [
      'CHECKOUT_CART_NOT_READY',
      'CHECKOUT_ADDRESS_NOT_FOUND',
      'CHECKOUT_ADDRESS_OUTSIDE_ZONE',
      'CHECKOUT_DELIVERY_ZONE_AMBIGUOUS',
      'CHECKOUT_PRICING_RULE_NOT_FOUND',
      'CHECKOUT_PRICING_CONFIGURATION_INVALID',
      'CHECKOUT_MERCHANT_NOT_OPERATIONAL',
      'CHECKOUT_BRANCH_NOT_OPERATIONAL',
      'CHECKOUT_BRANCH_CLOSED',
      'CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED',
      'PROMOTION_CODE_INVALID',
    ];
    for (final code in codes) {
      final cart = FakeCartClient()
        ..bootstrap = CartBootstrap(
          cartExists: true,
          cart: espressoCheckoutCart(),
        );
      final checkout = FakeCheckoutClient(
        error: ApiException(
          AppStrings.errorForCode(code),
          code: code,
          statusCode: 409,
        ),
      );
      final container = await _ready(checkout: checkout, cart: cart);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        container.read(checkoutControllerProvider).preview,
        isNull,
        reason: code,
      );
      expect(
        container.read(checkoutControllerProvider).errorCode,
        code,
        reason: code,
      );
      expect(
        container.read(checkoutControllerProvider).error,
        AppStrings.errorForCode(code),
        reason: code,
      );
      expect(
        container.read(cartControllerProvider).cartExists,
        isTrue,
        reason: code,
      );
    }
  });

  test('empty cart and missing address skip the preview call', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final emptyCart = FakeCartClient();
    final container = await _ready(
      checkout: checkout,
      cart: emptyCart,
      addresses: FakeAddressClient(),
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(checkout.previewCount, 0);
    expect(
      container.read(checkoutControllerProvider).errorCode,
      'CHECKOUT_CART_REQUIRED',
    );
  });
}
