import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/features/promotions/presentation/promotions_list_screen.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

void main() {
  testWidgets('promotions list uses discoverable GET contract', (tester) async {
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
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    GoRouter.of(
      tester.element(find.byType(HomeScreen)),
    ).go(AppRoutes.promotions);
    await tester.pumpAndSettle();
    expect(find.byType(PromotionsListScreen), findsOneWidget);
    expect(find.text(AppStrings.promotionsTitle), findsOneWidget);
    expect(find.text('DEMO150'), findsOneWidget);
    expect(find.text(AppStrings.promotionsCheckoutHint), findsOneWidget);
    expect(find.text(AppStrings.promotionsUnavailable), findsNothing);
    expect(find.text(AppStrings.tabHome), findsWidgets);
    expect(find.text('Dar El Bahia'), findsNothing);
  });
}
