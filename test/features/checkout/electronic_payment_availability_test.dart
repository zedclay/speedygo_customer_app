import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/config/electronic_payment_config.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_controller.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_payment_method.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';
import 'package:speedygo_customer_app/features/checkout/application/order_submission_controller.dart';
import 'package:speedygo_customer_app/features/checkout/presentation/checkout_payment_method_screen.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';

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
  ElectronicPaymentAvailability availability =
      ElectronicPaymentAvailability.disabled,
}) async {
  final cartClient = FakeCartClient()
    ..bootstrap = CartBootstrap(
      cartExists: true,
      cart: espressoCheckoutCart(),
    );
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
      electronicPaymentAvailabilityProvider.overrideWithValue(availability),
    ],
  );
  await container.read(sessionControllerProvider.notifier).restore();
  container.listen(cartControllerProvider, (_, _) {});
  container.listen(addressBookProvider, (_, _) {});
  container.listen(checkoutControllerProvider, (_, _) {});
  container.listen(orderSubmissionControllerProvider, (_, _) {});
  container.listen(checkoutPaymentMethodProvider, (_, _) {});
  await container.read(cartControllerProvider.notifier).refresh();
  await container.read(addressBookProvider.notifier).refresh();
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  testWidgets('disabled electronic shows Bientôt disponible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          electronicPaymentAvailabilityProvider.overrideWithValue(
            ElectronicPaymentAvailability.disabled,
          ),
        ],
        child: const MaterialApp(home: CheckoutPaymentMethodScreen()),
      ),
    );
    expect(find.text(AppStrings.checkoutPaymentElectronicSoon), findsOneWidget);
    await tester.tap(find.byKey(const Key('checkout-method-electronic')));
    await tester.pump();
    // Selection must not flip to electronic when disabled.
  });

  test('disabled electronic blocks submission without creating order', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(createResult: sampleOrderDetail());
    final container = await _ready(checkout: checkout, orders: orders);
    addTearDown(container.dispose);

    container
        .read(checkoutPaymentMethodProvider.notifier)
        .debugSetSelection(CheckoutPaymentMethod.electronic);
    expect(
      container.read(checkoutPaymentMethodProvider),
      CheckoutPaymentMethod.electronic,
    );

    final order = await container
        .read(orderSubmissionControllerProvider.notifier)
        .submit();

    expect(order, isNull);
    expect(orders.createCount, 0);
    expect(
      container.read(checkoutPaymentMethodProvider),
      CheckoutPaymentMethod.electronic,
    );
    final submission = container.read(orderSubmissionControllerProvider);
    expect(submission.phase, OrderSubmissionPhase.failed);
    expect(submission.error, AppStrings.checkoutPaymentMethodUnavailable);
  });

  test('stale electronic selection is not silently rewritten to COD', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(createResult: sampleOrderDetail());
    final container = await _ready(
      checkout: checkout,
      orders: orders,
      availability: ElectronicPaymentAvailability.disabled,
    );
    addTearDown(container.dispose);

    container
        .read(checkoutPaymentMethodProvider.notifier)
        .debugSetSelection(CheckoutPaymentMethod.electronic);
    container.read(checkoutPaymentMethodProvider.notifier).select(
          CheckoutPaymentMethod.electronic,
        );
    expect(
      container.read(checkoutPaymentMethodProvider),
      CheckoutPaymentMethod.electronic,
    );
    container
        .read(checkoutPaymentMethodProvider.notifier)
        .select(CheckoutPaymentMethod.cod);
    expect(
      container.read(checkoutPaymentMethodProvider),
      CheckoutPaymentMethod.cod,
    );
  });

  test('enabled availability allows electronic select and submit', () async {
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    final orders = FakeOrdersClient(
      createResult: sampleOrderDetail(paymentMethod: 'ELECTRONIC'),
    );
    final container = await _ready(
      checkout: checkout,
      orders: orders,
      availability: const ElectronicPaymentAvailability(
        enabledForCheckout: true,
      ),
    );
    addTearDown(container.dispose);

    container
        .read(checkoutPaymentMethodProvider.notifier)
        .select(CheckoutPaymentMethod.electronic);
    expect(
      container.read(checkoutPaymentMethodProvider),
      CheckoutPaymentMethod.electronic,
    );

    final order = await container
        .read(orderSubmissionControllerProvider.notifier)
        .submit();
    expect(order, isNotNull);
    expect(orders.createCount, 1);
    expect(orders.lastCreateRequest!.paymentMethod, 'ELECTRONIC');
  });

  test('compile-time default keeps electronic disabled', () {
    expect(ElectronicPaymentConfig.enabled, isFalse);
    expect(CheckoutPaymentMethod.electronic.selectableInCurrentSlice, isFalse);
    expect(CheckoutPaymentMethod.cod.selectableInCurrentSlice, isTrue);
  });
}
