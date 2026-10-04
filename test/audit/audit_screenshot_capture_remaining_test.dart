import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/auth/presentation/restore_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';

import '../features/customer_navigation_test.dart';
import '../helpers/catalog_fixtures.dart';
import '../helpers/fakes.dart';
import '../helpers/order_fixtures.dart';
import '../widget_test.dart' as host;
import 'audit_screenshot_capture_test.dart' show populatedReadyApp;

final _capture = Platform.environment['AUDIT_CAPTURE'] == '1';

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
    matchesGoldenFile('../../audit/visuals/alignment/flutter/$name.png'),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets);
  await tester.tap(finder.first);
  await _frames(tester);
}

Future<void> _waitFor(WidgetTester tester, Finder finder, {int pumps = 40}) async {
  for (var i = 0; i < pumps; i++) {
    if (tester.any(finder)) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _assertSaveAboveKeyboard(WidgetTester tester) async {
  const keyboardLogical = 280.0;
  addTearDown(tester.view.resetViewInsets);
  tester.view.viewInsets = FakeViewPadding(
    bottom: keyboardLogical * tester.view.devicePixelRatio,
  );
  await _frames(tester, count: 12);
  final save = find.byKey(const Key('address-save-button'));
  expect(save, findsOneWidget);
  final insets = MediaQuery.viewInsetsOf(tester.element(save));
  expect(insets.bottom, keyboardLogical);
  expect(save.hitTestable(), findsOneWidget);
  final rect = tester.getRect(save);
  final viewHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  expect(rect.height, greaterThan(40));
  expect(rect.top, greaterThan(0));
  expect(rect.bottom, lessThanOrEqualTo(viewHeight - insets.bottom + 0.5));
}

Future<void> _scrollToSupportIfNeeded(WidgetTester tester) async {
  final target = find.text(AppStrings.supportTicketsLabel);
  for (var i = 0; i < 12; i++) {
    if (tester.any(target)) {
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 80));
      return;
    }
    final scrollable = find.byType(Scrollable);
    if (!tester.any(scrollable)) {
      return;
    }
    await tester.drag(scrollable.first, const Offset(0, -240));
    await tester.pump(const Duration(milliseconds: 80));
  }
}

GoRouter _router(WidgetTester tester) {
  if (tester.any(find.byType(HomeScreen))) {
    return GoRouter.of(tester.element(find.byType(HomeScreen)));
  }
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

Future<void> _captureAuthJourney(WidgetTester tester, String suffix) async {
  // Same first-launch path as widget_test: language → welcome → phone.
  await tester.pumpWidget(
    host.app(
      auth: FakeAuthClient(),
      customer: FakeCustomerClient(),
      onboardingSeen: false,
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 2));
  expect(find.text(AppStrings.languageTitle), findsOneWidget);
  await _shot(tester, 'language-ready-$suffix');

  await _tap(tester, find.widgetWithText(FilledButton, AppStrings.continueLabel));
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
  expect(find.byType(PageView), findsOneWidget);
  await _shot(tester, 'welcome-ready-$suffix');

  await tester.drag(find.byType(PageView), const Offset(-280, 0));
  await _frames(tester, count: 20);
  await _shot(tester, 'welcome-order-ready-$suffix');
  await tester.drag(find.byType(PageView), const Offset(-280, 0));
  await _frames(tester, count: 20);
  await _shot(tester, 'welcome-track-ready-$suffix');

  if (tester.any(find.text(AppStrings.skip))) {
    await _tap(tester, find.text(AppStrings.skip));
  } else {
    await _tap(tester, find.widgetWithText(FilledButton, AppStrings.start));
  }
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  await _shot(tester, 'phone-ready-$suffix');

  await tester.enterText(
    find.byKey(const Key('phone-number-field')),
    '550000072',
  );
  await _frames(tester);
  await _tap(tester, find.widgetWithText(FilledButton, AppStrings.continueLabel));
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.otpTitle), findsOneWidget);
  await _shot(tester, 'otp-ready-$suffix');
}

Future<void> _captureProfileSetup(WidgetTester tester, String suffix) async {
  final auth = FakeAuthClient()
    ..meResult = const AuthMe(
      accountId: 'acc-1',
      phone: '+213550000072',
      status: 'ACTIVE',
      hasCustomerProfile: false,
    );
  final store = MemorySessionStore()
    ..value = const TokenPair(
      accessToken: 'access-1',
      refreshToken: 'refresh-1-token-value',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  await tester.pumpWidget(
    host.app(
      auth: auth,
      customer: FakeCustomerClient()
        ..meResult = const CustomerMe(
          customerProfileExists: false,
          profileComplete: false,
          addressReady: false,
        ),
      store: store,
    ),
  );
  await _waitFor(tester, find.text(AppStrings.profileStep), pumps: 80);
  await _frames(tester, count: 20);
  await _shot(tester, 'profile-setup-ready-$suffix');
}

Future<void> _captureRestore(WidgetTester tester, String suffix) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: RestoreScreen()),
    ),
  );
  await _frames(tester);
  await _shot(tester, 'restore-loading-ready-$suffix');
}

Future<void> _captureCheckoutExtras(WidgetTester tester, String suffix) async {
  await tester.pumpWidget(populatedReadyApp());
  await _frames(tester, count: 30);
  final router = _router(tester);
  router.go(AppRoutes.checkoutMethod);
  await _frames(tester, count: 30);
  await _shot(tester, 'checkout-method-ready-$suffix');

  router.go(AppRoutes.orderConfirmation(activeOrderId));
  await _frames(tester, count: 40);
  await _shot(tester, 'order-confirmation-ready-$suffix');
}

Future<void> _captureMerchantExtras(WidgetTester tester, String suffix) async {
  await tester.pumpWidget(populatedReadyApp(ratings: FakeRatingsClient()));
  await _frames(tester, count: 40);
  expect(find.byType(HomeScreen), findsOneWidget);
  _router(tester).go(AppRoutes.merchantReviews(cafeBranchId));
  await _frames(tester, count: 50);
  expect(find.text(AppStrings.ratingReviewsEmpty), findsOneWidget);
  expect(find.text(AppStrings.ratingReviewsUnsupportedEmpty), findsOneWidget);
  expect(find.textContaining('Voici la note moyenne'), findsNothing);
  await _shot(tester, 'merchant-reviews-empty-$suffix');

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(populatedReadyApp());
  await _frames(tester, count: 50);
  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.text(AppStrings.seeAll), findsWidgets);
  await _tap(tester, find.text(AppStrings.seeAll));
  await _tap(tester, find.text('Restaurants'));
  await _frames(tester);
  await _tap(tester, find.text('Café Central'));
  await _frames(tester, count: 30);
  await _shot(tester, 'menu-ready-$suffix');

  await _tap(tester, find.byTooltip(AppStrings.storefrontInfo));
  await _frames(tester, count: 30);
  await _shot(tester, 'merchant-info-ready-$suffix');

  final router = _router(tester);
  router.go(AppRoutes.merchant(cafeBranchId));
  await _frames(tester, count: 30);
  await _tap(tester, find.byKey(const Key('storefront-reviews-entry')));
  await _frames(tester, count: 30);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  expect(find.textContaining('4.7'), findsWidgets);
  expect(find.text(AppStrings.ratingReviewsEmpty), findsNothing);
  expect(find.text(AppStrings.ratingReviewsUnsupported), findsOneWidget);
  await _shot(tester, 'merchant-reviews-ready-$suffix');
}

Future<void> _captureOrdersExtras(WidgetTester tester, String suffix) async {
  final completed = sampleOrderDetail(
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa10',
    status: 'COMPLETED',
    fulfillmentStatus: 'DELIVERED',
  );
  final waiting = sampleOrderDetail(
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa13',
  );
  final searching = sampleOrderDetail(
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa11',
    status: 'ACTIVE',
    fulfillmentStatus: 'READY',
  );
  final inTransit = sampleOrderDetail(
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa12',
    status: 'ACTIVE',
    fulfillmentStatus: 'READY',
  );
  final deliverySearching = sampleDelivery(
    orderId: searching.id,
    status: 'SEARCHING_DRIVER',
  );
  final deliveryTransit = sampleDelivery(
    id: '22222222-2222-4222-8222-222222222212',
    orderId: inTransit.id,
    status: 'IN_TRANSIT',
  );

  final orders = FakeOrdersClient(
    orders: orderPage([
      sampleOrder(),
      sampleOrder(
        id: searching.id,
        publicReference: 'sgo_searching001',
        status: 'ACTIVE',
        fulfillmentStatus: 'READY',
      ),
    ]),
  )..details.addAll({
      waiting.id: waiting,
      searching.id: searching,
      inTransit.id: inTransit,
      completed.id: completed,
      activeOrderId: sampleOrderDetail(),
    });

  await tester.pumpWidget(
    readyApp(
      orders: orders,
      catalog: FakeCatalogClient(storefrontDetail: cafeStorefrontDetail()),
      ratings: FakeRatingsClient(),
    ),
  );
  await _frames(tester, count: 30);
  final router = _router(tester);

  await tester.tap(find.byIcon(Icons.receipt_long_outlined));
  await _frames(tester, count: 40);
  expect(
    find.byKey(const Key('order-list-tile-$activeOrderId')),
    findsOneWidget,
  );
  expect(find.textContaining(AppStrings.orderPaymentCod), findsWidgets);
  await _shot(tester, 'orders-in-progress-ready-$suffix');

  await tester.tap(find.byKey(const Key('order-list-tile-$activeOrderId')));
  await _frames(tester, count: 40);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  await _shot(tester, 'order-detail-ready-$suffix');
  await tester.tap(find.byTooltip(AppStrings.back).first);
  await _frames(tester, count: 20);

  router.go(AppRoutes.orderCancel(activeOrderId));
  await _frames(tester, count: 40);
  await _shot(tester, 'order-cancel-form-ready-$suffix');

  router.go(AppRoutes.orderWaiting(waiting.id));
  await _frames(tester, count: 50);
  expect(find.text(AppStrings.trackingAwaitingMerchantTitle), findsOneWidget);
  expect(find.byKey(const Key('tracking-reference')), findsOneWidget);
  expect(find.text('#${waiting.publicReference}'), findsOneWidget);
  expect(find.text(waiting.publicReference), findsNothing);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  await _shot(tester, 'tracking-waiting-ready-$suffix');

  orders
    ..delivery = deliverySearching
    ..trackingResult = TrackingSnapshot(
      deliveryId: deliverySearching.id,
      orderId: searching.id,
      driverAssigned: false,
      status: 'NO_DRIVER',
      isStale: false,
    );
  router.go(AppRoutes.orderSearching(searching.id));
  await _frames(tester, count: 50);
  await _shot(tester, 'tracking-searching-ready-$suffix');

  orders
    ..delivery = deliveryTransit
    ..trackingResult = TrackingSnapshot(
      deliveryId: deliveryTransit.id,
      orderId: inTransit.id,
      driverAssigned: true,
      assignedDriverId: 'driver-1',
      status: 'LIVE',
      isStale: false,
      location: TrackingLocation(
        deliveryId: deliveryTransit.id,
        assignedDriverId: 'driver-1',
        latitude: 36.76,
        longitude: 3.06,
        recordedAt: '2026-09-11T12:00:00.000Z',
      ),
    );
  router.go(AppRoutes.orderMap(inTransit.id));
  await _frames(tester, count: 50);
  await _shot(tester, 'tracking-map-ready-$suffix');

  router.go(AppRoutes.orderNearby(inTransit.id));
  await _frames(tester, count: 40);
  await _shot(tester, 'tracking-nearby-ready-$suffix');

  router.go(AppRoutes.orderCompleted(completed.id));
  await _frames(tester, count: 40);
  await _shot(tester, 'tracking-completed-ready-$suffix');

  router.go(AppRoutes.orderRate(completed.id));
  await _frames(tester, count: 50);
  await _shot(tester, 'order-rate-ready-$suffix');

  router.go(AppRoutes.orderReview(completed.id));
  await _frames(tester, count: 40);
  await _shot(tester, 'order-write-review-ready-$suffix');
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _captureAccountExtras(WidgetTester tester, String suffix) async {
  await tester.pumpWidget(populatedReadyApp());
  await _frames(tester, count: 30);
  final router = _router(tester);

  router.go(AppRoutes.accountLanguage);
  await _frames(tester, count: 30);
  await _shot(tester, 'account-language-ready-$suffix');

  router.go(AppRoutes.account);
  await _frames(tester, count: 30);
  _router(tester).push(AppRoutes.supportNew);
  await _frames(tester, count: 30);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  await _shot(tester, 'support-create-ready-$suffix');
  await tester.tap(find.byTooltip(AppStrings.back).first);
  await _frames(tester, count: 20);

  router.go(AppRoutes.account);
  await _frames(tester, count: 30);
  await _scrollToSupportIfNeeded(tester);
  await _tap(tester, find.text(AppStrings.supportTicketsLabel));
  await _frames(tester, count: 30);
  await _shot(tester, 'support-list-ready-$suffix');
  final ticketTile = find.byKey(
    const Key('support-ticket-tile-55555555-5555-4555-8555-555555555555'),
  );
  expect(ticketTile, findsOneWidget);
  await tester.ensureVisible(ticketTile);
  await tester.tap(ticketTile);
  await _frames(tester, count: 40);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  await _shot(tester, 'support-detail-ready-$suffix');
  await tester.tap(find.byTooltip(AppStrings.back).first);
  await _frames(tester, count: 20);

  router.go(AppRoutes.accountLegal);
  await _frames(tester, count: 30);
  await _shot(tester, 'legal-ready-$suffix');

  router.go(AppRoutes.accountNotifications);
  await _frames(tester, count: 30);
  await _shot(tester, 'notification-prefs-ready-$suffix');

  router.go(AppRoutes.accountDelete);
  await _frames(tester, count: 30);
  await _shot(tester, 'account-delete-ready-$suffix');

  router.go(AppRoutes.accountPaymentMethods);
  await _frames(tester, count: 30);
  await _shot(tester, 'payment-methods-ready-$suffix');

  router.go(AppRoutes.favorites);
  await _frames(tester, count: 30);
  await _shot(tester, 'favorites-ready-$suffix');

  router.go(AppRoutes.promotions);
  await _frames(tester, count: 30);
  await _shot(tester, 'promotions-ready-$suffix');

  router.go(AppRoutes.checkoutNotes);
  await _frames(tester, count: 30);
  await _shot(tester, 'checkout-notes-ready-$suffix');

  router.go(AppRoutes.locationPermission);
  await _frames(tester, count: 30);
  await _shot(tester, 'location-permission-ready-$suffix');

  router.go(AppRoutes.addressConfirm);
  await _frames(tester, count: 30);
  await _shot(tester, 'location-confirm-ready-$suffix');

  router.go(AppRoutes.addressForm);
  await _frames(tester, count: 30);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  expect(find.text(AppStrings.addressCoordsHint), findsOneWidget);
  await tester.ensureVisible(find.text(AppStrings.useMyLocation));
  await tester.ensureVisible(find.text(AppStrings.addressCoordsHint));
  expect(
    find.text(AppStrings.addressCoordsHint).hitTestable(),
    findsOneWidget,
  );
  await _shot(tester, 'address-form-ready-$suffix');
  await tester.ensureVisible(find.byKey(const Key('use-my-location')));
  await _shot(tester, 'address-form-scrolled-$suffix');
  final promoField = find.byKey(const Key('address-text-field'));
  await tester.ensureVisible(promoField);
  await tester.tap(promoField);
  await tester.showKeyboard(promoField);
  await _assertSaveAboveKeyboard(tester);
  await _shot(tester, 'address-form-keyboard-$suffix');
  tester.view.resetViewInsets();
  await tester.pump();

  router.go(AppRoutes.account);
  await _frames(tester, count: 40);
  final logout = find.byKey(const Key('account-logout'));
  for (var i = 0; i < 12 && !tester.any(logout); i++) {
    final scrollable = find.byType(Scrollable);
    if (tester.any(scrollable)) {
      await tester.drag(scrollable.first, const Offset(0, -240));
      await tester.pump(const Duration(milliseconds: 80));
    }
  }
  expect(logout, findsWidgets);
  await _tap(tester, logout);
  await _frames(tester, count: 20);
  await _shot(tester, 'logout-sheet-ready-$suffix');
}

void main() {
  testWidgets('mocked remaining auth SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureAuthJourney(tester, 'se-375x667');
    await _captureProfileSetup(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked remaining restore SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureRestore(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked remaining checkout/merchant SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureCheckoutExtras(tester, 'se-375x667');
    await _captureMerchantExtras(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked remaining orders/tracking/ratings SE 375×667', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureOrdersExtras(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked remaining account/honest SE 375×667', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(375, 667));
    await _captureAccountExtras(tester, 'se-375x667');
  }, skip: !_capture);

  testWidgets('mocked remaining auth 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureAuthJourney(tester, 'iphone17pro-402x874');
    await _captureProfileSetup(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked remaining account 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureMerchantExtras(tester, 'iphone17pro-402x874');
    await _captureAccountExtras(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked remaining tracking 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureOrdersExtras(tester, 'iphone17pro-402x874');
  }, skip: !_capture);

  testWidgets('mocked address form dense SE 375×667 text 1.3', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _size(tester, const Size(375, 667));
    await tester.pumpWidget(populatedReadyApp());
    await _frames(tester, count: 30);
    _router(tester).go(AppRoutes.addressForm);
    await _frames(tester, count: 40);
    expect(find.text(AppStrings.addressCoordsHint), findsOneWidget);
    expect(find.byKey(const Key('address-save-button')), findsOneWidget);
    await tester.ensureVisible(find.text(AppStrings.addressCoordsHint));
    await _shot(tester, 'address-form-ready-se-375x667-text-1.3');
    await _shot(tester, 'address-form-scrolled-se-375x667-text-1.3');
    final field = find.byKey(const Key('address-text-field'));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.showKeyboard(field);
    await _assertSaveAboveKeyboard(tester);
    await _shot(tester, 'address-form-keyboard-se-375x667-text-1.3');
    tester.view.resetViewInsets();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }, skip: !_capture);

  testWidgets('mocked remaining tracking/account 402×874', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _size(tester, const Size(402, 874), dpr: 3);
    await _captureCheckoutExtras(tester, 'iphone17pro-402x874');
    await _captureOrdersExtras(tester, 'iphone17pro-402x874');
    await _captureAccountExtras(tester, 'iphone17pro-402x874');
  }, skip: !_capture);
}
