import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';

import '../test/helpers/fakes.dart';

Widget _app({
  required FakeAuthClient auth,
  required FakeCustomerClient customer,
  MemorySessionStore? store,
  bool onboardingSeen = true,
  bool? languageSeen,
  bool navPreview = false,
}) {
  return ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(store ?? MemorySessionStore()),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(
          onboardingSeen: onboardingSeen,
          languageSeen: languageSeen,
        ),
      ),
      splashMinDurationProvider.overrideWithValue(Duration.zero),
      splashAnimateProvider.overrideWithValue(false),
      authApiProvider.overrideWithValue(auth),
      customerApiProvider.overrideWithValue(customer),
      catalogApiProvider.overrideWithValue(FakeCatalogClient()),
      ordersApiProvider.overrideWithValue(FakeOrdersClient()),
      ratingsApiProvider.overrideWithValue(FakeRatingsClient()),
      addressApiProvider.overrideWithValue(
        FakeAddressClient(addresses: customer.meResult.addresses),
      ),
      addressSelectionStoreProvider.overrideWithValue(
        MemoryAddressSelectionStore(),
      ),
      locationClientProvider.overrideWithValue(FakeLocationClient()),
      navPreviewEnabledProvider.overrideWith(
        () => NavPreviewFlag(initial: navPreview),
      ),
    ],
    child: const SpeedyGoApp(),
  );
}

Widget _readyApp({bool navPreview = false}) {
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
  return _app(
    auth: FakeAuthClient(),
    customer: customer,
    store: store,
    navPreview: navPreview,
  );
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    await binding.takeScreenshot(name);
  } catch (_) {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigation review: first-use language stays French', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        onboardingSeen: false,
        languageSeen: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.languageTitle), findsOneWidget);
    expect(find.text(AppStrings.languageArabicDisabled), findsOneWidget);
    await _shot(binding, '01-language');

    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
    await _shot(binding, '02-introduction');

    await tester.tap(find.text(AppStrings.skip));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    await _shot(binding, '03-phone-after-intro');
  });

  testWidgets('navigation review: normal home has no fixtures', (tester) async {
    await tester.pumpWidget(_readyApp());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.allScreens), findsNothing);
    expect(find.text(AppStrings.landingTitle), findsNothing);
    expect(find.text(AppStrings.activeOrder), findsNothing);
    await _shot(binding, '04-home');

    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.directory);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.previewBanner), findsNothing);
  });

  testWidgets('navigation review: preview directory and logout dismiss', (
    tester,
  ) async {
    await tester.pumpWidget(_readyApp(navPreview: true));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.directory);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.previewBanner), findsOneWidget);
    await _shot(binding, '05-directory');

    await tester.scrollUntilVisible(
      find.text('Favoris'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un favori'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.favoritesUnavailable), findsOneWidget);
    await _shot(binding, '06-favorites-blocked');

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('account-logout')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await _shot(binding, '07-account-hub');
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-logout')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.logoutConfirmTitle), findsOneWidget);
    await _shot(binding, '08-logout-modal');
    await tester.scrollUntilVisible(
      find.text(AppStrings.cancel),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.logoutConfirmTitle), findsNothing);
    expect(find.byKey(const Key('account-logout')), findsOneWidget);
  });
}
