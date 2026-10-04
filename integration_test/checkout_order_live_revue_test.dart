import 'dart:convert';
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

/// Live Revue COD order against 127.0.0.1:3000 / speedygo_dev.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const merchandiseMinor = '1400';
  const deliveryMinor = '500';
  const payableMinor = '1900';

  Future<void> shot(String name) async {
    debugPrint('LIVE_ORDER_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    Directory('/Users/mac/Downloads/speedygo_project/.cache/live-order-success')
        .createSync(recursive: true);
    File(
      '/Users/mac/Downloads/speedygo_project/.cache/live-order-success/last-shot.txt',
    ).writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int ticks = 80,
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
      final onHome =
          find.text(AppStrings.searchHint).evaluate().isNotEmpty &&
          find.text(AppStrings.addressPickerTitle).evaluate().isEmpty;
      if (onHome) {
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
          find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text(AppStrings.searchHint).evaluate().isNotEmpty &&
        find.text(AppStrings.phoneTitle).evaluate().isEmpty) {
      await popToShell(tester);
      expect(find.text(AppStrings.searchHint), findsWidgets);
      return;
    }
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
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
    await tester.enterText(
      find.byType(TextField),
      found!.readAsStringSync().trim(),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
    await tester.pumpAndSettle();
    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
    await popToShell(tester);
    expect(find.text(AppStrings.searchHint), findsWidgets);
  }

  Future<void> ensureRevueCheckoutAddress(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('home-address-chip')));
    await tester.pumpAndSettle();
    final labeled = find.text('Revue checkout Hydra');
    if (labeled.evaluate().isNotEmpty) {
      await tester.tap(labeled.first);
      await tester.pumpAndSettle();
    }
    await popToShell(tester);
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
    await pumpUntil(tester, find.text('Espresso Demo'));
    expect(find.text('Espresso Demo'), findsWidgets);
    await tester.tap(find.text('Espresso Demo').first);
    await tester.pumpAndSettle();
  }

  Future<void> prepareEspressoCart(WidgetTester tester) async {
    await openEspressoFromSearch(tester);
    await tester.tap(find.byKey(const Key('customize-product-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('option-0d00c070-d000-7000-8000-000000000032')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-to-cart-button')));
    await tester.pumpAndSettle();
    if (find.text(AppStrings.viewCart).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.viewCart));
      await tester.pumpAndSettle();
    } else {
      final cartIcon = find.byIcon(Icons.shopping_cart_outlined);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon.last);
      } else {
        await tester.tap(find.byIcon(Icons.shopping_bag_outlined).last);
      }
      await tester.pumpAndSettle();
    }
    if (find.text(MoneyFormat.dzd(merchandiseMinor)).evaluate().isEmpty &&
        find.text(AppStrings.clearCart).evaluate().isNotEmpty) {
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
      if (find.text(AppStrings.viewCart).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.viewCart));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text(AppStrings.cartTitle), findsOneWidget);
    expect(find.text(MoneyFormat.dzd(merchandiseMinor)), findsWidgets);
  }

  testWidgets('Revue COD order — review to awaiting merchant confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await prepareEspressoCart(tester);
    await shot('01-cart');

    await tester.tap(find.byKey(const Key('checkout-review-cta')));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.byKey(const Key('checkout-totals')));
    await scrollReview(tester, find.byKey(const Key('checkout-totals')));
    expect(find.text(MoneyFormat.dzd(payableMinor)), findsWidgets);
    await shot('02-review');

    await tester.tap(find.byKey(const Key('checkout-payment-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checkout-method-cod')));
    await tester.pumpAndSettle();
    await shot('03-cod');

    final placeOrder = find.byKey(const Key('checkout-place-order'));
    expect(tester.widget<FilledButton>(placeOrder).onPressed, isNotNull);
    await tester.tap(placeOrder);
    for (var i = 0; i < 120; i++) {
      final confirmed =
          find.text(AppStrings.orderConfirmationSent).evaluate().isNotEmpty;
      final pending = find
          .text(AppStrings.orderSubmissionPendingVerification)
          .evaluate()
          .isNotEmpty;
      if (confirmed || pending) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    await shot('04-after-submit');
    if (find.text(AppStrings.orderConfirmationSent).evaluate().isEmpty) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .where((t) => t.trim().isNotEmpty)
          .take(40)
          .toList();
      debugPrint('LIVE_ORDER_AFTER_SUBMIT:$texts');
      fail('Order confirmation not shown. Visible: $texts');
    }
    expect(find.text(AppStrings.orderConfirmationTitle), findsOneWidget);
    await shot('04-confirmation');

    expect(find.text(AppStrings.orderConfirmationSent), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmationAwaitingMerchant), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmationNoPaymentCollected), findsOneWidget);

    final reference = tester
        .widget<Text>(find.byKey(const Key('order-confirmation-reference')))
        .data!;
    expect(reference.startsWith('sgo_'), isTrue);

    await tester.tap(find.byKey(const Key('order-confirmation-detail')));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text(AppStrings.orderDetailTitle));
    await shot('05-detail');

    expect(find.text(AppStrings.orderStatusPendingAcceptance), findsOneWidget);
    expect(find.text(MoneyFormat.dzd(payableMinor)), findsWidgets);

    const reportPath =
        '/Users/mac/Downloads/speedygo_project/.cache/live-order-success/report.json';
    File(reportPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'note': 'See LIVE_ORDER_REPORT debug line for API-backed status',
        'publicReference': reference,
        'expectedPayableMinor': payableMinor,
        'expectedMerchandiseMinor': merchandiseMinor,
        'expectedDeliveryMinor': deliveryMinor,
        'paymentMethod': 'COD',
      }),
    );
    debugPrint(
      'LIVE_ORDER_REPORT:${jsonEncode({'publicReference': reference})}',
    );
  });
}
