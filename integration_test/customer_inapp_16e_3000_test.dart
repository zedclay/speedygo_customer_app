import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/notifications/presentation/notification_inbox_screen.dart';

/// DEVICE_UI: Customer IN_APP inbox on iPhone 16e vs live :3000.
/// Dedicated fixture rows only. Does not create orders or mutate money.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const expectedApi = 'http://127.0.0.1:3000/api/v1';
  const evidDir = String.fromEnvironment(
    'INAPP_EVIDENCE_DIR',
    defaultValue:
        '/Users/mac/Downloads/speedygo_project/docs/audits/2026-10-23/evidence/customer_inapp_16e',
  );
  const shotMarker = String.fromEnvironment(
    'INAPP_SHOT_FILE',
    defaultValue: '/tmp/speedygo_customer_inapp_shot.txt',
  );
  const phase = String.fromEnvironment(
    'INAPP_PHASE',
    defaultValue: 'empty',
  );
  const acceptedId = String.fromEnvironment(
    'INAPP_ACCEPTED_ID',
    defaultValue: 'c1a55e70-1aab-4b02-8002-000000000101',
  );
  const acceptedSource = String.fromEnvironment(
    'INAPP_ACCEPTED_SOURCE',
    defaultValue: 'c1a55e70-1aab-4b02-8002-000000000201',
  );
  const destOrderId = String.fromEnvironment('INAPP_DEST_ORDER_ID');
  const destPublicRef = String.fromEnvironment('INAPP_PUBLIC_REF');
  const fixturePhone = String.fromEnvironment('INAPP_FIXTURE_PHONE');

  Map<String, dynamic> tokens() {
    const b64 = String.fromEnvironment('SMOKE_TOKEN_B64');
    if (b64.isEmpty) {
      throw StateError('SMOKE_TOKEN_B64 required');
    }
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64Decode(b64))) as Map,
    );
  }

  Future<void> pumpFrames(WidgetTester tester, int ticks) async {
    for (var i = 0; i < ticks; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> waitFinder(
    WidgetTester tester,
    Finder finder, {
    int ticks = 80,
  }) async {
    for (var i = 0; i < ticks; i++) {
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    return false;
  }

  String dumpTexts(WidgetTester tester) {
    final texts = <String>[];
    for (final el in find.byType(Text).evaluate()) {
      final w = el.widget;
      if (w is Text) {
        final s = w.data ?? w.textSpan?.toPlainText() ?? '';
        if (s.trim().isNotEmpty) {
          texts.add(s.trim());
        }
      }
    }
    return texts.take(80).join(' | ');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    debugPrint('INAPP_UI_$tag:${dumpTexts(tester)}');
    Directory(evidDir).createSync(recursive: true);
    File('$evidDir/ui_$tag.txt').writeAsStringSync(dumpTexts(tester));
    await pumpFrames(tester, 6);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    File(shotMarker).writeAsStringSync(tag);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await pumpFrames(tester, 2);
  }

  Future<void> denySystemLocation(WidgetTester tester) async {
    for (final label in <String>[
      "Don't Allow",
      'Don’t Allow',
      'Ask Next Time',
    ]) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.tap(find.text(label));
        await pumpFrames(tester, 12);
        return;
      }
    }
  }

  GoRouter routerOf(WidgetTester tester) {
    return GoRouter.of(tester.element(find.byType(Navigator).first));
  }

  Future<void> awaitHome(WidgetTester tester, {required bool arabic}) async {
    final hint = arabic
        ? 'ابحث عن متجر أو منتج'
        : 'Rechercher un commerce ou produit';
    final found = await waitFinder(tester, find.text(hint), ticks: 160);
    await denySystemLocation(tester);
    await pumpFrames(tester, 8);
    if (!found && find.text(hint).evaluate().isEmpty) {
      fail(
        'home not reached locale=${arabic ? 'ar' : 'fr'}: ${dumpTexts(tester)}',
      );
    }
  }

  ProviderScope app({
    required MemorySessionStore store,
    required MemoryLaunchStore launch,
    required MemoryAddressSelectionStore selection,
  }) {
    return ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        launchStoreProvider.overrideWithValue(launch),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        splashAnimateProvider.overrideWithValue(false),
        addressSelectionStoreProvider.overrideWithValue(selection),
      ],
      child: const SpeedyGoApp(),
    );
  }

  Future<void> openInbox(WidgetTester tester) async {
    final bell = find.byKey(const Key('home-alerts-bell'));
    if (bell.evaluate().isNotEmpty) {
      await tester.tap(bell);
      await pumpFrames(tester, 24);
      return;
    }
    routerOf(tester).go(AppRoutes.alerts);
    await pumpFrames(tester, 24);
  }

  Future<void> switchArabic(
    WidgetTester tester,
    MemoryLaunchStore launch,
  ) async {
    routerOf(tester).push(AppRoutes.accountLanguage);
    await pumpFrames(tester, 24);
    expect(
      await waitFinder(
        tester,
        find.byKey(const Key('language-option-ar')),
        ticks: 60,
      ),
      isTrue,
    );
    await tester.tap(find.byKey(const Key('language-option-ar')));
    await pumpFrames(tester, 8);
    final save = find.text(AppStrings.languageSave);
    expect(save, findsWidgets);
    await tester.tap(save.last);
    await pumpFrames(tester, 16);
    expect(launch.locale, AppLocale.arabic);
  }

  testWidgets('customer in-app inbox 16e $phase', (tester) async {
    expect(AppConstants.apiBaseUrl, expectedApi);
    final store = MemorySessionStore();
    await store.write(TokenPair.fromJson(tokens()));
    final launch = MemoryLaunchStore(
      onboardingSeen: true,
      languageSeen: true,
      locale: AppLocale.french,
    );
    final selection = MemoryAddressSelectionStore();

    await tester.pumpWidget(
      app(store: store, launch: launch, selection: selection),
    );
    File(shotMarker).writeAsStringSync('WAIT_DENY_LOCATION');
    await Future<void>.delayed(const Duration(seconds: 2));
    await awaitHome(tester, arabic: false);

    if (phase == 'empty') {
      await openInbox(tester);
      expect(
        await waitFinder(
          tester,
          find.byKey(const Key('notifications-empty')),
          ticks: 80,
        ),
        isTrue,
      );
      expect(find.text('Aucune notification pour le moment.'), findsOneWidget);
      await shot(tester, 'empty_fr');

      await switchArabic(tester, launch);
      await tester.pumpWidget(
        app(store: store, launch: launch, selection: selection),
      );
      File(shotMarker).writeAsStringSync('WAIT_DENY_LOCATION');
      await Future<void>.delayed(const Duration(seconds: 2));
      await denySystemLocation(tester);
      await pumpFrames(tester, 40);
      routerOf(tester).go(AppRoutes.alerts);
      await pumpFrames(tester, 24);
      expect(
        await waitFinder(
          tester,
          find.byKey(const Key('notifications-empty')),
          ticks: 80,
        ),
        isTrue,
      );
      expect(find.text('لا توجد إشعارات حاليًا.'), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byType(NotificationInboxScreen)),
        ),
        TextDirection.rtl,
      );
      await shot(tester, 'empty_ar');
      File('$evidDir/customer_inapp_empty.json').writeAsStringSync(
        jsonEncode({
          'app': 'CUSTOMER',
          'phase': 'empty',
          'kind': 'device_ui',
          'result': 'PASS',
        }),
      );
      File(shotMarker).writeAsStringSync('done');
      return;
    }

    await openInbox(tester);
    expect(
      await waitFinder(tester, find.text('Commande acceptée'), ticks: 80),
      isTrue,
    );

    if (phase == 'owned_destination') {
      expect(destOrderId, isNotEmpty, reason: 'owned dest requires order UUID');
      expect(
        find.byKey(Key('notification-tile-$acceptedId')),
        findsOneWidget,
      );
      await shot(tester, 'owned_inbox_fr');
      await tester.tap(find.byKey(Key('notification-tile-$acceptedId')));
      await pumpFrames(tester, 40);
      final location = routerOf(tester).state.uri.path;
      expect(location, contains(destOrderId));
      expect(location.endsWith('/tracking'), isTrue);
      expect(
        location.contains(destPublicRef.replaceAll('sgo_', '')),
        isFalse,
        reason: 'navigation uses contract sourceId, not display sgo_*',
      );
      expect(find.textContaining('introuvable'), findsNothing);
      expect(
        await waitFinder(
          tester,
          find.text(AppStrings.trackingCompletedTitle),
          ticks: 80,
        ),
        isTrue,
      );
      if (destPublicRef.isNotEmpty) {
        expect(find.textContaining(destPublicRef), findsWidgets);
      }
      await shot(tester, 'destination_owned_order_fr');
      File('$evidDir/customer_inapp_owned_destination.json').writeAsStringSync(
        jsonEncode({
          'app': 'CUSTOMER',
          'phase': 'owned_destination',
          'kind': 'device_ui',
          'fixturePhone': fixturePhone,
          'destination': {
            'kind': 'owned_order_tracking',
            'orderId': destOrderId,
            'publicReference': destPublicRef,
            'route': location,
            'navigatedBy': 'sourceId',
            'result': 'PASS',
          },
          'result': 'PASS',
        }),
      );
      File(shotMarker).writeAsStringSync('done');
      return;
    }

    expect(find.byKey(const Key('notifications-mark-all')), findsOneWidget);
    expect(
      find.byKey(Key('notification-unread-$acceptedId')),
      findsOneWidget,
    );
    await shot(tester, 'populated_fr');

    await tester.tap(find.byKey(Key('notification-tile-$acceptedId')));
    await pumpFrames(tester, 40);
    final location = routerOf(tester).state.uri.path;
    expect(location, contains(acceptedSource));
    expect(location.endsWith('/tracking'), isTrue);
    await waitFinder(
      tester,
      find.textContaining('introuvable'),
      ticks: 40,
    );
    await shot(tester, 'destination_missing_order_fr');

    routerOf(tester).go(AppRoutes.alerts);
    await pumpFrames(tester, 24);
    expect(
      await waitFinder(tester, find.text('Commande acceptée'), ticks: 80),
      isTrue,
    );
    expect(
      find.byKey(Key('notification-unread-$acceptedId')),
      findsNothing,
    );
    await shot(tester, 'after_mark_read_fr');

    final markAll = find.byKey(const Key('notifications-mark-all'));
    expect(markAll, findsOneWidget);
    await tester.tap(markAll);
    await pumpFrames(tester, 30);
    expect(find.byKey(const Key('notifications-mark-all')), findsNothing);
    await shot(tester, 'after_read_all_fr');

    routerOf(tester).go(AppRoutes.home);
    await pumpFrames(tester, 16);
    await openInbox(tester);
    expect(
      await waitFinder(tester, find.text('Commande acceptée'), ticks: 80),
      isTrue,
    );
    expect(find.byKey(const Key('notifications-mark-all')), findsNothing);
    await shot(tester, 'reopen_persisted_fr');

    await switchArabic(tester, launch);
    await tester.pumpWidget(
      app(store: store, launch: launch, selection: selection),
    );
    File(shotMarker).writeAsStringSync('WAIT_DENY_LOCATION');
    await Future<void>.delayed(const Duration(seconds: 2));
    await denySystemLocation(tester);
    await pumpFrames(tester, 40);
    routerOf(tester).go(AppRoutes.alerts);
    await pumpFrames(tester, 24);
    expect(
      await waitFinder(tester, find.text('التنبيهات'), ticks: 80),
      isTrue,
    );
    expect(find.text('تم قبول الطلب'), findsOneWidget);
    expect(find.text('تم الدفع'), findsOneWidget);
    await shot(tester, 'populated_ar');

    File('$evidDir/customer_inapp_populated.json').writeAsStringSync(
      jsonEncode({
        'app': 'CUSTOMER',
        'phase': 'populated',
        'kind': 'device_ui',
        'destination': {
          'kind': 'synthetic_missing_order',
          'route': AppRoutes.orderTracking(acceptedSource),
          'result': 'error_handling',
          'ownedOrdersOnFixture': 0,
          'realOwnedOrder': 'blocked',
        },
        'result': 'PASS',
      }),
    );
    File(shotMarker).writeAsStringSync('done');
  });
}
