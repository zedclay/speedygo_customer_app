import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_active_order_card.dart';

import 'support/dev_otp_file.dart';

/// Read-only Customer UI acceptance for the completed COD order.
/// Does not create orders, resubmit ratings, or fabricate notifications.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const orderId = '01a0a2d5-70c9-76a9-8a6d-a6a77b54645d';
  const publicReference = 'sgo_01a0a2d570c97b46834e0c23e071634c';
  const payableMinor = '240500';
  const revuePhone = '+213550000072';
  const reportDir =
      '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/cod-lifecycle-acceptance';
  final shotDir = Directory('$reportDir/screenshots');
  final evidence = <String, Object?>{
    'mode': 'LIVE_UI_GESTURE',
    'orderId': orderId,
    'publicReference': publicReference,
    'payableMinor': payableMinor,
    'expectedDzd': MoneyFormat.dzd(payableMinor),
    'createdNewOrder': false,
    'ratingsResubmitted': false,
    'notificationsCreated': false,
  };

  Future<void> shot(String name) async {
    shotDir.createSync(recursive: true);
    debugPrint('COD_COMPLETED_UI:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File('$reportDir/logs/last-shot.txt').writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 500));
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
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .take(50)
        .toList();
    fail('Timed out waiting for $finder. Visible: $texts');
  }

  Future<void> ensureRevueSession(WidgetTester tester) async {
    for (var i = 0; i < 80; i++) {
      if (find.text(AppStrings.searchHint).evaluate().isNotEmpty ||
          find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.languageTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
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

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SpeedyGoApp)),
    );
    var session = container.read(sessionControllerProvider);
    final phone = session.signedInPhone ?? '';
    final name = session.customer?.displayName ?? '';
    final isRevue = phone == revuePhone || name.contains('Revue');
    if (session.phase == SessionPhase.ready && !isRevue) {
      await container.read(sessionControllerProvider.notifier).logout();
      await tester.pumpAndSettle();
      for (var i = 0; i < 40; i++) {
        if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
            find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.skip));
        await tester.pumpAndSettle();
      }
    } else if (session.phase == SessionPhase.ready && isRevue) {
      await pumpUntil(tester, find.text(AppStrings.searchHint));
      evidence['login'] = 'restored_revue_session';
      return;
    }

    // Already on Home without reading as Revue above — treat as signed-in Home.
    if (find.text(AppStrings.searchHint).evaluate().isNotEmpty &&
        find.text(AppStrings.phoneTitle).evaluate().isEmpty) {
      session = container.read(sessionControllerProvider);
      final againPhone = session.signedInPhone ?? '';
      final againName = session.customer?.displayName ?? '';
      if (againPhone == revuePhone || againName.contains('Revue')) {
        evidence['login'] = 'home_already_revue';
        return;
      }
      await container.read(sessionControllerProvider.notifier).logout();
      await tester.pumpAndSettle();
      for (var i = 0; i < 40; i++) {
        if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
            find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.skip));
        await tester.pumpAndSettle();
      }
    }

    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
    await pumpUntil(tester, find.text(AppStrings.phoneTitle), ticks: 80);
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
    expect(found, isNotNull, reason: 'OTP capture blocked — cannot login Revue');
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
    evidence['login'] = 'otp_revue';
  }

  testWidgets(
    'Home → Commandes → completed COD order → payment/ratings read → Back',
    (tester) async {
      Directory('$reportDir/logs').createSync(recursive: true);
      shotDir.createSync(recursive: true);

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

      // Completed order must not own the active-order card (another open order may).
      final activeCards = find.byType(HomeActiveOrderCard);
      if (activeCards.evaluate().isNotEmpty) {
        expect(
          find.descendant(
            of: activeCards,
            matching: find.textContaining(publicReference),
          ),
          findsNothing,
          reason: 'Completed COD must not appear on Home active-order card',
        );
        evidence['activeOrderCard'] =
            'present_but_not_target_completed_order';
      } else {
        evidence['activeOrderCard'] = 'absent';
      }

      await tester.tap(find.text(AppStrings.tabOrders));
      await tester.pumpAndSettle();
      // Default segment is in-progress; completed COD is under Terminées.
      await pumpUntil(tester, find.text(AppStrings.ordersTabCompleted), ticks: 40);
      await tester.tap(find.text(AppStrings.ordersTabCompleted));
      await tester.pumpAndSettle();
      await pumpUntil(tester, find.text(publicReference), ticks: 100);
      expect(find.text(publicReference), findsWidgets);
      expect(find.text(AppStrings.orderStatusCompleted), findsWidgets);
      expect(find.text(MoneyFormat.dzd(payableMinor)), findsWidgets);
      await shot('02-orders-list');

      await tester.tap(find.byKey(const Key('order-list-tile-$orderId')));
      await tester.pumpAndSettle();
      await pumpUntil(tester, find.text(AppStrings.orderDetailTitle));
      expect(find.textContaining(publicReference), findsWidgets);
      expect(
        find.textContaining(AppStrings.orderStatusCompleted),
        findsWidgets,
      );
      expect(find.textContaining(AppStrings.orderPaymentCod), findsWidgets);
      expect(find.text(MoneyFormat.dzd(payableMinor)), findsWidgets);
      await shot('03-order-detail');

      // Server-authoritative COD payment status (read-only).
      if (find.byKey(const Key('order-detail-payment-entry')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('order-detail-payment-entry')));
        await tester.pumpAndSettle();
        await pumpUntil(
          tester,
          find.text(AppStrings.paymentStatusSucceeded),
          ticks: 80,
        );
        expect(find.text(AppStrings.paymentStatusSucceeded), findsWidgets);
        expect(find.textContaining(AppStrings.orderPaymentCod), findsWidgets);
        await shot('04-payment-status');
        await tester.tap(find.byTooltip(AppStrings.back));
        await tester.pumpAndSettle();
        evidence['paymentStatusUi'] = 'SUCCEEDED_Confirmé';
      } else {
        evidence['paymentStatusUi'] = 'payment_entry_missing';
      }

      // Existing ratings — read only, do not resubmit.
      if (find.text(AppStrings.ratingEntry).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text(AppStrings.ratingEntry).first);
        await tester.tap(find.text(AppStrings.ratingEntry).first);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 800));
        final already =
            find.text(AppStrings.ratingAlreadyDone).evaluate().isNotEmpty;
        evidence['ratingsRead'] = already
            ? 'already_done_banner'
            : 'rating_entry_opened';
        await shot('05-ratings-read');
        final back = find.byTooltip(AppStrings.back);
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first);
          await tester.pumpAndSettle();
        }
      } else {
        evidence['ratingsRead'] = 'rating_entry_not_visible';
      }

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      expect(find.text(publicReference), findsWidgets);
      await shot('06-orders-after-back');

      // Existing notifications — inspect only.
      await tester.tap(find.text(AppStrings.tabHome));
      await tester.pumpAndSettle();
      await pumpUntil(tester, find.text(AppStrings.searchHint), ticks: 40);
      if (find.text(AppStrings.tabAlerts).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.tabAlerts));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));
        evidence['notificationsInspected'] = true;
        await shot('07-alerts-existing');
      } else {
        evidence['notificationsInspected'] = false;
      }

      File('$reportDir/logs/completed-order-ui-evidence.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          ...evidence,
          'gesturePath':
              'Home → Commandes → detail → payment/ratings read → Back → Alertes',
          'finishedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    },
  );
}
