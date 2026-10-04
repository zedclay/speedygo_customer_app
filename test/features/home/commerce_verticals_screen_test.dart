import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/storefront_list_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/commerce_vertical_presentation.dart';
import 'package:speedygo_customer_app/features/home/presentation/commerce_verticals_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_category_strip.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

const _restaurantsId = '11111111-1111-4111-8111-111111111111';
const _bakeriesId = '22222222-2222-4222-8222-222222222222';
const _dessertsId = '33333333-3333-4333-8333-333333333333';

FakeCatalogClient _catalog() {
  return FakeCatalogClient(
    verticals: const [
      CommerceVertical(
        id: _restaurantsId,
        slug: 'restaurants',
        name: 'Restaurants',
        iconKey: 'restaurant',
        sortOrder: 0,
      ),
      CommerceVertical(
        id: _bakeriesId,
        slug: 'bakeries',
        name: 'Boulangeries',
        iconKey: 'bakery_dining',
        sortOrder: 1,
      ),
      CommerceVertical(
        id: _dessertsId,
        slug: 'desserts',
        name: 'Desserts',
        iconKey: 'icecream',
        sortOrder: 2,
      ),
    ],
    storefronts: CatalogPage(
      items: [cafeStorefront()],
      limit: 50,
      offset: 0,
      total: 1,
    ),
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required FakeCatalogClient catalog,
  Size logical = const Size(375, 667),
  double textScale = 1,
}) async {
  tester.view.physicalSize = logical * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(readyApp(catalog: catalog));
  await tester.pumpAndSettle();
}

void main() {
  test('presentation helpers preserve slug identity', () {
    final items = [
      const CommerceVertical(
        id: _restaurantsId,
        slug: 'demo-restaurants',
        name: 'Restaurants',
        iconKey: 'restaurant',
        sortOrder: 0,
      ),
      const CommerceVertical(
        id: _dessertsId,
        slug: 'demo-desserts',
        name: 'Desserts',
        iconKey: 'icecream',
        sortOrder: 1,
      ),
    ];
    expect(featuredRestaurantsVertical(items)?.id, _restaurantsId);
    expect(explorerVerticals(items).single.slug, 'demo-desserts');
    expect(commerceVerticalSubtitle('demo-desserts'), isNotNull);
    expect(commerceVerticalSubtitle('unknown-slug'), isNull);
    expect(filterVerticalsByQuery(items, 'dess').single.name, 'Desserts');
    expect(resolvedCommerceIconKey('grocery'), 'local_mall');
    expect(resolvedCommerceIconKey('pharmacy'), 'medical_services');
    expect(resolvedCommerceIconKey('cake'), 'icecream');
    expect(
      resolvedCommerceIconKey('category', slug: 'pharmacies'),
      'medical_services',
    );
  });

  testWidgets('Tout voir opens redesigned categories inside tab shell', (
    tester,
  ) async {
    final catalog = _catalog();
    await _pumpHome(tester, catalog: catalog);
    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();

    expect(find.byType(CommerceVerticalsScreen), findsOneWidget);
    expect(find.text(AppStrings.allCategoriesTitle), findsOneWidget);
    expect(find.text(AppStrings.categoriesExploreHeading), findsOneWidget);
    expect(find.text(AppStrings.categoriesSearchHint), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('categories-search-field')))
          .autofocus,
      isFalse,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('categories-search-field')))
          .focusNode
          ?.hasFocus,
      isFalse,
    );
    expect(find.byType(HomeBottomBar), findsOneWidget);
    expect(find.text(AppStrings.tabHome), findsWidgets);
    expect(find.byKey(const Key('categories-feature-$_restaurantsId')), findsOneWidget);
    expect(find.text('Desserts'), findsOneWidget);
    expect(find.text('Pâtisseries'), findsNothing);
    expect(find.text('Supermarchés'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category search filters locally', (tester) async {
    await _pumpHome(tester, catalog: _catalog());
    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('categories-search-field')),
      'Boul',
    );
    await tester.pumpAndSettle();

    expect(find.text('Boulangeries'), findsOneWidget);
    expect(find.text('Desserts'), findsNothing);
    expect(find.byKey(const Key('categories-feature-$_restaurantsId')), findsNothing);
  });

  testWidgets('category tap opens results with verticalId and keeps Home filter', (
    tester,
  ) async {
    final catalog = _catalog();
    await _pumpHome(tester, catalog: catalog);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    expect(container.read(selectedCommerceVerticalIdProvider), isNull);

    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('categories-tile-$_bakeriesId')));
    await tester.pumpAndSettle();

    expect(find.byType(StorefrontListScreen), findsOneWidget);
    expect(find.text('Boulangeries'), findsOneWidget);
    expect(catalog.lastStorefrontQuery?.verticalId, _bakeriesId);
    expect(container.read(selectedCommerceVerticalIdProvider), isNull);

    final location = GoRouter.of(
      tester.element(find.byType(StorefrontListScreen)),
    ).state.uri.toString();
    expect(location, contains('verticalId=$_bakeriesId'));
  });

  testWidgets('results pagination preserves vertical filter', (tester) async {
    final all = List.generate(
      3,
      (i) => cafeStorefront(branchId: 'branch-$i', branchName: 'Shop $i'),
    );
    final catalog = FakeCatalogClient(
      verticals: const [
        CommerceVertical(
          id: _bakeriesId,
          slug: 'bakeries',
          name: 'Boulangeries',
          iconKey: 'bakery_dining',
          sortOrder: 0,
        ),
      ],
      storefronts: CatalogPage(
        items: all,
        limit: 2,
        offset: 0,
        total: 3,
      ),
      testPageCap: 2,
    );
    await _pumpHome(tester, catalog: catalog);
    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('categories-tile-$_bakeriesId')));
    await tester.pumpAndSettle();

    expect(catalog.lastStorefrontQuery?.verticalId, _bakeriesId);
    expect(catalog.lastStorefrontQuery?.offset, 0);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StorefrontListScreen)),
    );
    await container
        .read(storefrontResultsControllerProvider(_bakeriesId).notifier)
        .loadMore();
    await tester.pumpAndSettle();
    expect(catalog.lastStorefrontQuery?.verticalId, _bakeriesId);
    expect(catalog.lastStorefrontQuery?.offset, greaterThan(0));
  });

  testWidgets('back from results restores categories search state', (
    tester,
  ) async {
    await _pumpHome(tester, catalog: _catalog());
    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('categories-search-field')),
      'Boul',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('categories-tile-$_bakeriesId')));
    await tester.pumpAndSettle();
    expect(find.byType(StorefrontListScreen), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();

    expect(find.byType(CommerceVerticalsScreen), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('categories-search-field')))
          .controller
          ?.text,
      'Boul',
    );
    expect(find.text('Boulangeries'), findsOneWidget);
    expect(find.text('Desserts'), findsNothing);
  });

  testWidgets('SE layout and large text do not overflow categories', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      catalog: _catalog(),
      logical: const Size(375, 667),
      textScale: 1.3,
    );
    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.allCategoriesTitle), findsOneWidget);
    expect(find.byType(HomeBottomBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('last category tile is reachable after scroll on SE', (
    tester,
  ) async {
    const lastId = '88888888-8888-4888-8888-888888888888';
    final catalog = FakeCatalogClient(
      verticals: [
        ..._catalog().verticals,
        const CommerceVertical(
          id: '44444444-4444-4444-8444-444444444444',
          slug: 'pharmacies',
          name: 'Pharmacies',
          iconKey: 'local_pharmacy',
          sortOrder: 3,
        ),
        const CommerceVertical(
          id: '55555555-5555-4555-8555-555555555555',
          slug: 'groceries',
          name: 'Épiceries',
          iconKey: 'grocery',
          sortOrder: 4,
        ),
        const CommerceVertical(
          id: '66666666-6666-4666-8666-666666666666',
          slug: 'supermarkets',
          name: 'Supermarchés',
          iconKey: 'store',
          sortOrder: 5,
        ),
        const CommerceVertical(
          id: lastId,
          slug: 'review-other',
          name: 'Dernière catégorie',
          iconKey: 'category',
          sortOrder: 6,
        ),
      ],
      storefronts: CatalogPage(
        items: [cafeStorefront()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
    );
    await _pumpHome(tester, catalog: catalog);
    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();

    final last = find.byKey(const Key('categories-tile-$lastId'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(last, findsOneWidget);
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(catalog.lastStorefrontQuery?.verticalId, lastId);
  });

  testWidgets('feature arrow navigates like tiles', (tester) async {
    final catalog = _catalog();
    await _pumpHome(tester, catalog: catalog);
    await tester.tap(find.text(AppStrings.seeAll));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('categories-feature-arrow-$_restaurantsId')),
    );
    await tester.pumpAndSettle();
    expect(catalog.lastStorefrontQuery?.verticalId, _restaurantsId);
    expect(find.text('Restaurants'), findsWidgets);
  });

  test('restaurants route helper encodes verticalId', () {
    expect(
      AppRoutes.restaurantsForVertical(_bakeriesId),
      '/home/categories/results?verticalId=$_bakeriesId',
    );
    expect(
      AppRoutes.homeCategoryResults(_bakeriesId),
      '/home/categories/results?verticalId=$_bakeriesId',
    );
  });
}
