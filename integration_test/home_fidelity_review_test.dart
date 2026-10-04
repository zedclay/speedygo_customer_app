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
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_design_preview_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_active_order_card.dart';

import '../test/helpers/catalog_fixtures.dart';
import '../test/helpers/fakes.dart';
import '../test/helpers/order_fixtures.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> hold(String name) async {
    debugPrint('READY_FOR_CAPTURE:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 4));
  }

  Widget app({
    required bool navPreview,
    FakeCatalogClient? catalog,
    FakeCustomerClient? customer,
    FakeOrdersClient? orders,
    FakeRatingsClient? ratings,
  }) {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final resolvedCustomer =
        customer ??
        (FakeCustomerClient()
          ..meResult = const CustomerMe(
            customerProfileExists: true,
            profileComplete: true,
            addressReady: false,
            profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
          ));
    return ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: true, languageSeen: true),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        splashAnimateProvider.overrideWithValue(false),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        customerApiProvider.overrideWithValue(resolvedCustomer),
        catalogApiProvider.overrideWithValue(
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
        ordersApiProvider.overrideWithValue(orders ?? FakeOrdersClient()),
        ratingsApiProvider.overrideWithValue(ratings ?? FakeRatingsClient()),
        addressApiProvider.overrideWithValue(
          FakeAddressClient(addresses: resolvedCustomer.meResult.addresses),
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

  testWidgets('live-style Home has no fabricated reference blocks', (
    tester,
  ) async {
    await tester.pumpWidget(app(navPreview: false));
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsOneWidget);
    expect(find.text(AppStrings.nearbyMerchants), findsNothing);
    expect(find.text(AppStrings.specialOffer), findsNothing);
    expect(find.text(AppStrings.activeOrder), findsNothing);
    await hold('fidelity-live-home');
  });

  testWidgets('normal Home wires address rating and active order', (
    tester,
  ) async {
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: true,
        profileComplete: true,
        addressReady: true,
        profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
        defaultAddressId: 'addr-home',
        addresses: [
          CustomerAddress(
            id: 'addr-home',
            label: 'Domicile',
            addressText: 'Cité 120 logements',
            isDefault: true,
          ),
        ],
      );
    await tester.pumpWidget(
      app(
        navPreview: false,
        customer: customer,
        orders: FakeOrdersClient(
          orders: orderPage([
            sampleOrder(status: 'ACTIVE', fulfillmentStatus: 'READY'),
          ]),
          delivery: sampleDelivery(status: 'IN_TRANSIT'),
        ),
        ratings: FakeRatingsClient(
          summaries: {merchantId: ratedSummary(average: 4.3)},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Domicile'), findsOneWidget);
    expect(find.text('4.3'), findsOneWidget);
    expect(find.byType(HomeActiveOrderCard), findsOneWidget);
    expect(find.text(AppStrings.orderStatusInTransit), findsOneWidget);
    expect(find.text(AppStrings.categories), findsNothing);
    expect(find.text(AppStrings.promoCode), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await hold('fidelity-live-home-wired');
  });

  testWidgets('design preview shows the full approved Home composition', (
    tester,
  ) async {
    await tester.pumpWidget(app(navPreview: true));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.homeDesignPreview);
    await tester.pumpAndSettle();
    expect(find.byType(HomeDesignPreviewScreen), findsOneWidget);
    expect(find.text(AppStrings.categories), findsOneWidget);
    expect(find.text(AppStrings.promoCode), findsOneWidget);
    expect(find.text(AppStrings.nearbyMerchants), findsOneWidget);
    expect(find.text(AppStrings.activeOrder), findsOneWidget);
    await hold('fidelity-design-preview-home');
  });
}
