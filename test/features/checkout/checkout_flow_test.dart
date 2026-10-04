import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/checkout/presentation/checkout_review_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_confirmation_screen.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';
import '../customer_navigation_test.dart';

FakeCustomerClient _customer(List<CustomerAddress> addresses) {
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
      addressReady: false,
      profile: const CustomerProfile(id: 'p', fullName: 'Amel Benali'),
      defaultAddressId: defaultId,
      addresses: addresses,
    );
}

FakeCatalogClient _catalog() {
  return FakeCatalogClient(
    storefronts: CatalogPage(
      items: [cafeStorefront()],
      limit: 50,
      offset: 0,
      total: 1,
    ),
    storefrontDetail: cafeStorefrontDetail(),
  );
}

Widget _app({
  required FakeCartClient cart,
  required FakeCheckoutClient checkout,
  FakeOrdersClient? orders,
  FakeAddressClient? addresses,
  MemoryAddressSelectionStore? selection,
  List<CustomerAddress> book = const [checkoutHomeAddress],
}) {
  return readyApp(
    catalog: _catalog(),
    customer: _customer(book),
    cart: cart,
    checkout: checkout,
    orders: orders,
    addresses: addresses ?? FakeAddressClient(addresses: book),
    addressSelection:
        selection ??
        (MemoryAddressSelectionStore()
          ..value = book.isEmpty
              ? null
              : AddressSelectionRecord(
                  profileId: 'p',
                  addressId: book.first.id,
                )),
  );
}

Future<void> _scrollReview(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find
        .descendant(
          of: find.byType(CheckoutReviewScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openReview(WidgetTester tester) async {
  final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
  router.push(AppRoutes.cart);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('checkout-review-cta')), findsOneWidget);
  await tester.tap(find.byKey(const Key('checkout-review-cta')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cart CTA opens review with server totals', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cart = FakeCartClient()
      ..bootstrap = CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(),
      );
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    await tester.pumpWidget(_app(cart: cart, checkout: checkout));
    await tester.pumpAndSettle();
    await _openReview(tester);

    expect(find.text(AppStrings.checkoutReviewTitle), findsOneWidget);
    expect(checkout.previewCount, greaterThan(0));
    expect(find.text('Espresso'), findsWidgets);
    await _scrollReview(tester, find.byKey(const Key('checkout-totals')));
    expect(find.byKey(const Key('checkout-totals')), findsOneWidget);
    expect(find.byKey(const Key('checkout-delivery')), findsOneWidget);
    expect(find.text(MoneyFormat.dzd('1400')), findsWidgets);
    expect(find.text(MoneyFormat.dzd('500')), findsOneWidget);
    expect(find.byKey(const Key('checkout-total')), findsNothing);
    expect(find.byKey(const Key('checkout-sticky-total')), findsOneWidget);
    expect(find.text(MoneyFormat.dzd('1900')), findsOneWidget);
    expect(find.text(AppStrings.checkoutPayable), findsOneWidget);
    expect(find.text(AppStrings.checkoutDiscount), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('checkout-place-order')))
          .onPressed,
      isNotNull,
    );
    expect(find.text(AppStrings.checkoutPaymentCod), findsOneWidget);
    expect(checkout.requests.single.toJson(), {
      'addressId': checkoutHomeAddressId,
    });
  });

  testWidgets('address picker selection is sent and does not write default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cart = FakeCartClient()
      ..bootstrap = CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(),
      );
    final addresses = FakeAddressClient(
      addresses: const [checkoutHomeAddress, checkoutWorkAddress],
    );
    final checkout = FakeCheckoutClient(
      builder: (request) => espressoCheckoutPreview(
        addressId: request.addressId,
        label: request.addressId == checkoutWorkAddressId
            ? 'Bureau'
            : 'Domicile',
        addressText: request.addressId == checkoutWorkAddressId
            ? 'Rue du Travail'
            : 'Cité 120 logements',
      ),
    );
    await tester.pumpWidget(
      _app(
        cart: cart,
        checkout: checkout,
        addresses: addresses,
        book: const [checkoutHomeAddress, checkoutWorkAddress],
      ),
    );
    await tester.pumpAndSettle();
    await _openReview(tester);
    expect(find.text('Domicile'), findsWidgets);
    expect(find.textContaining('Alger Centre'), findsNothing);
    expect(find.textContaining(AppStrings.checkoutDeliveryZone), findsNothing);

    await tester.tap(find.byKey(const Key('checkout-address-card')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('picker-address-$checkoutWorkAddressId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bureau'), findsWidgets);
    expect(checkout.requests.last.addressId, checkoutWorkAddressId);
    expect(addresses.defaultCount, 0);
  });

  testWidgets('promo apply/remove and method screen stay preview-only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cart = FakeCartClient()
      ..bootstrap = CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(),
      );
    final checkout = FakeCheckoutClient(
      builder: (request) {
        if (request.promoCode == 'SAVE10') {
          return espressoCheckoutPreview(
            discountMinor: '100',
            promoCode: 'SAVE10',
            customerTotalMinor: '1800',
          );
        }
        return espressoCheckoutPreview();
      },
    );
    await tester.pumpWidget(_app(cart: cart, checkout: checkout));
    await tester.pumpAndSettle();
    await _openReview(tester);

    expect(find.byKey(const Key('checkout-promo-applied')), findsNothing);
    await _scrollReview(tester, find.byKey(const Key('checkout-promo-field')));
    await tester.enterText(
      find.byKey(const Key('checkout-promo-field')),
      'SAVE10',
    );
    await _scrollReview(tester, find.byKey(const Key('checkout-apply-promo')));
    await tester.tap(find.byKey(const Key('checkout-apply-promo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkout-promo-applied')), findsOneWidget);
    expect(find.textContaining(MoneyFormat.dzd('100')), findsOneWidget);
    expect(find.byKey(const Key('checkout-total')), findsNothing);
    expect(find.byKey(const Key('checkout-sticky-total')), findsOneWidget);
    expect(find.text(MoneyFormat.dzd('1800')), findsOneWidget);

    await tester.tap(find.byKey(const Key('checkout-remove-promo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkout-promo-applied')), findsNothing);
    expect(checkout.requests.last.promoCode, isNull);

    await _scrollReview(tester, find.byKey(const Key('checkout-payment-card')));
    await tester.tap(find.byKey(const Key('checkout-payment-card')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.checkoutPaymentCod), findsOneWidget);
    expect(find.text(AppStrings.checkoutPaymentElectronic), findsOneWidget);
    expect(find.text('CIB'), findsNothing);
    await tester.tap(find.byKey(const Key('checkout-method-back')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.checkoutReviewTitle), findsOneWidget);
    for (final request in checkout.requests) {
      expect(request.toJson().containsKey('paymentMethod'), isFalse);
    }
  });

  testWidgets('outside-zone error keeps the cart and offers address recovery', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cart = FakeCartClient()
      ..bootstrap = CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(),
      );
    final checkout = FakeCheckoutClient(
      error: ApiException(
        AppStrings.errorForCode('CHECKOUT_ADDRESS_OUTSIDE_ZONE'),
        code: 'CHECKOUT_ADDRESS_OUTSIDE_ZONE',
        statusCode: 409,
      ),
    );
    await tester.pumpWidget(_app(cart: cart, checkout: checkout));
    await tester.pumpAndSettle();
    await _openReview(tester);

    expect(checkout.previewCount, greaterThan(0));
    expect(find.text('Domicile'), findsWidgets);
    expect(
      find.text(AppStrings.errorForCode('CHECKOUT_ADDRESS_OUTSIDE_ZONE')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('checkout-totals')), findsNothing);
    expect(cart.bootstrap?.cartExists, isTrue);
    await tester.tap(find.byKey(const Key('checkout-recovery')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);
  });

  testWidgets('need address when neither selection nor default exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cart = FakeCartClient()
      ..bootstrap = CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(),
      );
    final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
    await tester.pumpWidget(
      _app(
        cart: cart,
        checkout: checkout,
        book: const [],
        addresses: FakeAddressClient(),
      ),
    );
    await tester.pumpAndSettle();
    await _openReview(tester);
    expect(find.text(AppStrings.checkoutNeedAddress), findsWidgets);
    expect(checkout.previewCount, 0);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('checkout-place-order')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'Commander after shell+cart+review opens confirmation without duplicate page keys',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final created = sampleOrderDetail();
      final cart = FakeCartClient()
        ..bootstrap = CartBootstrap(
          cartExists: true,
          cart: espressoCheckoutCart(),
        );
      final checkout = FakeCheckoutClient(result: espressoCheckoutPreview());
      final orders = FakeOrdersClient(createResult: created)
        ..details[created.id] = created;

      await tester.pumpWidget(
        _app(cart: cart, checkout: checkout, orders: orders),
      );
      await tester.pumpAndSettle();
      await _openReview(tester);

      await tester.tap(find.byKey(const Key('checkout-place-order')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(orders.createCount, 1);
      expect(find.byType(OrderConfirmationScreen), findsOneWidget);
      expect(find.text(AppStrings.orderConfirmationSent), findsOneWidget);
    },
  );
}
