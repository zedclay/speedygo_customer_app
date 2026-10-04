import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/orders/application/orders_list_controller.dart';
import 'package:speedygo_customer_app/features/support/application/support_list_controller.dart';

import 'support/dev_otp_file.dart';

/// Natural access-token expiry → in-app refresh observation (one app instance).
///
/// Uses a synthetic Revue session. If the local seed cannot restore (stale
/// refresh), performs **one** normal in-app OTP (respecting cooldowns), then
/// waits for natural access expiry. Never copies the refresh token to an
/// external client, never changes TTLs/clocks, and does not revoke sessions.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const reportDir =
      '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/customer-release-readiness';
  const tokenPath =
      '/Users/mac/Downloads/speedygo_project/.cache/support-closure/otp-verify.json';

  String fp(String value) {
    // Short non-reversible fingerprint for evidence only (never log tokens).
    var h = 0;
    for (final c in value.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  Map<String, Object?> accessMeta(String? jwt) {
    if (jwt == null || jwt.isEmpty) {
      return {'present': false};
    }
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return {'present': true, 'parse': 'bad'};
      final payload = parts[1];
      final padded = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      final data =
          jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
      final exp = data['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expInt = exp is int ? exp : int.tryParse('$exp');
      return {
        'present': true,
        'exp': expInt,
        'secondsUntilExp': expInt == null ? null : expInt - now,
        'accessFp': fp(jwt),
        'sidFp': data['sid'] == null ? null : fp('${data['sid']}'),
      };
    } catch (_) {
      return {'present': true, 'parse': 'error'};
    }
  }

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

  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    int ticks = 120,
  }) async {
    for (var i = 0; i < ticks; i++) {
      if (finder.evaluate().isNotEmpty) return true;
      await tester.pump(const Duration(milliseconds: 100));
    }
    return finder.evaluate().isNotEmpty;
  }

  Future<void> revueOtpOnce(WidgetTester tester) async {
    await pumpUntil(tester, find.text(AppStrings.phoneTitle), ticks: 200);
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
    // Respect AUTH_RATE_LIMITED / cooldown copy — do not spam request.
    if (find.textContaining('réessayer').evaluate().isNotEmpty ||
        find.textContaining('Trop de tentatives').evaluate().isNotEmpty) {
      fail('OTP cooldown/rate-limit visible; not retrying');
    }
    File? found;
    for (var i = 0; i < 80; i++) {
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
    await pumpUntil(tester, find.text(AppStrings.searchHint), ticks: 300);
  }

  testWidgets('natural access expiry triggers single in-app refresh', (
    tester,
  ) async {
    Directory('$reportDir/logs').createSync(recursive: true);
    Directory(tokenPath).parent.createSync(recursive: true);
    final evidence = <String, Object?>{
      'observation': 'in_app_natural_access_expiry',
      'accountHint': 'Revue Catalogue SpeedyGo',
    };

    final store = MemorySessionStore();
    final launch = MemoryLaunchStore(onboardingSeen: true, languageSeen: true);
    final tokenFile = File(tokenPath);
    var usedOtp = false;

    if (tokenFile.existsSync()) {
      try {
        final tokens = Map<String, dynamic>.from(
          jsonDecode(tokenFile.readAsStringSync()),
        );
        final seeded = TokenPair.fromJson(tokens);
        evidence['seedAccessBefore'] = accessMeta(seeded.accessToken);
        await store.write(seeded);
      } catch (_) {
        evidence['seedParse'] = 'failed';
      }
    }

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

    final homeFromSeed = await waitFor(
      tester,
      find.text(AppStrings.searchHint),
      ticks: 200,
    );
    evidence['homeFromSeed'] = homeFromSeed;

    if (!homeFromSeed) {
      // Stale seed / failed restore — one in-app Revue OTP only.
      usedOtp = true;
      evidence['bootstrap'] = 'in_app_otp_once';
      await revueOtpOnce(tester);
    }

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SpeedyGoApp)),
    );
    final infra = container.read(authInfrastructureProvider);
    var session = container.read(sessionControllerProvider);
    evidence['usedOtpBootstrap'] = usedOtp;
    evidence['refreshCountAtHome'] = infra.refresher.refreshCount;
    evidence['sessionPhaseAtHome'] = session.phase.name;
    evidence['accessAtHome'] = accessMeta(session.tokens?.accessToken);

    // Persist rotated/new pair locally for same-app future seeds only (never
    // sent to an external HTTP client from this harness).
    final live = session.tokens;
    if (live != null) {
      tokenFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(live.toJson()),
      );
      evidence['seedCacheUpdated'] = true;
    }

    if (session.phase != SessionPhase.ready || live == null) {
      evidence['result'] = 'NOT_TESTED_no_authenticated_session';
      File('$reportDir/logs/refresh-expiry-evidence.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          ...evidence,
          'finishedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      debugPrint('REFRESH_EVIDENCE:${jsonEncode(evidence)}');
      fail('No authenticated Revue session for natural expiry observation');
    }

    // Wait for natural access expiry (TTL typically 900s). Do not change clocks.
    final until = (evidence['accessAtHome'] as Map)['secondsUntilExp'];
    if (until is int && until > 0) {
      evidence['waitedForNaturalExpirySeconds'] = until + 2;
      final deadline = DateTime.now().add(Duration(seconds: until + 2));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(seconds: 1));
      }
    } else {
      evidence['waitedForNaturalExpirySeconds'] = 0;
    }

    session = container.read(sessionControllerProvider);
    final accessBeforeBurst = session.tokens?.accessToken;
    final beforeMeta = accessMeta(accessBeforeBurst);
    evidence['accessBeforeBurst'] = beforeMeta;
    final untilBurst = beforeMeta['secondsUntilExp'];
    evidence['accessExpiryObserved'] =
        untilBurst is int && untilBurst <= 0 && accessBeforeBurst != null;

    final beforeBurst = infra.refresher.refreshCount;
    evidence['refreshCountBeforeBurst'] = beforeBurst;

    Object? burstError;
    Map<String, Object?>? me1;
    try {
      final authMe1 = await infra.authApi.me();
      me1 = {
        'accountId': authMe1.accountId,
        'phone': authMe1.phone,
        'hasCustomerProfile': authMe1.hasCustomerProfile,
      };
      await infra.customerApi.me();
      await container.read(ordersListControllerProvider.notifier).refresh();
      await container.read(supportListControllerProvider.notifier).refresh();
      final authMe2 = await infra.authApi.me();
      evidence['subsequentMeOk'] = true;
      evidence['subsequentAccountId'] = authMe2.accountId;
      evidence['accountUnchanged'] = authMe1.accountId == authMe2.accountId;
    } catch (e) {
      burstError = e;
      evidence['subsequentMeOk'] = false;
      evidence['burstErrorType'] = e.runtimeType.toString();
      evidence['burstError'] = e.toString();
    }

    await tester.pump(const Duration(milliseconds: 500));

    final afterBurst = infra.refresher.refreshCount;
    // Authoritative pair after interceptor refresh lives in TokenCache / store.
    // SessionController.state.tokens is not mirrored on silent rotation.
    final cachedAfter = container.read(tokenCacheProvider).current;
    final storedAfter = await store.read();
    final accessAfter =
        cachedAfter?.accessToken ?? storedAfter?.accessToken;
    evidence['refreshCountAfterBurst'] = afterBurst;
    evidence['refreshDelta'] = afterBurst - beforeBurst;
    evidence['accessAfterBurst'] = accessMeta(accessAfter);
    evidence['accessRotated'] =
        accessBeforeBurst != null &&
        accessAfter != null &&
        accessBeforeBurst != accessAfter;
    evidence['tokenSourceAfter'] = cachedAfter != null
        ? 'tokenCache'
        : (storedAfter != null ? 'sessionStore' : 'none');
    evidence['me1'] = me1;
    evidence['sessionPhaseAfter'] =
        container.read(sessionControllerProvider).phase.name;
    evidence['stillAuthenticated'] =
        container.read(sessionControllerProvider).phase == SessionPhase.ready &&
        accessAfter != null &&
        accessAfter.isNotEmpty;
    evidence['singleFlightOk'] = (afterBurst - beforeBurst) <= 1;
    evidence['homeVisibleAloneInsufficient'] = true;

    // Refresh reuse / revocation checks (sanitized): sid fingerprint change is
    // allowed on rotation; session must remain authenticated.
    final sidBefore = beforeMeta['sidFp'];
    final sidAfter = (evidence['accessAfterBurst'] as Map)['sidFp'];
    evidence['sidFpBefore'] = sidBefore;
    evidence['sidFpAfter'] = sidAfter;

    final pass = evidence['accessExpiryObserved'] == true &&
        evidence['accessRotated'] == true &&
        evidence['refreshDelta'] == 1 &&
        evidence['subsequentMeOk'] == true &&
        evidence['stillAuthenticated'] == true &&
        burstError == null;

    evidence['result'] = pass
        ? 'PASS'
        : (burstError != null ? 'FAIL_OR_INCONCLUSIVE' : 'INCONCLUSIVE');

    final persist = cachedAfter ?? storedAfter;
    if (persist != null) {
      tokenFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(persist.toJson()),
      );
    }

    File('$reportDir/logs/refresh-expiry-evidence.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        ...evidence,
        'finishedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    debugPrint('REFRESH_EVIDENCE:${jsonEncode(evidence)}');

    expect(evidence['accessExpiryObserved'], isTrue);
    expect(burstError, isNull);
    expect(evidence['refreshDelta'], 1);
    expect(evidence['accessRotated'], isTrue);
    expect(evidence['subsequentMeOk'], isTrue);
    expect(evidence['stillAuthenticated'], isTrue);
  }, timeout: const Timeout(Duration(minutes: 25)));
}
