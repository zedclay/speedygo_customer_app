import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';

import '../test/helpers/catalog_fixtures.dart';
import '../test/helpers/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
  }

  Widget mockedApp(FakeCatalogClient catalog) {
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
    return ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: true, languageSeen: true),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        splashAnimateProvider.overrideWithValue(false),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        customerApiProvider.overrideWithValue(customer),
        catalogApiProvider.overrideWithValue(catalog),
        ordersApiProvider.overrideWithValue(FakeOrdersClient()),
        ratingsApiProvider.overrideWithValue(FakeRatingsClient()),
        addressApiProvider.overrideWithValue(FakeAddressClient()),
        addressSelectionStoreProvider.overrideWithValue(
          MemoryAddressSelectionStore(),
        ),
        locationClientProvider.overrideWithValue(FakeLocationClient()),
      ],
      child: const SpeedyGoApp(),
    );
  }

  testWidgets('mocked home search storefront product and back', (tester) async {
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [cafeStorefront()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
      storefrontDetail: cafeStorefrontDetail(),
      categories: const [
        CatalogCategory(
          categoryId: drinksCategoryId,
          name: 'Boissons',
          sortOrder: 1,
        ),
      ],
      products: CatalogPage(items: [espresso()], limit: 50, offset: 0, total: 1),
      productDetail: espressoDetail(),
      searchHits: CatalogPage(
        items: [
          CatalogSearchHit.product(
            product: espresso(),
            storefront: cafeStorefront(),
          ),
          CatalogSearchHit.storefront(cafeStorefront()),
        ],
        limit: 50,
        offset: 0,
        total: 2,
      ),
    );

    await tester.pumpWidget(mockedApp(catalog));
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsOneWidget);
    await shot('mocked-populated-home');

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'esp');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Espresso'), findsOneWidget);
    await shot('mocked-populated-search');

    await tester.tap(find.text('Espresso'));
    await tester.pumpAndSettle();
    expect(find.textContaining(AppStrings.customizeProduct), findsWidgets);
    await shot('mocked-populated-product-from-search');

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Café Central'));
    await tester.pumpAndSettle();
    expect(find.text('Boissons'), findsOneWidget);
    await shot('mocked-populated-storefront');

    await tester.tap(find.text('Espresso'));
    await tester.pumpAndSettle();
    expect(find.text(MoneyFormat.dzd('1200')), findsWidgets);
    await shot('mocked-populated-product');
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsOneWidget);
  });
}
