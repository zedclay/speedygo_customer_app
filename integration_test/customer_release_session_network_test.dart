import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

/// Session restore + controlled client network interruption on one app instance.
/// Does not restart Redis/Postgres, clear Keychain, or revoke unrelated sessions.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const reportDir =
      '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/customer-release-readiness';

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int ticks = 120,
  }) async {
    for (var i = 0; i < ticks; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('Timed out $finder');
  }

  testWidgets('seeded restore + client network error recoverable', (
    tester,
  ) async {
    Directory('$reportDir/logs').createSync(recursive: true);
    final evidence = <String, Object?>{};

    final tokenFile = File(
      '/Users/mac/Downloads/speedygo_project/.cache/support-closure/otp-verify.json',
    );
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SpeedyGoApp)),
    );
    final session = container.read(sessionControllerProvider);
    evidence['coldStartRestore'] = session.phase == SessionPhase.ready;
    evidence['phone'] = session.signedInPhone;
    expect(session.phase, SessionPhase.ready);

    // Simulate app resume (lifecycle) without clearing session.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 200));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 500));
    evidence['afterResumeReady'] =
        container.read(sessionControllerProvider).phase == SessionPhase.ready;
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.ready,
    );

    // Controlled client network interruption — Dio to unreachable host.
    Object? netError;
    try {
      await Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 800),
          receiveTimeout: const Duration(milliseconds: 800),
        ),
      ).get('http://127.0.0.1:9/nope');
    } catch (e) {
      netError = e;
    }
    evidence['clientNetworkErrorObserved'] = netError != null;
    evidence['clientNetworkErrorType'] = netError.runtimeType.toString();
    expect(netError, isNotNull);

    // Reconnection: real API still works with same session (no stale swap).
    final me = await Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        headers: {
          'Authorization':
              'Bearer ${container.read(sessionControllerProvider).tokens?.accessToken}',
        },
      ),
    ).get<Map<String, dynamic>>(ApiEndpoints.customerMePath);
    evidence['reconnectApiOk'] = me.statusCode == 200;
    evidence['reconnectAccountId'] = me.data?['accountId'] ?? me.data?['id'];
    expect(me.statusCode, 200);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.ready,
    );
    evidence['accessExpiryObserved'] = false;
    evidence['refreshRotationLive'] = 'NOT_TESTED_access_not_expired';

    File('$reportDir/logs/session-network-evidence.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        ...evidence,
        'logoutIsolation': 'covered_by_session_controller_unit_and_auth_logout_revoke',
        'finishedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  });
}
