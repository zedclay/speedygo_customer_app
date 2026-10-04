import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/config/electronic_payment_config.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/auth/presentation/profile_setup_screen.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_active_order_card.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/last_created_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_confirmation_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_payment_screen.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_create_screen.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/fakes.dart';
import '../helpers/order_fixtures.dart';
import '../widget_test.dart' as host;
import 'audit_screenshot_capture_test.dart' show populatedReadyApp;

final _capture = Platform.environment['AUDIT_CAPTURE'] == '1';

const _productImagePath =
    '/customer/catalog/product-images/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _keyboardInsetPx = 280.0;

Uint8List _productPhotoBytes() =>
    File('test/audit/fixtures/product-photo.jpg').readAsBytesSync();

Future<void> _sizeSe(WidgetTester tester) async {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _settle(WidgetTester tester, {int pumps = 40}) async {
  for (var i = 0; i < pumps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _clear(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _assertClean(WidgetTester tester) async {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Unexpected Flutter exception: $error');
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _assertClean(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../audit/visuals/pilot/flutter/$name.png'),
  );
}

Widget _themed({
  required Widget home,
  List overrides = const [],
}) {
  return ProviderScope(
    overrides: [...overrides],
    child: MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: home,
    ),
  );
}

CatalogProductDetail _croissantWithPhoto() {
  return const CatalogProductDetail(
    productId: espressoProductId,
    branchId: cafeBranchId,
    categoryId: drinksCategoryId,
    name: 'Croissant au beurre',
    description: 'Pâte feuilletée, beurre, cuit le matin.',
    priceMinor: '40000',
    imageUrl: _productImagePath,
    optionGroups: [],
  );
}

CustomerPayment _mockSucceededPayment() {
  return const CustomerPayment(
    paymentId: 'pay-1',
    method: 'ELECTRONIC',
    status: 'SUCCEEDED',
    amountMinor: '1700',
    currency: 'DZD',
    provider: 'mock',
    createdAt: '2026-09-11T00:00:00.000Z',
    updatedAt: '2026-09-11T00:00:00.000Z',
  );
}

void main() {
  testWidgets('pilot SE: home populated', (tester) async {
    await _sizeSe(tester);
    await tester.pumpWidget(populatedReadyApp());
    await _settle(tester, pumps: 80);

    expect(find.byType(HomeScreen), findsOneWidget);
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.text(AppStrings.searchHint), findsWidgets);
    expect(find.text('Restaurants'), findsWidgets);
    expect(find.text('Boulangeries'), findsWidgets);
    expect(find.byType(HomeActiveOrderCard), findsOneWidget);
    expect(find.text('DEMO150'), findsOneWidget);
    expect(find.byTooltip(AppStrings.copyPromoCode), findsOneWidget);

    // Entire promo (code + copy) must be reachable by scrolling, then restore
    // the top viewport (logo + categories) for the representative golden.
    await tester.ensureVisible(find.text('DEMO150'));
    await tester.ensureVisible(find.byTooltip(AppStrings.copyPromoCode));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    scrollable.position.jumpTo(0);
    await _settle(tester, pumps: 8);

    final logo = find.byKey(const Key('home-logo'));
    expect(logo, findsOneWidget);
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/speedygo_logo.png'),
        tester.element(find.byType(HomeScreen)),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('Restaurants'), findsWidgets);

    await _shot(tester, 'home-ready-se-375x667');
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('pilot SE: profile setup filled + enabled CTA', (tester) async {
    await _sizeSe(tester);
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
        onboardingSeen: true,
        languageSeen: true,
      ),
    );
    for (var i = 0; i < 120; i++) {
      if (tester.any(find.byType(ProfileSetupScreen))) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(
      find.text(AppStrings.profileStep.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(AppStrings.otpTitle), findsNothing);
    expect(find.text(AppStrings.profilePhotoUnavailable), findsOneWidget);
    final router = GoRouter.of(
      tester.element(find.byType(ProfileSetupScreen)),
    );
    expect(router.state.uri.path, AppRoutes.profileSetup);

    // Valid filled fullName → enabled Continue CTA (email/photo remain unsupported).
    await tester.enterText(find.byType(TextField), 'Amel Benali');
    await tester.pump();
    final continueBtn = find.widgetWithText(
      SgPrimaryButton,
      AppStrings.continueLabel,
    );
    expect(continueBtn, findsOneWidget);
    expect(
      tester.widget<SgPrimaryButton>(continueBtn).onPressed,
      isNotNull,
    );

    await _settle(tester);
    await _shot(tester, 'profile-setup-ready-se-375x667');
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('pilot SE: order confirmation COD (awaiting merchant)', (
    tester,
  ) async {
    await _sizeSe(tester);
    final order = sampleOrderDetail(paymentMethod: 'COD');
    final orders = FakeOrdersClient()..details[order.id] = order;

    await tester.pumpWidget(
      _themed(
        home: OrderConfirmationScreen(orderId: order.id),
        overrides: [
          ordersApiProvider.overrideWithValue(orders),
          lastCreatedOrderProvider.overrideWith(
            () => _FixedLastCreated(order),
          ),
        ],
      ),
    );
    await _settle(tester);

    expect(find.byType(OrderConfirmationScreen), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmationSent), findsOneWidget);
    expect(find.text(AppStrings.orderItemsLabel), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmationAmountCod), findsOneWidget);
    expect(find.text(AppStrings.checkoutPayable), findsNothing);
    expect(
      find.text(AppStrings.orderConfirmationAwaitingMerchantShort),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.orderConfirmationNoPaymentCollected),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('order-confirmation-continue-payment')),
      findsNothing,
    );
    expect(find.byKey(const Key('order-confirmation-detail')), findsOneWidget);

    // Scrolled capture: full payment status above sticky actions.
    final status = find.byKey(const Key('order-confirmation-payment-status'));
    await tester.ensureVisible(status);
    await _settle(tester, pumps: 6);
    final statusRect = tester.getRect(status);
    final detailRect = tester.getRect(
      find.byKey(const Key('order-confirmation-detail')),
    );
    expect(statusRect.bottom, lessThanOrEqualTo(detailRect.top + 1));

    await _shot(tester, 'order-confirmation-ready-se-375x667');
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('pilot SE: product detail with live croissant photo', (
    tester,
  ) async {
    await _sizeSe(tester);
    final photo = _productPhotoBytes();
    final detail = _croissantWithPhoto();
    expect(detail.imageUrl, startsWith('/customer/'));
    expect(
      resolveCustomerCatalogImagePath(detail.imageUrl),
      _productImagePath,
    );
    // Reject color-band fixture regressions (tiny placeholder ~11KB).
    expect(photo.lengthInBytes, greaterThan(20000));

    await tester.pumpWidget(
      _themed(
        home: const ProductDetailScreen(
          branchId: cafeBranchId,
          productId: espressoProductId,
        ),
        overrides: [
          catalogApiProvider.overrideWithValue(
            FakeCatalogClient(productDetail: detail),
          ),
          coverImageBytesProvider.overrideWith((ref, path) async {
            expect(path, startsWith('/customer/'));
            return photo;
          }),
        ],
      ),
    );
    for (var i = 0; i < 100; i++) {
      if (tester.any(find.byKey(const Key('authenticated-catalog-image')))) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Croissant au beurre'), findsOneWidget);
    expect(find.text('Pâte feuilletée, beurre, cuit le matin.'), findsOneWidget);
    final imageFinder = find.byKey(const Key('authenticated-catalog-image'));
    expect(imageFinder, findsOneWidget);
    expect(find.byKey(const Key('catalog-image-unbound')), findsNothing);
    expect(find.byKey(const Key('catalog-image-loading')), findsNothing);

    final imageElement = tester.element(imageFinder);
    expect(tester.widget<Image>(imageFinder).image, isA<MemoryImage>());
    await tester.runAsync(() async {
      await precacheImage(MemoryImage(photo), imageElement);
    });
    await tester.pumpAndSettle();

    expect(tester.widget<Image>(imageFinder).image, isA<MemoryImage>());
    RenderImage? decoded;
    void walk(RenderObject object) {
      if (object is RenderImage && object.image != null) {
        decoded = object;
        return;
      }
      object.visitChildren(walk);
    }
    walk(imageElement.renderObject!);
    expect(decoded, isNotNull);
    expect(decoded!.image, isNotNull);

    await _settle(tester, pumps: 10);
    await _shot(tester, 'product-ready-se-375x667');
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('pilot SE: support order-linked create (keyboard hidden)', (
    tester,
  ) async {
    await _sizeSe(tester);
    tester.view.viewInsets = const FakeViewPadding();
    addTearDown(tester.view.resetViewInsets);

    final order = sampleOrderDetail();
    final orders = FakeOrdersClient()..details[order.id] = order;

    await tester.pumpWidget(
      _themed(
        home: SupportCreateScreen(orderId: order.id),
        overrides: [
          ordersApiProvider.overrideWithValue(orders),
        ],
      ),
    );
    await _settle(tester, pumps: 20);

    expect(find.byType(SupportCreateScreen), findsOneWidget);
    expect(find.text(AppStrings.supportNewTitle), findsOneWidget);
    expect(find.text(AppStrings.supportOrderLinked), findsOneWidget);
    expect(
      find.byKey(const Key('support-create-order-reference')),
      findsOneWidget,
    );
    expect(find.text(order.publicReference), findsOneWidget);
    expect(find.text(order.id), findsNothing);
    expect(find.text(AppStrings.supportOrderOptional), findsNothing);
    expect(
      MediaQuery.viewInsetsOf(
        tester.element(find.byType(SupportCreateScreen)),
      ).bottom,
      0,
    );

    await _shot(tester, 'support-create-keyboard-se-375x667');
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('pilot SE: support create 280px inset reachability (no golden)', (
    tester,
  ) async {
    await _sizeSe(tester);

    final order = sampleOrderDetail();
    await tester.pumpWidget(
      _themed(
        home: SupportCreateScreen(orderId: order.id),
        overrides: [
          ordersApiProvider.overrideWithValue(
            FakeOrdersClient()..details[order.id] = order,
          ),
        ],
      ),
    );
    await _settle(tester, pumps: 20);

    final bodyField = find.byKey(const Key('support-create-body'));
    await tester.tap(bodyField);
    await tester.showKeyboard(bodyField);

    addTearDown(tester.view.resetViewInsets);
    final keyboardInsetPhysical =
        _keyboardInsetPx * tester.view.devicePixelRatio;
    for (var i = 0; i < 12; i++) {
      tester.view.viewInsets = FakeViewPadding(
        left: 0,
        top: 0,
        right: 0,
        bottom: keyboardInsetPhysical,
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    final screenElement = tester.element(find.byType(SupportCreateScreen));
    expect(
      MediaQuery.viewInsetsOf(screenElement).bottom,
      _keyboardInsetPx,
    );

    final submit = find.byKey(const Key('support-create-submit'));
    expect(submit, findsOneWidget);
    final rect = tester.getRect(submit);
    expect(
      rect.bottom <= 667 - _keyboardInsetPx + 8,
      isTrue,
      reason:
          'Submit bottom ${rect.bottom} must clear keyboard '
          '(inset $_keyboardInsetPx on 667h)',
    );
    await _clear(tester);
  }, skip: !_capture);

  testWidgets(
    'pilot SE: payment success lands on confirmation (gate off, SUCCEEDED)',
    (tester) async {
      await _sizeSe(tester);
      expect(ElectronicPaymentConfig.enabled, isFalse);

      final order = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
      final payment = _mockSucceededPayment();
      expect(payment.provider, 'mock');
      expect(
        (payment.provider ?? '').toLowerCase(),
        isNot(contains('chargily')),
      );
      final orders = FakeOrdersClient()
        ..details[order.id] = order
        ..paymentResult = payment;

      final router = GoRouter(
        initialLocation: '/orders/${order.id}/payment',
        routes: [
          GoRoute(
            path: '/orders/:orderId/payment',
            builder: (context, state) => OrderPaymentScreen(
              orderId: state.pathParameters['orderId']!,
            ),
          ),
          GoRoute(
            path: '/orders/:orderId/confirmation',
            builder: (context, state) => OrderConfirmationScreen(
              orderId: state.pathParameters['orderId']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersApiProvider.overrideWithValue(orders),
            lastCreatedOrderProvider.overrideWith(
              () => _FixedLastCreated(order),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          ),
        ),
      );

      for (var i = 0; i < 100; i++) {
        if (tester.any(find.byType(OrderConfirmationScreen))) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
      await _settle(tester);

      expect(find.byType(OrderConfirmationScreen), findsOneWidget);
      expect(find.text(AppStrings.orderConfirmationSent), findsOneWidget);
      expect(find.text(AppStrings.orderItemsLabel), findsOneWidget);
      expect(
        find.text(AppStrings.orderConfirmationPaymentSucceeded),
        findsOneWidget,
      );
      expect(find.text(AppStrings.orderConfirmationAmountPaid), findsOneWidget);
      expect(find.text(AppStrings.checkoutPayable), findsNothing);
      expect(
        find.text(AppStrings.orderConfirmationPaymentPending),
        findsNothing,
      );
      expect(
        find.byKey(const Key('order-confirmation-continue-payment')),
        findsNothing,
      );
      expect(find.byType(OrderPaymentScreen), findsNothing);
      expect(router.state.uri.path, '/orders/${order.id}/confirmation');

      final status = find.byKey(const Key('order-confirmation-payment-status'));
      await tester.ensureVisible(status);
      await _settle(tester, pumps: 6);
      final statusRect = tester.getRect(status);
      final detailRect = tester.getRect(
        find.byKey(const Key('order-confirmation-detail')),
      );
      expect(statusRect.bottom, lessThanOrEqualTo(detailRect.top + 1));

      await _shot(tester, 'payment-success-to-confirmation-se-375x667');
      await _clear(tester);
    },
    skip: !_capture,
  );
}

class _FixedLastCreated extends LastCreatedOrderController {
  _FixedLastCreated(this.seed);
  final OrderDetail seed;
  @override
  OrderDetail? build() => seed;
}
