import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_controller.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_inbox_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_providers.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';
import 'package:speedygo_customer_app/features/support/application/support_list_controller.dart';

import 'helpers/fakes.dart';
import 'helpers/notification_support_fakes.dart';

Widget app({
  required FakeAuthClient auth,
  required FakeCustomerClient customer,
  MemorySessionStore? store,
  bool onboardingSeen = true,
  bool? languageSeen,
  bool navPreview = false,
  MemoryLaunchStore? launch,
  FakeCatalogClient? catalog,
  FakeOrdersClient? orders,
  FakeRatingsClient? ratings,
  FakePromotionsClient? promotions,
  FakeCartClient? cart,
  FakeCheckoutClient? checkout,
  FakeAddressClient? addresses,
  MemoryAddressSelectionStore? addressSelection,
  FakeLocationClient? location,
  FakeNotificationsClient? notifications,
  FakeSupportClient? support,
  Future<Uint8List?> Function(String path)? coverImageBytes,
}) {
  return ProviderScope(
    overrides: [
      if (coverImageBytes != null)
        coverImageBytesProvider.overrideWith((ref, path) async {
          return coverImageBytes(path);
        }),
      sessionStoreProvider.overrideWithValue(store ?? MemorySessionStore()),
      launchStoreProvider.overrideWithValue(
        launch ??
            MemoryLaunchStore(
              onboardingSeen: onboardingSeen,
              languageSeen: languageSeen,
            ),
      ),
      splashMinDurationProvider.overrideWithValue(Duration.zero),
      splashAnimateProvider.overrideWithValue(false),
      authApiProvider.overrideWithValue(auth),
      customerApiProvider.overrideWithValue(customer),
      catalogApiProvider.overrideWithValue(catalog ?? FakeCatalogClient()),
      ordersApiProvider.overrideWithValue(orders ?? FakeOrdersClient()),
      ratingsApiProvider.overrideWithValue(ratings ?? FakeRatingsClient()),
      promotionsApiProvider.overrideWithValue(
        promotions ?? FakePromotionsClient(),
      ),
      cartApiProvider.overrideWithValue(cart ?? FakeCartClient()),
      checkoutApiProvider.overrideWithValue(checkout ?? FakeCheckoutClient()),
      addressApiProvider.overrideWithValue(
        addresses ?? FakeAddressClient(addresses: customer.meResult.addresses),
      ),
      addressSelectionStoreProvider.overrideWithValue(
        addressSelection ?? MemoryAddressSelectionStore(),
      ),
      locationClientProvider.overrideWithValue(
        location ?? FakeLocationClient(),
      ),
      notificationsApiProvider.overrideWithValue(
        notifications ?? FakeNotificationsClient(),
      ),
      supportApiProvider.overrideWithValue(support ?? FakeSupportClient()),
      navPreviewEnabledProvider.overrideWith(
        () => NavPreviewFlag(initial: navPreview),
      ),
    ],
    child: const SpeedyGoApp(),
  );
}

void main() {
  testWidgets('first launch shows onboarding before phone entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        onboardingSeen: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.languageTitle), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.skip));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('no credentials shows phone entry after splash restore', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(auth: FakeAuthClient(), customer: FakeCustomerClient()),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.text(AppStrings.continueLabel), findsOneWidget);
  });

  testWidgets('continue stays disabled until a valid phone is entered', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(auth: FakeAuthClient(), customer: FakeCustomerClient()),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('phone-number-field')),
      '555123456',
    );
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('phone request navigates to OTP', (tester) async {
    await tester.pumpWidget(
      app(auth: FakeAuthClient(), customer: FakeCustomerClient()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('phone-number-field')),
      '555123456',
    );
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
  });

  testWidgets('OTP cooldown survives returning to the phone screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(auth: FakeAuthClient(), customer: FakeCustomerClient()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('phone-number-field')),
      '555123456',
    );
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    expect(find.textContaining('Renvoyer le code dans'), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.text('555 12 34 56'), findsWidgets);
    expect(find.byKey(const Key('phone-otp-cooldown')), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.text(AppStrings.otpTitle), findsNothing);
  });

  testWidgets('completed profile restore lands on temporary home', (
    tester,
  ) async {
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
      app(auth: FakeAuthClient(), customer: customer, store: store),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeGreeting('Amel Benali')), findsOneWidget);
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.byKey(const Key('home-search-field')), findsOneWidget);
    expect(find.text(AppStrings.landingTitle), findsNothing);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.logoutConfirmAction),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.logoutConfirmAction), findsOneWidget);
  });
}
