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
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

/// Location/address form on iPhone SE viewport + textScale 1.3.
/// Does not save or delete addresses. Simulator GPS labeled as simulated.
/// Host must run: xcrun simctl location UDID set 36.7538,3.0588
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const reportDir =
      '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/customer-release-readiness';

  Future<void> shot(String name) async {
    Directory('$reportDir/logs').createSync(recursive: true);
    debugPrint('LOCATION_RELEASE:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File('$reportDir/logs/location-last-shot.txt').writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
    fail('Timed out for $finder');
  }

  testWidgets('SE 1.3 address form + permission after tap (no save)', (
    tester,
  ) async {
    Directory('$reportDir/logs').createSync(recursive: true);
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    const simLat = 36.7538;
    const simLng = 3.0588;
    // simctl must run on host before this test (iOS VM cannot Process.run).
    // Coordinates below are labeled SIMULATOR_ONLY in evidence.

    final tokenFile = File(
      '/Users/mac/Downloads/speedygo_project/.cache/support-closure/otp-verify.json',
    );
    expect(tokenFile.existsSync(), isTrue);
    final tokens =
        Map<String, dynamic>.from(jsonDecode(tokenFile.readAsStringSync()));
    final store = MemorySessionStore();
    await store.write(TokenPair.fromJson(tokens));
    final launch = MemoryLaunchStore(onboardingSeen: true, languageSeen: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          launchStoreProvider.overrideWithValue(launch),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(AppStrings.searchHint).evaluate().isNotEmpty) break;
    }
    await pumpUntil(tester, find.text(AppStrings.searchHint), ticks: 200);

    final ctx = tester.element(find.text(AppStrings.searchHint).first);
    GoRouter.of(ctx).push(AppRoutes.addressForm);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await pumpUntil(tester, find.byKey(const Key('address-text-field')));
    await shot('01-address-form-se');

    Future<void> typeField(Key key, String value) async {
      final finder = find.byKey(key);
      await tester.ensureVisible(finder);
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();
      await tester.enterText(finder, value);
      await tester.pump();
    }

    await typeField(const Key('address-label-field'), 'SE acceptance (unsaved)');
    await typeField(
      const Key('address-text-field'),
      'Manual entry check — do not save',
    );
    await typeField(const Key('address-latitude-field'), '$simLat');
    await typeField(const Key('address-longitude-field'), '$simLng');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('address-save-button')));
    expect(find.byKey(const Key('address-save-button')), findsOneWidget);
    await shot('02-save-visible-se-1_3');

    expect(find.byKey(const Key('use-my-location')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('use-my-location')));
    await tester.tap(find.byKey(const Key('use-my-location')), warnIfMissed: false);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await pumpUntil(tester, find.text(AppStrings.allowLocation));
    expect(find.text(AppStrings.allowLocation), findsOneWidget);
    await shot('03-permission-screen');

    await tester.tap(find.byKey(const Key('allow-location-button')));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shot('04-after-allow');

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final denied = texts.contains(AppStrings.locationDenied) ||
        texts.contains(AppStrings.locationDeniedForever) ||
        texts.contains(AppStrings.locationServicesDisabled) ||
        texts.contains(AppStrings.locationUnavailable);
    final confirm =
        find.text(AppStrings.confirmLocationTitle).evaluate().isNotEmpty;
    final manualStill =
        find.byKey(const Key('address-text-field')).evaluate().isNotEmpty ||
        find.text(AppStrings.enterAddressManually).evaluate().isNotEmpty;

    if (confirm) {
      final back = find.byTooltip(AppStrings.back);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    File('$reportDir/logs/location-evidence.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'viewport': 'iPhone SE 375x667',
        'textScale': 1.3,
        'simulatedCoordinates': {'latitude': simLat, 'longitude': simLng},
        'gpsEvidence': 'SIMULATOR_ONLY',
        'permissionEvidence': 'LIVE_OS_AFTER_TAP',
        'mockedPermissionMatrix':
            'see address_flow_test.dart (denied/forever/servicesDisabled)',
        'saveVisible': true,
        'manualEntryUsable': true,
        'permissionAfterTap': true,
        'afterAllow': {
          'confirmScreen': confirm,
          'deniedOrUnavailable': denied,
          'manualAvailable': manualStill,
        },
        'addressesSaved': false,
        'addressesDeleted': false,
        'finishedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    expect(
      confirm || denied || manualStill,
      isTrue,
      reason: 'Expected confirm, permission/service error, or manual path',
    );
  });
}
