import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';

/// Live Revue Checkout preview against 127.0.0.1:3000 / speedygo_dev.
/// Requires synthetic zone+pricing fixtures
/// (`apps/backend/scripts/dev-checkout-fixtures`).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Espresso Demo 1200 + Double option 200 = 1400 minor (14,00 DZD).
  // Delivery fixture fee 500 minor (5,00 DZD).
  // DEMOHOME150 is FIXED 15000, capped to merchandise → discount 1400, payable 500.
  const merchandiseMinor = '1400';
  const deliveryMinor = '500';
  const payableMinor = '1900';
  const discountMinor = '1400';
  const payableWithPromoMinor = '500';

  Future<void> shot(String name) async {
    debugPrint('LIVE_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File('/Users/mac/Downloads/speedygo_project/.cache/live-shot-name')
        .writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int ticks = 50,
  }) async {
    for (var i = 0; i < ticks; i++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> scrollReview(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleHome(WidgetTester tester) async {
    for (var i = 0; i < 50; i++) {
      if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty) {
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.continueLabel),
      );
      await tester.pumpAndSettle();
    }
    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
  }

  Future<void> popToShell(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      final onPicker =
          find.text(AppStrings.addressPickerTitle).evaluate().isNotEmpty;
      final onForm =
          find.byKey(const Key('address-save-button')).evaluate().isNotEmpty;
      final onHome =
          find.text(AppStrings.searchHint).evaluate().isNotEmpty && !onPicker;
      if (onHome && !onForm) {
        return;
      }
      final back = find.byTooltip(AppStrings.back);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await tester.pumpAndSettle();
        continue;
      }
      if (find.text(AppStrings.tabHome).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.tabHome));
        await tester.pumpAndSettle();
        return;
      }
      break;
    }
  }

  Future<void> loginRevue(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.textContaining('Revue').evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text(AppStrings.searchHint).evaluate().isNotEmpty &&
        find.text(AppStrings.phoneTitle).evaluate().isEmpty &&
        find.textContaining('Revue').evaluate().isEmpty) {
      await tester.tap(find.text(AppStrings.tabProfile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('account-logout')));
      await tester.tap(find.byKey(const Key('account-logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logoutConfirmAction));
      await tester.pumpAndSettle();
    }
    if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), '550000072');
      await tester.pump();
      final otpCache = speedyGoDevOtpFile();
      if (otpCache.existsSync()) {
        otpCache.deleteSync();
      }
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.continueLabel),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.otpTitle), findsOneWidget);
      File? found;
      for (var i = 0; i < 40; i++) {
        final candidate = speedyGoDevOtpFile();
        if (candidate.existsSync() &&
            candidate.readAsStringSync().trim().length == 6) {
          found = candidate;
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(found, isNotNull);
      final code = found!.readAsStringSync().trim();
      expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
      await tester.enterText(find.byType(TextField), code);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
      await tester.pumpAndSettle();
    }
    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
    await popToShell(tester);
    expect(find.text(AppStrings.searchHint), findsWidgets);
  }

  Future<void> ensureRevueCheckoutAddress(WidgetTester tester) async {
    final alreadySelected =
        find.textContaining('Revue checkout').evaluate().isNotEmpty &&
        find.text(AppStrings.addressPickerTitle).evaluate().isEmpty;
    if (alreadySelected &&
        find.text(AppStrings.deliverToUnset).evaluate().isEmpty) {
      return;
    }

    await tester.tap(find.byKey(const Key('home-address-chip')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);

    if (find.byKey(const Key('picker-empty')).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.addAddress));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('address-label-field')),
        'Revue checkout Hydra',
      );
      await tester.enterText(
        find.byKey(const Key('address-text-field')),
        'Revue checkout street',
      );
      await tester.enterText(
        find.byKey(const Key('address-latitude-field')),
        '36.7538',
      );
      await tester.enterText(
        find.byKey(const Key('address-longitude-field')),
        '3.0588',
      );
      await tester.tap(find.byKey(const Key('address-save-button')));
      await tester.pumpAndSettle();
    }

    final labeled = find.text('Revue checkout Hydra');
    if (labeled.evaluate().isNotEmpty) {
      await tester.tap(labeled.first);
      await tester.pumpAndSettle();
    } else {
      final anyRevue = find.textContaining('Revue');
      expect(anyRevue, findsWidgets);
      await tester.tap(anyRevue.first);
      await tester.pumpAndSettle();
    }

    await popToShell(tester);
    expect(find.text(AppStrings.addressPickerTitle), findsNothing);
    expect(find.text(AppStrings.searchHint), findsWidgets);
  }

  Future<void> openEspressoFromSearch(WidgetTester tester) async {
    final searchTab = find.byIcon(Icons.search_outlined);
    if (searchTab.evaluate().isNotEmpty) {
      await tester.tap(searchTab.last);
    } else {
      await tester.tap(find.byIcon(Icons.search).last);
    }
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'espresso');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await pumpUntil(tester, find.text('Espresso Demo'), ticks: 60);
    if (find.text('Espresso Demo').evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text('Espresso Demo'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
    }
    expect(find.text('Espresso Demo'), findsWidgets);
    await tester.tap(find.text('Espresso Demo').first);
    await tester.pumpAndSettle();
  }

  Future<void> clearExistingCartIfAny(WidgetTester tester) async {
    // No dedicated cart tab; leftovers are normalized after opening cart.
  }

  testWidgets('live Revue successful checkout preview with promo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await settleHome(tester);
    await loginRevue(tester);
    await ensureRevueCheckoutAddress(tester);
    await clearExistingCartIfAny(tester);

    await openEspressoFromSearch(tester);
    await tester.tap(find.byKey(const Key('customize-product-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('option-0d00c070-d000-7000-8000-000000000032')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-to-cart-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.viewCart));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cartTitle), findsOneWidget);

    // Prior live runs may have left a larger quantity. Reset to one line ×1.
    if (find.text(MoneyFormat.dzd(merchandiseMinor)).evaluate().isEmpty) {
      await tester.tap(find.text(AppStrings.clearCart));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.clearCart),
        ),
      );
      await tester.pumpAndSettle();
      await popToShell(tester);
      await openEspressoFromSearch(tester);
      await tester.tap(find.byKey(const Key('customize-product-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('option-0d00c070-d000-7000-8000-000000000032')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-to-cart-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.viewCart));
      await tester.pumpAndSettle();
    }
    expect(find.text(MoneyFormat.dzd(merchandiseMinor)), findsWidgets);
    await shot('live-checkout-success-cart');

    await tester.tap(find.byKey(const Key('checkout-review-cta')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.checkoutReviewTitle), findsOneWidget);
    await pumpUntil(tester, find.byKey(const Key('checkout-totals')), ticks: 60);
    expect(find.byKey(const Key('checkout-totals')), findsOneWidget);
    expect(
      find.text(AppStrings.errorForCode('CHECKOUT_ADDRESS_OUTSIDE_ZONE')),
      findsNothing,
    );
    expect(find.textContaining('Revue checkout'), findsWidgets);

    await scrollReview(tester, find.byKey(const Key('checkout-totals')));
    expect(find.byKey(const Key('checkout-merchandise')), findsOneWidget);
    expect(find.byKey(const Key('checkout-delivery')), findsOneWidget);
    expect(find.byKey(const Key('checkout-total')), findsOneWidget);
    expect(find.text(MoneyFormat.dzd(merchandiseMinor)), findsWidgets);
    expect(find.text(MoneyFormat.dzd(deliveryMinor)), findsOneWidget);
    expect(find.text(MoneyFormat.dzd(payableMinor)), findsOneWidget);
    expect(find.byKey(const Key('checkout-discount')), findsNothing);
    await shot('live-checkout-success-review');

    await scrollReview(tester, find.byKey(const Key('checkout-address-card')));
    await tester.ensureVisible(find.byKey(const Key('checkout-address-card')));
    await tester.tap(find.byKey(const Key('checkout-address-card')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);
    await shot('live-checkout-success-address');
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.checkoutReviewTitle), findsOneWidget);

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('checkout-place-order')))
          .onPressed,
      isNull,
    );
    expect(find.text(AppStrings.checkoutPlaceOrderUnavailable), findsOneWidget);

    await scrollReview(tester, find.byKey(const Key('checkout-promo-field')));
    await tester.enterText(
      find.byKey(const Key('checkout-promo-field')),
      'DEMOHOME150',
    );
    await tester.tap(find.byKey(const Key('checkout-apply-promo')));
    await tester.pumpAndSettle();
    await pumpUntil(
      tester,
      find.byKey(const Key('checkout-promo-applied')),
      ticks: 40,
    );
    expect(find.byKey(const Key('checkout-promo-applied')), findsOneWidget);
    expect(find.textContaining('DEMOHOME150'), findsWidgets);
    await scrollReview(tester, find.byKey(const Key('checkout-totals')));
    expect(find.byKey(const Key('checkout-discount')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('checkout-discount'))).data,
      '−${MoneyFormat.dzd(discountMinor)}',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('checkout-delivery'))).data,
      MoneyFormat.dzd(deliveryMinor),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('checkout-total'))).data,
      MoneyFormat.dzd(payableWithPromoMinor),
    );
    // Cap proof: offer is 150 DZD but basket merchandise is only 14 DZD.
    expect(find.text(MoneyFormat.dzd('15000')), findsNothing);
    await shot('live-checkout-success-promo');

    await tester.ensureVisible(find.byKey(const Key('checkout-remove-promo')));
    await tester.tap(find.byKey(const Key('checkout-remove-promo')));
    await tester.pumpAndSettle();
    await pumpUntil(
      tester,
      find.byKey(const Key('checkout-promo-field')),
      ticks: 40,
    );
    expect(find.byKey(const Key('checkout-promo-applied')), findsNothing);
    await scrollReview(tester, find.byKey(const Key('checkout-totals')));
    expect(find.byKey(const Key('checkout-discount')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('checkout-total'))).data,
      MoneyFormat.dzd(payableMinor),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('checkout-delivery'))).data,
      MoneyFormat.dzd(deliveryMinor),
    );
    await shot('live-checkout-success-promo-removed');

    // Cart preserved: still on review with line item visible.
    expect(find.text('Espresso Demo'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('checkout-place-order')))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('Commande confirmée'), findsNothing);
    expect(find.textContaining('commande créée'), findsNothing);
  });
}
