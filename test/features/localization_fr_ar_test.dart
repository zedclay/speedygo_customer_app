import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/order_fixtures.dart';
import '../widget_test.dart' as host;
import 'customer_navigation_test.dart';

void _iphone16e(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
  addTearDown(tester.view.reset);
}

Future<void> _pumpOut(WidgetTester tester, {int ticks = 24}) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  test('French copy is unchanged after a round-trip bind', () {
    AppStrings.bind('fr');
    expect(AppStrings.tabHome, 'Accueil');
    expect(AppStrings.continueLabel, 'Continuer');
    expect(AppStrings.languageSessionNote, contains('français et l’arabe'));
    AppStrings.bind('ar');
    expect(AppStrings.tabHome, 'الرئيسية');
    expect(AppStrings.continueLabel, 'متابعة');
    AppStrings.bind('fr');
    expect(AppStrings.tabHome, 'Accueil');
    expect(AppStrings.searchHint, 'Rechercher un commerce ou produit');
  });

  test('DZD formatting stays locale-invariant', () {
    AppStrings.bind('fr');
    expect(MoneyFormat.dzd('0'), '0,00 DZD');
    expect(MoneyFormat.dzd('220000'), '2 200,00 DZD');
    AppStrings.bind('ar');
    expect(MoneyFormat.dzd('0'), '0,00 DZD');
    expect(MoneyFormat.dzd('220000'), '2 200,00 DZD');
    expect(MoneyFormat.dzd('650.00'), '650,00 DZD');
  });

  test('errorForCode is bilingual and phones stay Latin', () {
    AppStrings.bind('fr');
    expect(AppStrings.errorForCode('AUTH_INVALID_OTP'), 'Code incorrect. Réessayez.');
    expect(AppStrings.phonePrefix, '+213');
    expect(AppStrings.phoneHint, '555 12 34 56');
    AppStrings.bind('ar');
    expect(AppStrings.errorForCode('AUTH_INVALID_OTP'), 'رمز غير صحيح. أعد المحاولة.');
    expect(AppStrings.phonePrefix, '+213');
    expect(AppStrings.promoCode, 'SPEEDY150');
    expect(AppStrings.locationSearchUnavailable, contains('غير مُعدّ'));
    expect(AppStrings.locationSearchLoading, 'جاري البحث…');
    expect(AppStrings.locationSearchFailed, contains('أعد المحاولة'));
    expect(AppStrings.locationMapTilesDev, contains('OSM'));
    expect(AppStrings.locationMapUnavailable, contains('غير مُعدّ'));
    expect(AppStrings.locationSearchDisabledOnDevMap, contains('معطّل'));
    expect(AppStrings.checkoutPaymentElectronicSoon, 'قريبًا');
    expect(AppStrings.categoryRestaurants, 'مطاعم');
    expect(AppStrings.categoryGroceries, 'بقالات');
    AppStrings.bind('fr');
    expect(AppStrings.categoryRestaurants, 'Restaurants');
    expect(AppStrings.categoryRestaurantsSubtitle, 'Burgers, Pizzas, Traditionnel...');
  });

  testWidgets('first-run language picker enables Arabic and persists it', (
    tester,
  ) async {
    _iphone16e(tester);
    final launch = MemoryLaunchStore(onboardingSeen: false, languageSeen: false);
    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        launch: launch,
      ),
    );
    await _pumpOut(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.languageTitle), findsOneWidget);
    expect(find.text(AppStrings.languageArabicDisabled), findsNothing);
    await tester.tap(find.byKey(const Key('language-option-ar')));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await _pumpOut(tester);
    expect(launch.locale, AppLocale.arabic);
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
    final dir = tester
        .widget<Directionality>(find.byType(Directionality).first)
        .textDirection;
    expect(dir, TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic home cart orders address and logout fit without overflow', (
    tester,
  ) async {
    _iphone16e(tester);
    final launch = MemoryLaunchStore(
      onboardingSeen: true,
      languageSeen: true,
      locale: AppLocale.arabic,
    );
    await tester.pumpWidget(
      readyApp(
        launch: launch,
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()])),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.tabHome), findsWidgets);
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(
      find.text(MoneyFormat.dzd('220000')),
      findsNothing,
    );

    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.orders);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tabOrders), findsWidgets);
    expect(find.text(MoneyFormat.dzd('1900')), findsWidgets);
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.addressForm);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addAddress), findsOneWidget);
    expect(find.text('Sidi Bel Abbès'), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.accountLanguage);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('language-option-ar')), findsOneWidget);
    expect(find.text(AppStrings.languageSessionNote), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.checkoutMethod);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.checkoutPaymentCod), findsOneWidget);
    expect(find.text(AppStrings.checkoutPaymentElectronicSoon), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.supportList);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.supportEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stored Arabic locale restores RTL after a new app pump', (
    tester,
  ) async {
    _iphone16e(tester);
    final launch = MemoryLaunchStore(
      onboardingSeen: true,
      languageSeen: true,
      locale: AppLocale.arabic,
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: true,
        profileComplete: true,
        addressReady: false,
        profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
      );
    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: customer,
        store: store,
        launch: launch,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
    expect(find.text(AppStrings.tabHome), findsWidgets);

    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: customer,
        store: store,
        launch: launch,
      ),
    );
    await tester.pumpAndSettle();
    final locale = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).read(sessionControllerProvider).locale;
    expect(locale, AppLocale.arabic);
    expect(launch.locale, AppLocale.arabic);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
