import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hours_badge.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

void main() {
  test('hours badge distinguishes unconfigured from closed', () {
    expect(
      hoursLabel(
        const StorefrontHours(
          hoursConfigured: false,
          isOpenNow: false,
          timezone: 'Africa/Algiers',
        ),
      ),
      AppStrings.hoursUnconfigured,
    );
    expect(
      hoursLabel(
        const StorefrontHours(
          hoursConfigured: true,
          isOpenNow: false,
          timezone: 'Africa/Algiers',
        ),
      ),
      AppStrings.hoursClosed,
    );
    expect(hoursLabel(openHours), AppStrings.hoursOpen);
  });

  testWidgets('home loads storefronts only and shows empty state', (
    tester,
  ) async {
    final catalog = FakeCatalogClient();
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.storefrontsEmpty), findsOneWidget);
    expect(find.text(AppStrings.refresh), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsWidgets);
    expect(find.text(AppStrings.nearbyMerchants), findsNothing);
    expect(find.text(AppStrings.specialOffer), findsNothing);
    expect(find.text(AppStrings.categories), findsNothing);
    expect(find.text(AppStrings.promoCode), findsNothing);
    expect(find.text(AppStrings.activeOrder), findsNothing);
    expect(find.text(AppStrings.previewAddress), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(HomeBottomBar), findsOneWidget);
    expect(catalog.listCount, 1);
    expect(catalog.productListCount, 0);
    expect(catalog.getProductCount, 0);
  });

  testWidgets('home error can be retried', (tester) async {
    final catalog = FakeCatalogClient(
      listError: const NetworkException(AppStrings.offline, code: 'NETWORK'),
    );
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.offline), findsOneWidget);
    catalog.listError = null;
    catalog.storefronts = CatalogPage(
      items: [cafeStorefront()],
      limit: 50,
      offset: 0,
      total: 1,
    );
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsOneWidget);
  });

  testWidgets('home search storefront product and back keep branchId', (
    tester,
  ) async {
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
      products: CatalogPage(
        items: [espresso()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
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
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'esp');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text(AppStrings.searchProducts), findsOneWidget);
    expect(find.text(AppStrings.searchStorefronts), findsOneWidget);
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text(MoneyFormat.dzd('1200')), findsWidgets);

    await tester.tap(find.text('Espresso'));
    await tester.pumpAndSettle();
    expect(find.textContaining(AppStrings.customizeProduct), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('customize-product-button')),
          )
          .onPressed,
      isNotNull,
    );
    expect(catalog.getProductCount, 1);

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text('esp'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    final cafeCard = find.byKey(const ValueKey(cafeBranchId));
    await tester.ensureVisible(cafeCard);
    await tester.pumpAndSettle();
    await tester.tap(cafeCard);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.closedBrowseHint), findsNothing);
    expect(find.text('Boissons'), findsOneWidget);
    await tester.tap(find.text('Espresso'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-customize-card')), findsOneWidget);
    expect(find.textContaining(AppStrings.customizeProduct), findsWidgets);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsOneWidget);
  });

  testWidgets('home shows charger plus and keeps order after load more', (
    tester,
  ) async {
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [
          cafeStorefront(branchName: 'Alpha Cafe'),
          cafeStorefront(
            branchId: 'aaaaaaaa-aaaa-4aaa-8aaa-000000000002',
            branchName: 'Beta Cafe',
          ),
          cafeStorefront(
            branchId: 'aaaaaaaa-aaaa-4aaa-8aaa-000000000003',
            branchName: 'Gamma Cafe',
          ),
        ],
        limit: 2,
        offset: 0,
        total: 3,
      ),
      testPageCap: 2,
    );
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    expect(find.text('Alpha Cafe'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Beta Cafe'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Beta Cafe'), findsOneWidget);
    expect(find.text('Gamma Cafe'), findsNothing);
    await tester.scrollUntilVisible(
      find.text(AppStrings.loadMore),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.loadMore), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, AppStrings.loadMore));
    await tester.pumpAndSettle();
    expect(find.text('Alpha Cafe'), findsOneWidget);
    expect(find.text('Gamma Cafe'), findsOneWidget);
    expect(find.text(AppStrings.loadMore), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Gamma Cafe'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final card = tester.getRect(find.text('Gamma Cafe'));
    final nav = tester.getRect(find.byType(HomeBottomBar));
    expect(card.bottom, lessThanOrEqualTo(nav.top + 0.5));
  });

  testWidgets('nav product route stays local and does not call the API', (
    tester,
  ) async {
    final catalog = FakeCatalogClient(productDetail: espressoDetail());
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(HomeScreen)))
        .go(AppRoutes.product(AppRoutes.navProduct));
    await tester.pumpAndSettle();
    expect(catalog.getProductCount, 0);
  });

  testWidgets('empty storefront distinguishes unfiltered and category copy', (
    tester,
  ) async {
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
    );
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    final cafeCard = find.byKey(const ValueKey(cafeBranchId));
    await tester.ensureVisible(cafeCard);
    await tester.pumpAndSettle();
    await tester.tap(cafeCard);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.productsEmptyUnfiltered), findsOneWidget);
    expect(find.text(AppStrings.productsEmpty), findsNothing);
    await tester.tap(find.text('Boissons'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.productsEmpty), findsOneWidget);
    expect(find.text(AppStrings.productsEmptyUnfiltered), findsNothing);
  });

  testWidgets('hours badge moves below a long storefront name', (tester) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [
          cafeStorefront(
            branchName: 'DEMO Cover Hydra Restaurant',
            hours: const StorefrontHours(
              hoursConfigured: false,
              isOpenNow: false,
              timezone: 'Africa/Algiers',
            ),
          ),
        ],
        limit: 50,
        offset: 0,
        total: 1,
      ),
    );
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    final name = tester.getRect(find.text('DEMO Cover Hydra Restaurant'));
    final badge = tester.getRect(find.text(AppStrings.hoursUnconfigured));
    expect(badge.top, greaterThanOrEqualTo(name.bottom - 1));
    expect(name.width, greaterThan(200));
  });
}
