import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';

/// Full-process location permission probe on iPhone SE.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final shotDir = Directory(
    '/Users/mac/Downloads/speedygo_project/.cache/cod-closure',
  );

  Future<void> shot(String name) async {
    shotDir.createSync(recursive: true);
    debugPrint('LOCATION_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File('${shotDir.path}/location-last-shot.txt').writeAsStringSync(name);
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

  Future<void> ensureSignedIn(WidgetTester tester) async {
    for (var i = 0; i < 50; i++) {
      if (find.text(AppStrings.searchHint).evaluate().isNotEmpty ||
          find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.languageTitle).evaluate().isNotEmpty) {
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
    if (find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
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

  testWidgets('Autoriser la localisation after full process start', (
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
    await ensureSignedIn(tester);

    final context = tester.element(find.text(AppStrings.searchHint).first);
    GoRouter.of(context).push(AppRoutes.locationPermission);
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text(AppStrings.allowLocation));
    expect(find.text(AppStrings.allowLocation), findsOneWidget);
    expect(find.text(AppStrings.enterAddressManually), findsOneWidget);
    await shot('location-permission');

    await tester.tap(find.text(AppStrings.allowLocation));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    final texts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .where((t) => t.trim().isNotEmpty)
        .take(60)
        .toList();
    File('${shotDir.path}/location-after-allow.txt').writeAsStringSync(
      texts.join('\n'),
    );
    await shot('location-after-allow');

    final missingPlugin = texts.any(
      (t) => t.contains('MissingPlugin') || t.contains('No implementation'),
    );
    final permissionOrService =
        texts.contains(AppStrings.locationUnavailable) ||
        texts.contains(AppStrings.locationDenied) ||
        texts.contains(AppStrings.locationDeniedForever) ||
        texts.contains(AppStrings.locationServicesDisabled);
    final confirm =
        find.text(AppStrings.confirmLocationTitle).evaluate().isNotEmpty ||
        find.text(AppStrings.confirmLocationAction).evaluate().isNotEmpty;
    final manual =
        find.text(AppStrings.enterAddressManually).evaluate().isNotEmpty ||
        find.text(AppStrings.addressLatitudeField).evaluate().isNotEmpty;

    File('${shotDir.path}/location-verdict.json').writeAsStringSync(
      '{'
      '"missingPlugin":$missingPlugin,'
      '"permissionOrService":$permissionOrService,'
      '"confirmScreen":$confirm,'
      '"manualAvailable":$manual'
      '}\n',
    );

    expect(
      missingPlugin,
      isFalse,
      reason: 'Full rebuild must register geolocator_apple',
    );
    expect(
      confirm || permissionOrService || manual,
      isTrue,
      reason: 'Expected fix, permission/service error, or manual path',
    );
  });
}
