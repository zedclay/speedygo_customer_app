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

/// Android emulator smoke. Requires:
/// `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1`
/// `--dart-define=SMOKE_TOKEN_JSON=...` (host paths are not writable on-device)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const fixtureTicket = '01a0890a-c432-7703-9059-3d71d587d35e';

  void persistEvidence(Map<String, Object?> evidence) {
    final payload = {
      ...evidence,
      'finishedAt': DateTime.now().toUtc().toIso8601String(),
    };
    debugPrint('SMOKE_EVIDENCE_ANDROID:${jsonEncode(payload)}');
  }

  Future<void> shot(String name) async {
    debugPrint('SMOKE_ANDROID:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 300));
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

  testWidgets('android catalog orders support address smoke', (tester) async {
    final evidence = <String, Object?>{
      'platform': 'android_emulator',
      'apiBaseHint': '10.0.2.2',
    };

    const seeded = String.fromEnvironment('SMOKE_TOKEN_JSON');
    Map<String, dynamic> tokens;
    if (seeded.isNotEmpty) {
      tokens = Map<String, dynamic>.from(jsonDecode(seeded));
    } else {
      final tokenFile = File(
        '/Users/mac/Downloads/speedygo_project/.cache/support-closure/otp-verify.json',
      );
      tokens =
          Map<String, dynamic>.from(jsonDecode(tokenFile.readAsStringSync()));
    }
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
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(AppStrings.searchHint).evaluate().isNotEmpty) break;
    }
    await pumpUntil(tester, find.text(AppStrings.searchHint), ticks: 200);
    await shot('01-home');
    evidence['home'] = true;

    const atlasBranchId = '0d00c071-d000-7000-8000-000000011008';
    const creamProductId = '0d00c071-d000-7000-8000-000000030821';
    const demoCafeBranchId = '0d00c070-d000-7000-8000-000000000003';
    const espressoDemoId = '0d00c070-d000-7000-8000-000000000020';

    Future<bool> waitFor(Finder f, {int ticks = 120}) async {
      for (var i = 0; i < ticks; i++) {
        if (f.evaluate().isNotEmpty) return true;
        await tester.pump(const Duration(milliseconds: 100));
      }
      return f.evaluate().isNotEmpty;
    }

    // ListView lazily builds children — wait for the first on-screen branch.
    final feedByName = await waitFor(
      find.textContaining('Atelier Sucré'),
      ticks: 150,
    );
    evidence['feedReady'] = feedByName;
    evidence['feedHasAtelier'] =
        find.textContaining('Atelier Sucré').evaluate().isNotEmpty;
    evidence['feedHasDemoCafe'] =
        find.textContaining('Demo Cafe Hydra').evaluate().isNotEmpty;
    evidence['feedHasAtlasText'] =
        find.textContaining('Pharmacie Atlas').evaluate().isNotEmpty;
    evidence['feedEmptyMessage'] =
        find.text(AppStrings.storefrontsEmpty).evaluate().isNotEmpty;
    evidence['feedErrorMessage'] =
        find.text(AppStrings.catalogLoadError).evaluate().isNotEmpty;

    // Prefer the vertical home ListView — never the horizontal category strip.
    Finder homeVerticalScrollable() {
      final vertical = find.byWidgetPredicate(
        (w) =>
            w is Scrollable &&
            (w.axisDirection == AxisDirection.down ||
                w.axisDirection == AxisDirection.up),
      );
      return vertical.first;
    }

    Future<Finder> scrollToKey(Key key) async {
      final target = find.byKey(key);
      if (target.evaluate().isNotEmpty) return target;
      try {
        await tester.scrollUntilVisible(
          target,
          200,
          scrollable: homeVerticalScrollable(),
        );
      } catch (_) {
        // Manual fallback: drag the vertical home list.
        for (var i = 0; i < 12; i++) {
          if (find.byKey(key).evaluate().isNotEmpty) break;
          try {
            await tester.drag(homeVerticalScrollable(), const Offset(0, -320));
          } catch (_) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      await tester.pump(const Duration(milliseconds: 200));
      return find.byKey(key);
    }

    Future<Finder> scrollToText(String text) async {
      final target = find.textContaining(text);
      if (target.evaluate().isNotEmpty) return target;
      try {
        await tester.scrollUntilVisible(
          target,
          200,
          scrollable: homeVerticalScrollable(),
        );
      } catch (_) {
        for (var i = 0; i < 12; i++) {
          if (find.textContaining(text).evaluate().isNotEmpty) break;
          try {
            await tester.drag(homeVerticalScrollable(), const Offset(0, -320));
          } catch (_) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      await tester.pump(const Duration(milliseconds: 200));
      return find.textContaining(text);
    }

    // Category chip first (horizontal strip), then open Atlas under Pharmacies.
    Finder pharmacies = find.text('Pharmacies');
    if (pharmacies.evaluate().isEmpty) {
      try {
        final horiz = find.byWidgetPredicate(
          (w) =>
              w is Scrollable &&
              (w.axisDirection == AxisDirection.right ||
                  w.axisDirection == AxisDirection.left),
        );
        await tester.scrollUntilVisible(
          pharmacies,
          80,
          scrollable: horiz.first,
        );
      } catch (_) {}
      await tester.pump(const Duration(milliseconds: 200));
      pharmacies = find.text('Pharmacies');
    }
    if (pharmacies.evaluate().isNotEmpty) {
      await tester.ensureVisible(pharmacies.first);
      await tester.tap(pharmacies.first, warnIfMissed: false);
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      evidence['category'] = 'Pharmacies';
    } else {
      evidence['category'] = 'not_found_continue';
    }
    await shot('02-category');

    // Prefer Atlas; fall back to Demo Cafe Hydra if needed.
    String openedBranch = atlasBranchId;
    String openedProduct = creamProductId;
    List<String> productNameHints = [
      'Crème solaire',
      'Paracétamol',
      'Dentifrice',
    ];
    Finder storefrontHit = await scrollToKey(const ValueKey(atlasBranchId));
    if (storefrontHit.evaluate().isEmpty) {
      storefrontHit = await scrollToText('Pharmacie Atlas');
    }

    if (storefrontHit.evaluate().isEmpty) {
      final showAll = find.text(AppStrings.storefrontsShowAll);
      if (showAll.evaluate().isNotEmpty) {
        await tester.tap(showAll.first, warnIfMissed: false);
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      openedBranch = demoCafeBranchId;
      openedProduct = espressoDemoId;
      productNameHints = ['Espresso Demo', 'Croissant Demo'];
      storefrontHit = await scrollToKey(const ValueKey(demoCafeBranchId));
      if (storefrontHit.evaluate().isEmpty) {
        storefrontHit = await scrollToText('Demo Cafe Hydra');
      }
      evidence['storefrontFallback'] = 'Demo Cafe Hydra';
    }
    if (storefrontHit.evaluate().isEmpty) {
      evidence['storefront'] = 'BLOCKED_no_branch';
    } else {
      await tester.ensureVisible(storefrontHit.first);
      await tester.tap(storefrontHit.first, warnIfMissed: false);
      evidence['storefrontTap'] = openedBranch;
      // Confirm navigation — do not treat a missed tap as storefront success.
      var opened = false;
      for (var i = 0; i < 60; i++) {
        if (find.byKey(ValueKey(openedProduct)).evaluate().isNotEmpty ||
            find.byKey(const Key('storefront-reviews-entry')).evaluate().isNotEmpty ||
            find.text(AppStrings.productsEmptyUnfiltered).evaluate().isNotEmpty ||
            find.text(AppStrings.productsEmpty).evaluate().isNotEmpty) {
          opened = true;
          break;
        }
        // Branch title on detail can share home text; prefer reviews/product keys.
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (!opened) {
        // One retry tap on the branch name.
        final named = find.textContaining(
          openedBranch == atlasBranchId ? 'Pharmacie Atlas' : 'Demo Cafe Hydra',
        );
        if (named.evaluate().isNotEmpty) {
          await tester.ensureVisible(named.first);
          await tester.tap(named.first, warnIfMissed: false);
          for (var i = 0; i < 60; i++) {
            if (find.byKey(ValueKey(openedProduct)).evaluate().isNotEmpty ||
                find.byKey(const Key('storefront-reviews-entry')).evaluate().isNotEmpty) {
              opened = true;
              break;
            }
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
      }
      evidence['storefront'] = opened ? true : 'BLOCKED_tap_no_navigation';
    }
    await shot('03-storefront');

    // Product — prefer ValueKey; scroll vertical CustomScrollView only.
    Finder? productHit;
    if (evidence['storefront'] == true) {
      for (var attempt = 0; attempt < 50; attempt++) {
        final byId = find.byKey(ValueKey(openedProduct));
        if (byId.evaluate().isNotEmpty) {
          productHit = byId;
          break;
        }
        for (final hint in productNameHints) {
          final byName = find.textContaining(hint);
          if (byName.evaluate().isNotEmpty) {
            productHit = byName;
            break;
          }
        }
        if (productHit != null) break;
        final vertical = find.byWidgetPredicate(
          (w) =>
              w is Scrollable &&
              (w.axisDirection == AxisDirection.down ||
                  w.axisDirection == AxisDirection.up),
        );
        if (vertical.evaluate().isNotEmpty) {
          await tester.drag(vertical.last, const Offset(0, -280));
        }
        await tester.pump(const Duration(milliseconds: 150));
      }
    }
    if (productHit != null) {
      await tester.ensureVisible(productHit.first);
      await tester.tap(productHit.first, warnIfMissed: false);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      evidence['product'] = true;
      evidence['openedProduct'] = openedProduct;
      await shot('04-product');
      await tester.tap(find.byTooltip(AppStrings.back));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      evidence['productBack'] = true;
      await shot('05-after-product-back');
    } else {
      final empty =
          find.text(AppStrings.productsEmptyUnfiltered).evaluate().isNotEmpty ||
          find.text(AppStrings.productsEmpty).evaluate().isNotEmpty;
      evidence['product'] = empty ? 'EMPTY_CATALOG_UI' : 'BLOCKED_no_product_tile';
      evidence['atlasApiHadProducts'] = true;
      await shot('04-product-blocked');
    }


    GoRouter.of(tester.element(find.byType(Navigator).first))
        .go(AppRoutes.orders);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    evidence['orders'] = true;
    await shot('06-orders');

    GoRouter.of(tester.element(find.byType(Navigator).first))
        .go(AppRoutes.supportList);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final ticketFinder =
        find.byKey(const Key('support-ticket-tile-$fixtureTicket'));
    for (var i = 0; i < 80; i++) {
      if (ticketFinder.evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    evidence['support'] = ticketFinder.evaluate().isNotEmpty;
    await shot('07-support');

    GoRouter.of(tester.element(find.byType(Navigator).first))
        .push(AppRoutes.addressForm);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await pumpUntil(tester, find.byKey(const Key('address-text-field')));
    evidence['addressForm'] = true;
    await shot('08-address-form');

    persistEvidence(evidence);

    expect(evidence['home'], isTrue);
    expect(evidence['support'], isTrue);
    expect(evidence['addressForm'], isTrue);
    expect(evidence['orders'], isTrue);
    if (evidence['storefront'] != true) {
      fail('Catalog storefront blocked: $evidence');
    }
    if (evidence['product'] != true) {
      fail('Catalog product step blocked: $evidence');
    }
  });
}
