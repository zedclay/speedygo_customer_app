import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/search_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/storefront_detail_screen.dart';
import 'package:speedygo_customer_app/features/favorites/presentation/favorites_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_copy.dart';
import 'package:speedygo_customer_app/features/promotions/presentation/promotions_list_screen.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';
import '../home/home_promo_banner_test.dart';

void main() {
  testWidgets('home banner opens promotions and copy does not navigate', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(items: [fixedPromo(), ratePromo()]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePromoBanner), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.copyPromoCode));
    await tester.pump();
    expect(copied, 'DEMO150');
    expect(find.text(AppStrings.promoCodeCopied), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(PromotionsListScreen), findsNothing);

    await tester.tap(find.text(PromotionCopy.headline(fixedPromo())));
    await tester.pumpAndSettle();
    expect(find.byType(PromotionsListScreen), findsOneWidget);
    expect(find.text(AppStrings.promotionsTitle), findsOneWidget);
    expect(find.text('DEMO150'), findsWidgets);

    await tester.tap(find.text(AppStrings.promotionsPercentChip));
    await tester.pumpAndSettle();
    expect(find.text('SAVE10'), findsOneWidget);
    expect(find.text('DEMO150'), findsNothing);

    await tester.tap(find.text(AppStrings.promotionsFixedChip));
    await tester.pumpAndSettle();
    expect(find.text('DEMO150'), findsOneWidget);
    expect(find.text('SAVE10'), findsNothing);

    expect(find.text(AppStrings.tabHome), findsWidgets);
    expect(find.text(AppStrings.tabSearch), findsWidgets);

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('search idle recents, results tabs, and query clear', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [cafeStorefront()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
      verticals: const [
        CommerceVertical(
          id: '11111111-1111-4111-8111-111111111111',
          slug: 'restaurants',
          name: 'Restaurants',
          iconKey: 'restaurant',
          sortOrder: 1,
        ),
      ],
      searchHits: CatalogPage(
        items: [
          CatalogSearchHit.storefront(cafeStorefront()),
          CatalogSearchHit.product(
            product: espresso(),
            storefront: cafeStorefront(),
          ),
        ],
        limit: 50,
        offset: 0,
        total: 2,
      ),
    );

    await tester.pumpWidget(
      readyApp(
        catalog: catalog,
        promotions: FakePromotionsClient(items: [fixedPromo()]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text(AppStrings.searchSuggestions), findsOneWidget);
    expect(find.text(AppStrings.searchPopularCategories), findsOneWidget);
    expect(find.text(AppStrings.searchOfferOfDay), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search-query-field')), 'ca');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-result-count')), findsOneWidget);
    expect(find.text('Café Central'), findsWidgets);
    expect(catalog.lastSearchQuery?.hitType, 'STOREFRONT');

    await tester.tap(find.text(AppStrings.searchProductsTab));
    await tester.pumpAndSettle();
    expect(catalog.lastSearchQuery?.hitType, 'PRODUCT');
    expect(find.text('Espresso'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-filters-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search-filter-open-now')));
    await tester.pumpAndSettle();
    expect(catalog.lastSearchQuery?.openNow, isTrue);

    await tester.tap(find.byKey(const Key('search-clear-query')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchRecent), findsOneWidget);
    expect(find.text('ca'), findsOneWidget);

    catalog.searchCount = 0;
    await tester.tap(find.byKey(const Key('search-recent-ca')));
    await tester.pumpAndSettle();
    expect(catalog.lastSearchQ, 'ca');
    expect(catalog.searchCount, greaterThan(0));
    expect(find.byKey(const Key('search-result-count')), findsOneWidget);
    expect(find.text(AppStrings.searchMerchantsTab), findsOneWidget);
    expect(find.text(AppStrings.searchProductsTab), findsOneWidget);
    expect(find.text('Café Central'), findsWidgets);

    await tester.tap(find.text(AppStrings.searchProductsTab));
    await tester.pumpAndSettle();
    expect(catalog.lastSearchQuery?.hitType, 'PRODUCT');

    await tester.tap(find.byKey(const Key('search-clear-query')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchRecent), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-clear-recents')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchRecent), findsNothing);
  });

  testWidgets('promotions from search keep the tab bar and search state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
          searchHits: CatalogPage(
            items: [CatalogSearchHit.storefront(cafeStorefront())],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(items: [fixedPromo(), ratePromo()]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await tester.tap(find.text(PromotionCopy.headline(fixedPromo())));
    await tester.pumpAndSettle();
    expect(find.byType(PromotionsListScreen), findsOneWidget);
    expect(find.text(AppStrings.tabHome), findsWidgets);
    expect(find.text(AppStrings.tabSearch), findsWidgets);

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-query-field')), 'ca');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-result-count')), findsOneWidget);

    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PromotionCopy.headline(fixedPromo())));
    await tester.pumpAndSettle();
    expect(find.byType(PromotionsListScreen), findsOneWidget);
    expect(find.text(AppStrings.tabHome), findsWidgets);

    await tester.tap(find.text(AppStrings.tabSearch));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byKey(const Key('search-result-count')), findsOneWidget);
    expect(find.text('ca'), findsWidgets);
  });

  testWidgets('favorites persist per account and keep profile tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final favorites = FakeFavoritesClient(
      branchIds: {cafeBranchId},
      branches: [cafeStorefront()],
    );
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
          storefrontDetail: cafeStorefrontDetail(),
        ),
        favorites: favorites,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-favorites')));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.text('Café Central'), findsOneWidget);
    expect(find.text(AppStrings.favoritesMoreTitle), findsOneWidget);
    expect(find.text(AppStrings.tabProfile), findsWidgets);
    expect(find.text(AppStrings.favoritesOutOfZone), findsNothing);

    await tester.tap(find.text(AppStrings.searchProductsTab));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.favoritesEmpty), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-hub')), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-favorites')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.searchMerchantsTab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Café Central'));
    await tester.pumpAndSettle();
    expect(find.byType(StorefrontDetailScreen), findsOneWidget);
  });

  testWidgets('favorites show live outside and unknown coverage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final favorites = FakeFavoritesClient(
      branchIds: {cafeBranchId},
      branches: [
        cafeStorefront(
          coverage: const DeliveryCoverage(
            inCoverage: false,
            zoneCount: 0,
            reason: 'OUTSIDE',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        favorites: favorites,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-favorites')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.favoritesOutOfZone), findsOneWidget);
    expect(find.text(AppStrings.tabProfile), findsWidgets);
  });

  testWidgets('favorite write failure rolls back and does not claim save', (
    tester,
  ) async {
    final favorites = FakeFavoritesClient(
      writeError: ApiException(AppStrings.favoritesSaveError),
    );
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
          searchHits: CatalogPage(
            items: [CatalogSearchHit.storefront(cafeStorefront())],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        favorites: favorites,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-query-field')), 'ca');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.favoritesSaveError), findsOneWidget);
    expect(favorites.branchIds, isEmpty);
  });

  testWidgets('arabic promotions and search strings bind', (tester) async {
    AppStrings.bind(AppLocale.arabic);
    addTearDown(() => AppStrings.bind(AppLocale.french));
    expect(AppStrings.promotionsTitle, isNot(contains('Promotions')));
    expect(AppStrings.searchMerchantsTab, isNotEmpty);
    expect(AppStrings.favoritesTitle, isNotEmpty);
  });
}
