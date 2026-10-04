import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';

import '../test/helpers/catalog_fixtures.dart';
import '../test/helpers/fakes.dart';

Uint8List _demoCoverBytes() {
  for (final path in [
    '/tmp/speedygo-home-categories/live/api-cover.png',
    '/tmp/speedygo-demo-cover.png',
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsBytesSync();
    }
  }
  return Uint8List.fromList(const [
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xde, 0x00, 0x00, 0x00,
    0x0c, 0x49, 0x44, 0x41, 0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
    0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d, 0xb4, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
  ]);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    debugPrint('MOCK_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  testWidgets('mocked home categories and cover', (tester) async {
    const coverPath = '/customer/branches/$cafeBranchId/cover';
    final coverBytes = _demoCoverBytes();
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          launchStoreProvider.overrideWithValue(
            MemoryLaunchStore(onboardingSeen: true, languageSeen: true),
          ),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
          authApiProvider.overrideWithValue(FakeAuthClient()),
          customerApiProvider.overrideWithValue(
            FakeCustomerClient()
              ..meResult = const CustomerMe(
                customerProfileExists: true,
                profileComplete: true,
                addressReady: false,
                profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
              ),
          ),
          catalogApiProvider.overrideWithValue(
            FakeCatalogClient(
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
                  slug: 'desserts',
                  name: 'Desserts',
                  iconKey: 'icecream',
                  sortOrder: 1,
                ),
              ],
              storefronts: CatalogPage(
                items: [cafeStorefront(coverImageUrl: coverPath)],
                limit: 50,
                offset: 0,
                total: 1,
              ),
            ),
          ),
          ordersApiProvider.overrideWithValue(FakeOrdersClient()),
          ratingsApiProvider.overrideWithValue(FakeRatingsClient()),
          addressApiProvider.overrideWithValue(FakeAddressClient()),
          addressSelectionStoreProvider.overrideWithValue(
            MemoryAddressSelectionStore(),
          ),
          locationClientProvider.overrideWithValue(FakeLocationClient()),
          navPreviewEnabledProvider.overrideWith(
            () => NavPreviewFlag(initial: false),
          ),
          coverImageBytesProvider.overrideWith((ref, path) async => coverBytes),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeBottomBar), findsOneWidget);
    expect(find.text(AppStrings.categories), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('Café Central'), findsOneWidget);

    await tester.ensureVisible(find.text('Café Central'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('authenticated-cover-image')), findsOneWidget);
    await shot('mock-home-categories');

    await tester.tap(find.text('Restaurants'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Café Central'));
    await tester.pumpAndSettle();
    await shot('mock-home-category-filtered');

    await tester.tap(find.byKey(const ValueKey(cafeBranchId)));
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsWidgets);
    expect(find.byKey(const Key('authenticated-cover-image')), findsOneWidget);
    await shot('mock-storefront-cover');
  });
}
