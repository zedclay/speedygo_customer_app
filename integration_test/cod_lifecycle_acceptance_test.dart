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

/// Live COD create — Revue +213550000072 on speedygo_dev.
/// Creates at most one order; persists identity under audit/.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const reportDir =
      '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/cod-lifecycle-acceptance';
  const branchName = 'Pharmacie Atlas';
  const productName = 'Crème solaire SPF 50';
  const merchandiseUnitMinor = '120000';
  const merchandiseQty2Minor = '240000';
  const deliveryMinor = '500';
  const payableQty2Minor = '240500';

  Future<void> shot(String name) async {
    debugPrint('COD_ACCEPT_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File('$reportDir/logs/last-shot.txt').writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void persistPartial(Map<String, Object?> data) {
    Directory('$reportDir/logs').createSync(recursive: true);
    final file = File('$reportDir/order-identity.json');
    final existing = file.existsSync()
        ? (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
        : <String, dynamic>{};
    existing.addAll(data);
    existing['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(existing),
    );
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int ticks = 100,
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
    for (var i = 0; i < 60; i++) {
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
    for (var i = 0; i < 10; i++) {
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
    for (var i = 0; i < 40; i++) {
      if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text(AppStrings.searchHint).evaluate().isNotEmpty &&
        find.text(AppStrings.phoneTitle).evaluate().isEmpty) {
      await popToShell(tester);
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
    for (var i = 0; i < 50; i++) {
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
    await pumpUntil(
      tester,
      find.byKey(const Key('home-address-chip')),
      ticks: 80,
    );
    if (find.byKey(const Key('home-address-chip')).evaluate().isEmpty) {
      // Already past address chrome or still loading — do not hard-fail.
      return;
    }
    await tester.ensureVisible(find.byKey(const Key('home-address-chip')));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('home-address-chip')).evaluate().isEmpty) {
      return;
    }
    await tester.tap(
      find.byKey(const Key('home-address-chip')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    final labeled = find.text('Revue checkout Hydra');
    if (labeled.evaluate().isNotEmpty) {
      await tester.ensureVisible(labeled.first);
      await tester.tap(labeled.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    await popToShell(tester);
    await pumpUntil(tester, find.text(AppStrings.searchHint), ticks: 40);
  }

  Future<void> revealOpenNowChip(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      if (find.byKey(const Key('open-now-filter')).evaluate().isNotEmpty ||
          find.text(AppStrings.storefrontsOpenNow).evaluate().isNotEmpty) {
        final target =
            find.byKey(const Key('open-now-filter')).evaluate().isNotEmpty
            ? find.byKey(const Key('open-now-filter'))
            : find.text(AppStrings.storefrontsOpenNow);
        await tester.ensureVisible(target.first);
        await tester.pumpAndSettle();
        return;
      }
      final list = find.byType(Scrollable);
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.first, const Offset(0, -240));
        await tester.pumpAndSettle();
      } else {
        break;
      }
    }
  }

  testWidgets('COD lifecycle — openNow Pharmacie → COD create', (tester) async {
    // Guard: refuse create if prior acceptance already recorded an order.
    final identity = File('$reportDir/order-identity.json');
    if (identity.existsSync()) {
      final prior =
          jsonDecode(identity.readAsStringSync()) as Map<String, dynamic>;
      if (prior['publicReference'] != null || prior['orderId'] != null) {
        fail(
          'Prior order identity present (${prior['publicReference']}). '
          'Refusing duplicate create.',
        );
      }
    }

    Directory('$reportDir/logs').createSync(recursive: true);
    persistPartial({
      'phase': 'start',
      'customerPhone': '+213550000072',
      'intendedBranch': branchName,
      'intendedProduct': productName,
    });

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
    await shot('01-home');

    await revealOpenNowChip(tester);
    final chipFinder =
        find.byKey(const Key('open-now-filter')).evaluate().isNotEmpty
        ? find.byKey(const Key('open-now-filter'))
        : find.text(AppStrings.storefrontsOpenNow);
    expect(chipFinder, findsWidgets);
    await tester.ensureVisible(chipFinder.first);
    await tester.tap(chipFinder.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await pumpUntil(tester, find.text(branchName), ticks: 100);
    expect(find.text(branchName), findsWidgets);
    await shot('02-open-now');

    await tester.tap(find.text(branchName).first);
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text(productName), ticks: 80);
    expect(find.text(productName), findsWidgets);
    await shot('03-storefront');

    await tester.tap(find.text(productName).first);
    await tester.pumpAndSettle();
    await shot('04-product');

    if (find.byKey(const Key('add-to-cart-button')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('add-to-cart-button')));
    } else if (find
        .byKey(const Key('customize-product-button'))
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.byKey(const Key('customize-product-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-to-cart-button')));
    } else {
      fail('No add-to-cart control');
    }
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
    expect(find.text(AppStrings.cartTitle), findsOneWidget);
    expect(find.text(MoneyFormat.dzd(merchandiseUnitMinor)), findsWidgets);
    await shot('05-cart-qty1');

    final qtyPlus = find.byTooltip('Augmenter la quantité');
    expect(qtyPlus, findsWidgets);
    await tester.tap(qtyPlus.first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text(MoneyFormat.dzd(merchandiseQty2Minor)), findsWidgets);
    await shot('06-cart-qty2');

    await tester.tap(find.byKey(const Key('checkout-review-cta')));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.byKey(const Key('checkout-totals')));
    await scrollReview(tester, find.byKey(const Key('checkout-totals')));
    expect(find.text(MoneyFormat.dzd(payableQty2Minor)), findsWidgets);
    await shot('07-review');

    await tester.tap(find.byKey(const Key('checkout-payment-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checkout-method-cod')));
    await tester.pumpAndSettle();
    await shot('08-cod');

    final placeOrder = find.byKey(const Key('checkout-place-order'));
    expect(tester.widget<FilledButton>(placeOrder).onPressed, isNotNull);
    await tester.tap(placeOrder);
    for (var i = 0; i < 150; i++) {
      if (find.text(AppStrings.orderConfirmationSent).evaluate().isNotEmpty ||
          find
              .text(AppStrings.orderSubmissionPendingVerification)
              .evaluate()
              .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    await shot('09-after-submit');

    if (find.text(AppStrings.orderConfirmationSent).evaluate().isEmpty) {
      persistPartial({'phase': 'submit-failed'});
      fail('Order confirmation not shown');
    }

    final reference = tester
        .widget<Text>(find.byKey(const Key('order-confirmation-reference')))
        .data!;
    expect(reference.startsWith('sgo_'), isTrue);

    persistPartial({
      'phase': 'created',
      'publicReference': reference,
      'paymentMethod': 'COD',
      'expectedMerchandiseMinor': merchandiseQty2Minor,
      'expectedDeliveryMinor': deliveryMinor,
      'expectedPayableMinor': payableQty2Minor,
      'branchName': branchName,
      'productName': productName,
      'quantity': 2,
      'promotion': null,
      'mode': 'UI_GESTURE',
    });
    debugPrint('COD_ACCEPT_ORDER_REF:$reference');

    await tester.tap(find.byKey(const Key('order-confirmation-detail')));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text(AppStrings.orderDetailTitle));
    await shot('10-detail');
    expect(find.text(AppStrings.orderStatusPendingAcceptance), findsOneWidget);
  });
}
