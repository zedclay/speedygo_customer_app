import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';

import 'support/dev_otp_file.dart';

/// Terminal CANCELLED tracking for Revue order. Does not mutate orders.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const orderId = '01a0877e-2f9c-725c-9bf6-811b0430e165';
  const publicReference = 'sgo_01a0877e2f9c7018973207d62d5e3443';
  const revuePhone = '+213550000072';
  final shotDir = Directory(
    '/Users/mac/Downloads/speedygo_project/.cache/tracking-closure',
  );

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int ticks = 120,
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
        .take(40)
        .toList();
    fail('Timed out waiting for $finder. Visible texts: $texts');
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
    final session = container.read(sessionControllerProvider);
    final phone = session.signedInPhone ?? '';
    final name = session.customer?.displayName ?? '';
    final isRevue = phone == revuePhone || name.contains('Revue');
    if (session.phase == SessionPhase.ready && !isRevue) {
      await container.read(sessionControllerProvider.notifier).logout();
      await tester.pumpAndSettle();
    } else if (session.phase == SessionPhase.ready && isRevue) {
      await pumpUntil(tester, find.text(AppStrings.searchHint));
      return;
    }

    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), '550000072');
    await tester.pump();
    final otpCache = speedyGoDevOtpFile();
    final beforeOtp = otpCache.existsSync()
        ? otpCache.readAsStringSync().trim()
        : '';
    final beforeModified = otpCache.existsSync()
        ? otpCache.lastModifiedSync()
        : null;
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    String? code;
    for (var i = 0; i < 60; i++) {
      final candidate = speedyGoDevOtpFile();
      if (candidate.existsSync()) {
        final value = candidate.readAsStringSync().trim();
        final modified = candidate.lastModifiedSync();
        final fresher =
            beforeModified == null || modified.isAfter(beforeModified);
        if (value.length == 6 && (fresher || value != beforeOtp)) {
          code = value;
          break;
        }
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    code ??= beforeOtp.length == 6 ? beforeOtp : null;
    expect(code, isNotNull, reason: 'OTP capture file missing');
    await tester.enterText(find.byType(TextField), code!);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
    await tester.pumpAndSettle();
    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
    await pumpUntil(tester, find.text(AppStrings.searchHint));
  }

  testWidgets('Cancelled Revue order tracking is terminal', (tester) async {
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

    final homeContext = tester.element(find.text(AppStrings.searchHint).first);
    GoRouter.of(homeContext).push(AppRoutes.orderTracking(orderId));
    await tester.pump();
    await pumpUntil(tester, find.byKey(const Key('tracking-stage-title')));
    await pumpUntil(tester, find.text(AppStrings.trackingCancelledBody));

    expect(find.text(AppStrings.orderStatusCancelled), findsWidgets);
    expect(find.text(AppStrings.orderStatusSearchingDriver), findsNothing);
    expect(find.text(AppStrings.trackingCompletedTitle), findsNothing);
    expect(find.text(AppStrings.trackingSearchingBody), findsNothing);

    shotDir.createSync(recursive: true);
    File('${shotDir.path}/live-terminal-report.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'orderId': orderId,
        'publicReference': publicReference,
        'stage': 'cancelled',
        'delivery': 'DELIVERY_NOT_FOUND',
        'mutated': false,
      }),
    );
    try {
      await binding.takeScreenshot('tracking-cancelled-terminal');
    } catch (_) {}
  });
}
