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

/// Browse existing Revue COD order. Does not POST /customer/orders.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const orderId = '01a0877e-2f9c-725c-9bf6-811b0430e165';
  const publicReference = 'sgo_01a0877e2f9c7018973207d62d5e3443';
  const payableMinor = '1900';
  final shotDir = Directory(
    '/Users/mac/Downloads/speedygo_project/.cache/cod-closure',
  );

  Future<void> shot(String name) async {
    shotDir.createSync(recursive: true);
    debugPrint('COD_CLOSURE_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File('${shotDir.path}/last-shot.txt').writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 700));
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

  Future<void> ensureRevueSession(WidgetTester tester) async {
    await settleHome(tester);
    if (find.text(AppStrings.searchHint).evaluate().isNotEmpty &&
        find.text(AppStrings.phoneTitle).evaluate().isEmpty) {
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
    expect(found, isNotNull, reason: 'OTP capture file missing');
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
    await pumpUntil(tester, find.text(AppStrings.searchHint));
  }

  testWidgets('Commandes → existing COD order detail → Back', (tester) async {
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
    await ensureRevueSession(tester);
    await shot('01-home');

    await tester.tap(find.text(AppStrings.tabOrders));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text(publicReference), ticks: 80);
    expect(find.text(publicReference), findsOneWidget);
    expect(find.text(AppStrings.orderStatusPendingAcceptance), findsWidgets);
    await shot('02-orders-list');

    await tester.tap(find.byKey(const Key('order-list-tile-$orderId')));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text(AppStrings.orderDetailTitle));
    expect(find.textContaining(publicReference), findsWidgets);
    // Detail combines label + status in one Text (not bare status string).
    expect(
      find.textContaining(AppStrings.orderStatusPendingAcceptance),
      findsWidgets,
    );
    expect(find.textContaining(AppStrings.orderPaymentCod), findsWidgets);
    expect(find.byKey(const Key('order-detail-awaiting-merchant')), findsOneWidget);
    expect(find.byKey(const Key('order-detail-no-payment')), findsOneWidget);
    expect(find.text(MoneyFormat.dzd(payableMinor)), findsWidgets);
    await shot('03-order-detail');

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text(publicReference), findsOneWidget);
    await shot('04-orders-after-back');

    File('${shotDir.path}/order-browse-report.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'orderId': orderId,
        'publicReference': publicReference,
        'gesturePath': 'Commandes → detail → Back',
        'createdNewOrder': false,
      }),
    );
  });
}
