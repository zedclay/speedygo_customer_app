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

/// Customer release — support live gestures (Revue only).
/// Reuses fixture ticket; at most ONE create if no prior UI create evidence.
/// Session: Keychain restore OR in-app MemorySessionStore seed (same app; not
/// shared with external clients). Does not resend follow-up when fixture says sent.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const ticketId = '01a0890a-c432-7703-9059-3d71d587d35e';
  const publicReference = 'sgt_01a0890ac4327557b3aee7239d024822';
  const revuePhone = '+213550000072';
  const reportDir =
      '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/customer-release-readiness';
  final evidence = <String, Object?>{
    'fixtureTicketId': ticketId,
    'followUpResent': false,
    'createdNewTicket': false,
  };

  Future<void> shot(String name) async {
    Directory('$reportDir/logs').createSync(recursive: true);
    debugPrint('SUPPORT_RELEASE:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File('$reportDir/logs/last-shot.txt').writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

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
    fail('Timed out for $finder. Visible: $texts');
  }

  testWidgets('fixture list → detail → draft retention → Back', (tester) async {
    Directory('$reportDir/logs').createSync(recursive: true);

    final tokenFile = File(
      '/Users/mac/Downloads/speedygo_project/.cache/support-closure/otp-verify.json',
    );
    expect(tokenFile.existsSync(), isTrue, reason: 'Revue session seed required');
    final tokens =
        Map<String, dynamic>.from(jsonDecode(tokenFile.readAsStringSync()));
    final store = MemorySessionStore();
    await store.write(TokenPair.fromJson(tokens));
    final launch = MemoryLaunchStore(onboardingSeen: true, languageSeen: true);
    evidence['login'] = 'seeded_memory_session_same_app';

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
      if (find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
        break;
      }
    }
    await pumpUntil(tester, find.text(AppStrings.searchHint), ticks: 200);
    await shot('01-home');

    final homeCtx = tester.element(find.text(AppStrings.searchHint).first);
    GoRouter.of(homeCtx).go(AppRoutes.supportList);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await pumpUntil(tester, find.text(AppStrings.supportListTitle));
    await pumpUntil(
      tester,
      find.byKey(const Key('support-ticket-tile-$ticketId')),
    );
    expect(find.textContaining(publicReference), findsWidgets);
    await shot('02-support-list');

    await tester.tap(find.byKey(const Key('support-ticket-tile-$ticketId')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await pumpUntil(tester, find.byKey(const Key('support-detail-reference')));
    expect(find.textContaining('Test support Revue'), findsWidgets);
    expect(find.textContaining('Test support Revue follow-up'), findsWidgets);
    await shot('03-support-detail');

    const draft =
        'SpeedyGo acceptance draft — do not send — keep for retention check';
    if (find.byKey(const Key('support-reply-body')).evaluate().isNotEmpty) {
      await tester.enterText(find.byKey(const Key('support-reply-body')), draft);
      await tester.pump();
      expect(find.text(draft), findsOneWidget);
      evidence['draftTyped'] = true;
      // Do NOT send — follow-up already recorded on fixture.
      await tester.tap(find.byTooltip(AppStrings.back));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await pumpUntil(
        tester,
        find.byKey(const Key('support-ticket-tile-$ticketId')),
      );
      await tester.tap(find.byKey(const Key('support-ticket-tile-$ticketId')));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await pumpUntil(tester, find.byKey(const Key('support-detail-reference')));
      await tester.pump(const Duration(milliseconds: 80));
      final retained =
          find.text(draft).evaluate().isNotEmpty ||
          find.textContaining('acceptance draft').evaluate().isNotEmpty;
      evidence['draftRetainedAcrossBack'] = retained;
      await shot('04-draft-after-back');
    } else {
      evidence['draftTyped'] = false;
      evidence['draftRetainedAcrossBack'] = null;
      evidence['replyClosed'] =
          find.byKey(const Key('support-reply-closed')).evaluate().isNotEmpty;
    }

    await tester.tap(find.byTooltip(AppStrings.back));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.byKey(const Key('support-ticket-tile-$ticketId')),
      findsWidgets,
    );
    await shot('05-list-after-back');

    final createIdFile = File('$reportDir/support-create-identity.json');
    final priorCreate = createIdFile.existsSync()
        ? jsonDecode(createIdFile.readAsStringSync()) as Map<String, dynamic>
        : null;
    if (priorCreate != null && priorCreate['ticketId'] != null) {
      evidence['createFlow'] = 'reused_prior_ui_create';
      evidence['createTicketId'] = priorCreate['ticketId'];
    } else {
      evidence['apiCreateEvidence'] = File(
        '/Users/mac/Downloads/speedygo_project/.cache/support-closure/live-report.json',
      ).existsSync();
      await tester.tap(find.byKey(const Key('support-list-new')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await pumpUntil(tester, find.byKey(const Key('support-create-body')));
      const body =
          '[SpeedyGo acceptance] Synthetic Customer UI create — Revue — do not escalate';
      await tester.enterText(find.byKey(const Key('support-create-body')), body);
      await tester.pump();
      await tester.tap(find.byTooltip(AppStrings.back));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.byKey(const Key('support-list-new')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await pumpUntil(tester, find.byKey(const Key('support-create-body')));
      await tester.pump(const Duration(milliseconds: 80));
      final createDraftKept = find
          .textContaining('Synthetic Customer UI create')
          .evaluate()
          .isNotEmpty;
      evidence['createDraftRetainedAcrossBack'] = createDraftKept;
      if (!createDraftKept) {
        await tester.enterText(
          find.byKey(const Key('support-create-body')),
          body,
        );
        await tester.pump();
      }
      await tester.tap(find.byKey(const Key('support-create-submit')));
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      String? newId;
      for (final e in find.byType(Text).evaluate()) {
        final t = (e.widget as Text).data ?? '';
        if (t.startsWith('sgt_') && t != publicReference) {
          evidence['createPublicReference'] = t;
        }
      }
      if (find.byKey(const Key('support-detail-reference')).evaluate().isNotEmpty) {
        evidence['createLandedOnDetail'] = true;
        await shot('06-create-detail');
        await tester.tap(find.byTooltip(AppStrings.back));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      for (final e in find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'support-ticket-tile-',
                ),
          )
          .evaluate()) {
        final v = (e.widget.key! as ValueKey<String>).value;
        final id = v.replaceFirst('support-ticket-tile-', '');
        if (id != ticketId) {
          newId = id;
        }
      }
      evidence['createdNewTicket'] = newId != null;
      evidence['createTicketId'] = newId;
      createIdFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'ticketId': newId,
          'body': body,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'source': 'customer_ui_acceptance',
          'customerPhone': revuePhone,
        }),
      );
      await shot('07-after-create');
      evidence['createFlow'] = 'ui_create_once';
      // Reconcile uncertain: if submit failed silently, do not POST again.
      if (newId == null) {
        evidence['createReconcile'] = 'no_new_tile_observed_no_repost';
      }
    }

    File('$reportDir/logs/support-evidence.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        ...evidence,
        'finishedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    // Soft assertions for draft retention — record fail in evidence, hard-fail create path only if submit claimed without id.
    if (evidence['draftTyped'] == true &&
        evidence['draftRetainedAcrossBack'] != true) {
      fail('Detail draft not retained across Back');
    }
    if (evidence['createFlow'] == 'ui_create_once' &&
        evidence['createdNewTicket'] != true) {
      fail('UI create submitted but no new ticket id observed');
    }
  });
}
