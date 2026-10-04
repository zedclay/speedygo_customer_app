import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_design_preview_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_category_strip.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required Size logical,
    double textScale = 1,
    bool preview = false,
    FakeCatalogClient? catalog,
  }) async {
    tester.view.physicalSize = logical * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      readyApp(
        navPreview: preview,
        catalog:
            catalog ??
            FakeCatalogClient(
              storefronts: CatalogPage(
                items: [cafeStorefront()],
                limit: 50,
                offset: 0,
                total: 1,
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('live Home fits iPhone SE and large text', (tester) async {
    await pumpAt(tester, logical: const Size(375, 667), textScale: 1.3);
    expect(find.text(AppStrings.storefrontsTitle), findsOneWidget);
    expect(find.text('Café Central'), findsOneWidget);
    expect(find.text(AppStrings.categories), findsNothing);
    expect(find.text(AppStrings.nearbyMerchants), findsNothing);
    expect(find.byType(HomeBottomBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live Home shows API commerce categories', (tester) async {
    await pumpAt(
      tester,
      logical: const Size(375, 667),
      catalog: FakeCatalogClient(
        verticals: const [
          CommerceVertical(
            id: '11111111-1111-4111-8111-111111111111',
            slug: 'restaurants',
            name: 'Restaurants',
            iconKey: 'restaurant',
            sortOrder: 0,
          ),
        ],
        storefronts: CatalogPage(
          items: [cafeStorefront()],
          limit: 50,
          offset: 0,
          total: 1,
        ),
      ),
    );
    expect(find.text(AppStrings.categories), findsOneWidget);
    expect(find.text(AppStrings.seeAll), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text(AppStrings.storefrontsTitle), findsOneWidget);
  });

  testWidgets('category strip scrolls long labels on iPhone SE', (
    tester,
  ) async {
    await pumpAt(
      tester,
      logical: const Size(375, 667),
      textScale: 1.3,
      catalog: FakeCatalogClient(
        verticals: const [
          CommerceVertical(
            id: '11111111-1111-4111-8111-111111111111',
            slug: 'restaurants',
            name: 'Restaurants',
            iconKey: 'restaurant',
            sortOrder: 0,
          ),
          CommerceVertical(
            id: '22222222-2222-4222-8222-222222222222',
            slug: 'bakeries',
            name: 'Boulangeries artisanales',
            iconKey: 'bakery_dining',
            sortOrder: 1,
          ),
          CommerceVertical(
            id: '33333333-3333-4333-8333-333333333333',
            slug: 'groceries',
            name: 'Épiceries',
            iconKey: 'local_mall',
            sortOrder: 2,
          ),
          CommerceVertical(
            id: '44444444-4444-4444-8444-444444444444',
            slug: 'pharmacies',
            name: 'Pharmacies',
            iconKey: 'medical_services',
            sortOrder: 3,
          ),
          CommerceVertical(
            id: '55555555-5555-4555-8555-555555555555',
            slug: 'desserts',
            name: 'Desserts glacés',
            iconKey: 'icecream',
            sortOrder: 4,
          ),
        ],
        storefronts: CatalogPage(
          items: [cafeStorefront()],
          limit: 50,
          offset: 0,
          total: 1,
        ),
      ),
    );
    expect(find.text('Restaurants'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Desserts glacés'),
      60,
      scrollable: find
          .descendant(
            of: find.byType(HomeCategoryStrip),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Desserts glacés'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('design preview fits iPhone SE and Pro logical sizes', (
    tester,
  ) async {
    await pumpAt(tester, logical: const Size(375, 667), preview: true);
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.homeDesignPreview);
    await tester.pumpAndSettle();
    expect(find.byType(HomeDesignPreviewScreen), findsOneWidget);
    expect(find.text(AppStrings.previewMerchantName), findsOneWidget);
    expect(find.text(AppStrings.activeOrder), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(430, 932) * 2;
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.promoCode), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
