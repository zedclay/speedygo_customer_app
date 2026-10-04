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

/// Live UI browse of the synthetic Revue fixture ticket.
/// Writes shot markers for a host-side simctl screenshot watcher.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final shotDir = Directory(
    '/Users/mac/Downloads/speedygo_project/.cache/support-closure',
  );
  final fixtureFile = File('${shotDir.path}/fixture.json');
  final tokenFile = File('${shotDir.path}/otp-verify.json');
  final markerFile = File('${shotDir.path}/shot-marker.txt');
  final ackFile = File('${shotDir.path}/shot-ack.txt');

  List<String> visibleTexts(WidgetTester tester) {
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .take(50)
        .toList();
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int ticks = 160,
  }) async {
    for (var i = 0; i < ticks; i++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('Timed out waiting for $finder. Visible texts: ${visibleTexts(tester)}');
  }

  Future<void> requestHostShot(WidgetTester tester, String name) async {
    if (ackFile.existsSync()) {
      ackFile.deleteSync();
    }
    markerFile.writeAsStringSync(name);
    for (var i = 0; i < 100; i++) {
      if (ackFile.existsSync() &&
          ackFile.readAsStringSync().trim() == name) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Host watcher optional — do not fail the live browse if absent.
  }

  testWidgets('Revue support list detail refresh from fixture', (tester) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(fixtureFile.existsSync(), isTrue, reason: 'API live fixture required');
    expect(tokenFile.existsSync(), isTrue, reason: 'token seed required');
    final fixture =
        Map<String, dynamic>.from(jsonDecode(fixtureFile.readAsStringSync()));
    final tokens =
        Map<String, dynamic>.from(jsonDecode(tokenFile.readAsStringSync()));
    final ticketId = fixture['ticketId']?.toString() ?? '';
    expect(ticketId, isNotEmpty);
    final ticketBody = fixture['body']?.toString() ?? 'Test support Revue';
    final followUp =
        fixture['followUpBody']?.toString() ?? 'Test support Revue follow-up';

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
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text(AppStrings.searchHint), ticks: 200);

    final homeContext = tester.element(find.text(AppStrings.searchHint).first);
    final router = GoRouter.of(homeContext);

    router.go(AppRoutes.supportList);
    await tester.pump();
    await pumpUntil(tester, find.text(AppStrings.supportListTitle));
    await pumpUntil(tester, find.byKey(Key('support-ticket-tile-$ticketId')));
    await requestHostShot(tester, 'support-list');

    await tester.tap(find.byKey(Key('support-ticket-tile-$ticketId')));
    await tester.pump();
    await pumpUntil(tester, find.byKey(const Key('support-detail-reference')));
    expect(find.textContaining(ticketBody), findsWidgets);
    expect(find.textContaining(followUp), findsWidgets);
    await requestHostShot(tester, 'support-detail');

    final refresh = find.byIcon(Icons.refresh);
    await tester.ensureVisible(refresh);
    await tester.tap(refresh, warnIfMissed: false);
    await tester.pump();
    await pumpUntil(tester, find.byKey(const Key('support-detail-reference')));
    expect(find.textContaining(ticketBody), findsWidgets);
    expect(find.textContaining(followUp), findsWidgets);
    await requestHostShot(tester, 'support-confirmed-message');

    router.go(AppRoutes.supportList);
    await tester.pump();
    await pumpUntil(tester, find.byKey(Key('support-ticket-tile-$ticketId')));
    await requestHostShot(tester, 'support-list-after-refresh');

    shotDir.createSync(recursive: true);
    File('${shotDir.path}/live-ui-report.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'ticketId': ticketId,
        'uiCoverage': 'list_detail_refresh',
        'writesThisRun': false,
        'seededSession': true,
      }),
    );
  });
}
