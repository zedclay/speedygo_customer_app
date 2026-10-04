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
import 'package:speedygo_customer_app/features/checkout/application/order_submission_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

const _tokens = TokenPair(
  accessToken: 'access-1',
  refreshToken: 'refresh-1-token-value',
  expiresIn: 900,
  tokenType: 'Bearer',
);

Future<ProviderContainer> _ready({
  required FakeCheckoutClient checkout,
  required FakeOrdersClient orders,
  FakeCartClient? cart,
}) async {
  final cartClient =
      cart ??
      (FakeCartClient()
        ..bootstrap = CartBootstrap(
          cartExists: true,
          cart: espressoCheckoutCart(),
        ));
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
          ..meResult = const CustomerMe(
            customerProfileExists: true,
            profileComplete: true,
            addressReady: false,
            profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
            defaultAddressId: checkoutHomeAddressId,
            addresses: [checkoutHomeAddress],
          ),
      ),
      cartApiProvider.overrideWithValue(cartClient),
      checkoutApiProvider.overrideWithValue(checkout),
      ordersApiProvider.overrideWithValue(orders),
      addressApiProvider.overrideWithValue(
        FakeAddressClient(addresses: const [checkoutHomeAddress]),
      ),
      addressSelectionStoreProvider.overrideWithValue(
        MemoryAddressSelectionStore(),
      ),
      locationClientProvider.overrideWithValue(FakeLocationClient()),
    ],
  );
  await container.read(sessionControllerProvider.notifier).restore();
  container.listen(cartControllerProvider, (_, _) {});
  container.listen(addressBookProvider, (_, _) {});
  container.listen(checkoutControllerProvider, (_, _) {});
  container.listen(orderSubmissionControllerProvider, (_, _) {});
  await container.read(cartControllerProvider.notifier).refresh();
  await container.read(addressBookProvider.notifier).refresh();
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  test('submit sends exact COD payload without promo', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(createResult: sampleOrderDetail());
    final container = await _ready(checkout: checkout, orders: orders);

    final order = await container
        .read(orderSubmissionControllerProvider.notifier)
        .submit();

    expect(order, isNotNull);
    expect(orders.createCount, 1);
    final body = orders.lastCreateRequest!;
    expect(body.paymentMethod, 'COD');
    expect(body.expectedMerchandiseSubtotalMinor, 1400);
    expect(body.expectedDeliveryFeeMinor, 500);
    expect(body.expectedCustomerTotalMinor, 1900);
    expect(body.promoCode, isNull);
    expect(body.addressId, checkoutHomeAddressId);
    container.dispose();
  });

  test('double submit is ignored while in flight', () async {
    final gate = Completer<void>();
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(
      createResult: sampleOrderDetail(),
      createDelay: const Duration(milliseconds: 200),
    )..gateCreate = gate;
    final container = await _ready(checkout: checkout, orders: orders);
    final notifier = container.read(orderSubmissionControllerProvider.notifier);
    final first = notifier.submit();
    final second = notifier.submit();
    gate.complete();
    await Future.wait([first, second]);
    expect(orders.createCount, 1);
    container.dispose();
  });

  test('changed preview before submit requires reconfirmation', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(createResult: sampleOrderDetail());
    final container = await _ready(checkout: checkout, orders: orders);
    checkout.result = espressoCheckoutPreview(customerTotalMinor: '2000');

    final order = await container
        .read(orderSubmissionControllerProvider.notifier)
        .submit();

    expect(order, isNull);
    expect(orders.createCount, 0);
    expect(
      container.read(orderSubmissionControllerProvider).phase,
      OrderSubmissionPhase.reconfirmationRequired,
    );
    container.dispose();
  });

  test('ORDER_RECONFIRMATION_REQUIRED updates preview totals', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(
      createError: OrderReconfirmationException(
        message: AppStrings.orderReconfirmationRequired,
        changes: const ['CUSTOMER_TOTAL'],
        current: const OrderReconfirmationCurrent(
          merchandiseSubtotalMinor: '1400',
          deliveryFeeMinor: '500',
          customerTotalMinor: '2000',
        ),
      ),
    );
    final container = await _ready(checkout: checkout, orders: orders);

    final order = await container
        .read(orderSubmissionControllerProvider.notifier)
        .submit();

    expect(order, isNull);
    expect(
      container.read(checkoutControllerProvider).preview?.customerTotalMinor,
      '2000',
    );
    container.dispose();
  });

  test('timeout sets pending verification without duplicate POST', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(
      createError: const NetworkException(
        AppStrings.offline,
        code: 'NETWORK_TIMEOUT',
      ),
    );
    final container = await _ready(checkout: checkout, orders: orders);

    final order = await container
        .read(orderSubmissionControllerProvider.notifier)
        .submit();

    expect(order, isNull);
    expect(orders.createCount, 1);
    expect(
      container.read(orderSubmissionControllerProvider).phase,
      OrderSubmissionPhase.pendingVerification,
    );
    await container.read(orderSubmissionControllerProvider.notifier).submit();
    expect(orders.createCount, 1);
    container.dispose();
  });
}
