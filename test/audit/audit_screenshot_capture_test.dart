import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

import '../features/customer_navigation_test.dart';
import '../helpers/catalog_fixtures.dart';
import '../helpers/fakes.dart';
import '../helpers/notification_support_fakes.dart';
import '../helpers/order_fixtures.dart';

final _capture = Platform.environment['AUDIT_CAPTURE'] == '1';

const _restaurantsVerticalId = '11111111-1111-4111-8111-111111111111';
const _cancelledOrderId = '99999999-9999-4999-8999-999999999999';
const _supportTicketId = '55555555-5555-4555-8555-555555555555';

Widget populatedReadyApp({FakeRatingsClient? ratings}) {
  final cafe = cafeStorefront();
  final product = espresso();
  final auth = FakeAuthClient()
    ..meResult = const AuthMe(
      accountId: 'acc-1',
      phone: '+213550123456',
      status: 'ACTIVE',
      hasCustomerProfile: true,
    )
    ..sessions = const [
      AuthSession(
        id: '11111111-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
        deviceId: 'dev-1',
        platform: 'ios',
        deviceName: 'iPhone SE',
        createdAt: '2026-09-01T00:00:00.000Z',
        expiresAt: '2026-10-01T00:00:00.000Z',
        revoked: false,
        currentSession: true,
      ),
      AuthSession(
        id: '11111111-aaaa-4aaa-8aaa-aaaaaaaaaaa2',
        deviceId: 'dev-2',
        platform: 'ios',
        deviceName: 'iPhone 17 Pro',
        createdAt: '2026-09-05T00:00:00.000Z',
        expiresAt: '2026-10-05T00:00:00.000Z',
        revoked: false,
        currentSession: false,
      ),
    ];
  final customer = FakeCustomerClient()
    ..meResult = const CustomerMe(
      customerProfileExists: true,
      profileComplete: true,
      addressReady: true,
      profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
      addresses: [checkoutHomeAddress, checkoutWorkAddress],
      defaultAddressId: checkoutHomeAddressId,
    );
  final support = FakeSupportClient()
    ..tickets[_supportTicketId] = const SupportTicketDetail(
      id: _supportTicketId,
      publicReference: 'sgt_audit1',
      status: 'OPEN',
      priority: 'NORMAL',
      orderId: activeOrderId,
      createdAt: '2026-09-10T00:00:00.000Z',
      updatedAt: '2026-09-10T00:00:00.000Z',
      createdByAccountId: 'acc-1',
      order: null,
      messages: [
        SupportMessage(
          id: 'msg-1',
          ticketId: _supportTicketId,
          authorAccountId: 'acc-1',
          body: 'Ma commande n’a pas avancé.',
          createdAt: '2026-09-10T00:00:00.000Z',
          displayName: null,
        ),
      ],
    )
    ..page = const SupportTicketPage(
      items: [
        SupportTicketSummary(
          id: _supportTicketId,
          publicReference: 'sgt_audit1',
          status: 'OPEN',
          priority: 'NORMAL',
          orderId: activeOrderId,
          createdAt: '2026-09-10T00:00:00.000Z',
          updatedAt: '2026-09-10T00:00:00.000Z',
        ),
      ],
      total: 1,
      limit: 50,
      offset: 0,
    );
  final cancelled = sampleOrderDetail(
    id: _cancelledOrderId,
    publicReference: 'sgo_cancelledaudit1',
    status: 'CANCELLED',
    fulfillmentStatus: 'CANCELLED',
  );
  final orders = FakeOrdersClient(
    orders: orderPage([
      sampleOrder(),
      sampleOrder(
        id: _cancelledOrderId,
        publicReference: 'sgo_cancelledaudit1',
        status: 'CANCELLED',
        fulfillmentStatus: 'CANCELLED',
      ),
    ]),
  )..details.addAll({
      activeOrderId: sampleOrderDetail(),
      _cancelledOrderId: cancelled,
    });
  return readyApp(
    auth: auth,
    customer: customer,
    catalog: FakeCatalogClient(
      verticals: const [
        CommerceVertical(
          id: _restaurantsVerticalId,
          slug: 'restaurants',
          name: 'Restaurants',
          iconKey: 'restaurant',
          sortOrder: 0,
        ),
        CommerceVertical(
          id: '22222222-2222-4222-8222-222222222222',
          slug: 'bakeries',
          name: 'Boulangeries',
          iconKey: 'bakery_dining',
          sortOrder: 1,
        ),
      ],
      storefronts: CatalogPage(
        items: [cafe],
        limit: 50,
        offset: 0,
        total: 1,
      ),
      storefrontDetail: cafeStorefrontDetail(),
      categories: const [
        CatalogCategory(
          categoryId: drinksCategoryId,
          name: 'Boissons',
          sortOrder: 0,
        ),
      ],
      products: CatalogPage(
        items: [product],
        limit: 50,
        offset: 0,
        total: 1,
      ),
      productDetail: espressoDetail(),
      searchHits: CatalogPage(
        items: [
          CatalogSearchHit.storefront(cafe),
          CatalogSearchHit.product(product: product, storefront: cafe),
        ],
        limit: 50,
        offset: 0,
        total: 2,
      ),
    ),
    promotions: FakePromotionsClient(
      items: const [
        DiscoverablePromotion(
          id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa9',
          code: 'DEMO150',
          discountKind: PromotionDiscountKind.fixedMinor,
          value: 15000,
          startsAt: '2020-01-01T00:00:00.000Z',
          endsAt: '2099-01-01T00:00:00.000Z',
          customerLabel: 'Offre Spéciale',
        ),
      ],
    ),
    cart: FakeCartClient()
      ..products = {espressoProductId: espressoCartOffer()}
      ..bootstrap = CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(),
      ),
    checkout: FakeCheckoutClient(result: espressoCheckoutPreview()),
    addresses: FakeAddressClient(
      addresses: const [checkoutHomeAddress, checkoutWorkAddress],
    ),
    ratings:
        ratings ??
        FakeRatingsClient(
          summaries: {
            merchantId: const RatingSummary(
              targetType: 'MERCHANT',
              targetId: merchantId,
              count: 42,
              average: 4.7,
            ),
          },
        ),
    orders: orders,
    notifications: FakeNotificationsClient(
      seed: const [
        NotificationItem(
          id: 'n-order',
          type: 'ORDER_ACCEPTED',
          sourceId: activeOrderId,
          title: 'Commande acceptée',
          body: 'Le commerçant a accepté votre commande.',
          read: false,
          createdAt: '2026-09-10T00:00:00.000Z',
        ),
      ],
    ),
    support: support,
  );
}

Future<void> _size(WidgetTester tester, Size logical, {double dpr = 2}) async {
  tester.view.physicalSize = logical * dpr;
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
}

Future<void> _frames(WidgetTester tester, {int count = 24}) async {
  await tester.pump();
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _frames(tester, count: 8);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../audit/visuals/widget/mocked/$name.png'),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets);
  await tester.tap(finder.first);
  await _frames(tester);
}

Future<void> _back(WidgetTester tester) async {
  final back = find.byTooltip(AppStrings.back);
  expect(back, findsWidgets);
  await tester.tap(back.first);
  await _frames(tester);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  if (tester.any(target)) {
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 80));
    return;
  }
  for (var i = 0; i < 12; i++) {
    final scrollable = find.byType(Scrollable);
    if (!tester.any(scrollable)) {
      return;
    }
    await tester.drag(scrollable.first, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 80));
    if (tester.any(target)) {
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 80));
      return;
    }
  }
}

Future<void> _pumpPopulated(WidgetTester tester) async {
  await tester.pumpWidget(populatedReadyApp());
}

Future<void> _captureCatalogJourney(WidgetTester tester, String suffix) async {
  await _pumpPopulated(tester);
  await tester.pump();
  if (tester.any(find.byType(CircularProgressIndicator))) {
    await _shot(tester, 'home-loading-$suffix');
  }
  await _frames(tester);
  await _shot(tester, 'home-ready-$suffix');

  await _tap(tester, find.text(AppStrings.seeAll));
  await _shot(tester, 'categories-ready-$suffix');

  await _tap(tester, find.text('Restaurants'));
  await _frames(tester);
  await _shot(tester, 'category-results-ready-$suffix');

  await _tap(tester, find.text('Café Central'));
  await _frames(tester);
  await _shot(tester, 'storefront-ready-$suffix');

  await _tap(tester, find.text('Espresso'));
  await _frames(tester);
  await _shot(tester, 'product-ready-$suffix');

  await _tap(tester, find.byKey(const Key('customize-product-button')));
  await _frames(tester);
  await _shot(tester, 'product-options-ready-$suffix');
}

Future<void> _captureSearchJourney(WidgetTester tester, String suffix) async {
  await _pumpPopulated(tester);
  await _frames(tester);
  await _tap(tester, find.byIcon(Icons.search_outlined));
  await _shot(tester, 'search-idle-$suffix');
  await tester.enterText(find.byType(TextField), 'es');
  await tester.pump();
  await _shot(tester, 'search-loading-$suffix');
  await tester.pump(const Duration(milliseconds: 400));
  await _frames(tester);
  await _shot(tester, 'search-results-ready-$suffix');
}

Future<void> _captureCheckoutJourney(WidgetTester tester, String suffix) async {
  await _pumpPopulated(tester);
  await _frames(tester);
  GoRouter.of(tester.element(find.byType(HomeScreen))).push(AppRoutes.cart);
  await tester.pump();
  if (tester.any(find.byType(CircularProgressIndicator))) {
    await _shot(tester, 'cart-loading-$suffix');
  }
  await _frames(tester);
  await _shot(tester, 'cart-ready-$suffix');

  await _tap(tester, find.byKey(const Key('checkout-review-cta')));
  await tester.pump();
  if (tester.any(find.byType(CircularProgressIndicator))) {
    await _shot(tester, 'checkout-loading-$suffix');
  }
  await _frames(tester);
  await _shot(tester, 'checkout-review-ready-$suffix');

  await _tap(tester, find.byKey(const Key('checkout-address-card')));
  await _frames(tester);
  await _shot(tester, 'checkout-address-ready-$suffix');
}

Future<void> _captureOrdersJourney(WidgetTester tester, String suffix) async {
  await _pumpPopulated(tester);
  await _frames(tester);
  await tester.tap(find.byIcon(Icons.receipt_long_outlined));
  await tester.pump();
  if (tester.any(find.byType(CircularProgressIndicator))) {
    await _shot(tester, 'orders-loading-$suffix');
  }
  await _frames(tester);
  await _shot(tester, 'orders-in-progress-ready-$suffix');

  await _tap(tester, find.byKey(const Key('order-list-tile-$activeOrderId')));
  await _frames(tester);
  await _shot(tester, 'order-detail-ready-$suffix');
  await _back(tester);

  await _tap(tester, find.text(AppStrings.ordersTabCancelled));
  await _frames(tester);
  await _shot(tester, 'orders-cancelled-ready-$suffix');
}

Future<void> _captureAccountJourney(WidgetTester tester, String suffix) async {
  await _pumpPopulated(tester);
  await _frames(tester);
  await _tap(tester, find.byIcon(Icons.person_outline));
  await _shot(tester, 'account-hub-ready-$suffix');

  await _tap(tester, find.text(AppStrings.accountAddressesLabel));
  await _frames(tester);
  await _shot(tester, 'addresses-ready-$suffix');
  await _back(tester);

  await _scrollTo(tester, find.text(AppStrings.supportTicketsLabel));
  await _tap(tester, find.text(AppStrings.supportTicketsLabel));
  await _frames(tester, count: 30);
  await _shot(tester, 'support-list-ready-$suffix');
  final ticketTile = find.byKey(
    const Key('support-ticket-tile-$_supportTicketId'),
  );
  await _scrollTo(tester, ticketTile);
  await _tap(tester, ticketTile);
  await _frames(tester);
  await _shot(tester, 'support-detail-ready-$suffix');
}

Future<void> _captureAlertsSessions(WidgetTester tester, String suffix) async {
  await _pumpPopulated(tester);
  await _frames(tester, count: 40);
  await _tap(tester, find.byIcon(Icons.notifications_outlined));
  await tester.pump();
  if (tester.any(find.byType(CircularProgressIndicator))) {
    await _shot(tester, 'notifications-loading-$suffix');
  }
  await _frames(tester);
  await _shot(tester, 'notifications-ready-$suffix');

  await _tap(tester, find.byIcon(Icons.person_outline));
  await _frames(tester);
  await _scrollTo(tester, find.text(AppStrings.accountSecurityLabel));
  await _tap(tester, find.text(AppStrings.accountSecurityLabel));
  await _frames(tester);
  await _shot(tester, 'sessions-ready-$suffix');
}

void main() {
  testWidgets('mocked populated catalog SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureCatalogJourney(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked populated search SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureSearchJourney(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked populated checkout SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureCheckoutJourney(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked populated orders SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureOrdersJourney(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked populated account SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureAccountJourney(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked populated alerts sessions SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureAlertsSessions(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked populated catalog 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureCatalogJourney(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked populated search 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureSearchJourney(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked populated checkout 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureCheckoutJourney(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked populated orders 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureOrdersJourney(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked populated account 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureAccountJourney(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked populated alerts sessions 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureAlertsSessions(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked dense forms SE 375×667 text 1.3', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _size(tester, const Size(375, 667));
    await _pumpPopulated(tester);
    await _frames(tester);
    await _shot(tester, 'home-ready-se-375x667-text-1.3');

    await _tap(tester, find.text(AppStrings.seeAll));
    await _shot(tester, 'categories-ready-se-375x667-text-1.3');
    await _back(tester);

    GoRouter.of(tester.element(find.byType(HomeScreen))).push(AppRoutes.cart);
    await _frames(tester);
    await _shot(tester, 'cart-ready-se-375x667-text-1.3');
    await _tap(tester, find.byKey(const Key('checkout-review-cta')));
    await _frames(tester);
    await _shot(tester, 'checkout-review-ready-se-375x667-text-1.3');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await _frames(tester);
    await _shot(tester, 'checkout-review-keyboard-se-375x667-text-1.3');
    tester.view.resetViewInsets();

    await _back(tester);
    await _back(tester);
    await _tap(tester, find.byIcon(Icons.person_outline));
    await _shot(tester, 'account-hub-ready-se-375x667-text-1.3');
    await _tap(tester, find.text(AppStrings.accountAddressesLabel));
    await _frames(tester);
    await _tap(tester, find.byKey(const Key('add-address-button')));
    await _frames(tester);
    await _shot(tester, 'address-form-ready-se-375x667-text-1.3');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.tap(find.byKey(const Key('address-text-field')));
    await _frames(tester);
    await _shot(tester, 'address-form-keyboard-se-375x667-text-1.3');
  }, skip: !_capture);
}
