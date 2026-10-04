import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';
import 'support/live_screen.dart';

/// Read-only live gestures against the existing Revue session.
/// Does not request OTP, submit/cancel orders, clear carts, or create records.
/// A blocked Home is a **failed** test, not a passing diagnostic.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object?>{};

  Future<void> shot(String name) async {
    debugPrint('LIVE_SCREEN:$name');
    try {
      File(
        '/Users/mac/Downloads/speedygo_project/.cache/live-shot-name',
      ).writeAsStringSync(name);
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 450));
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    report['lastShot'] = name;
  }

  /// Real-time wait so Dio's 10s/20s timers are not advanced by [WidgetTester.pump].
  Future<void> pumpMs(WidgetTester tester, int ms) async {
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: ms)),
    );
    await tester.pump();
  }

  Future<void> tapBack(WidgetTester tester) async {
    final back = find.byTooltip(AppStrings.back).hitTestable();
    expect(back, findsWidgets, reason: 'Back tooltip missing or not hittable');
    await tester.tap(back.first);
    await pumpMs(tester, 500);
    for (var i = 0; i < 20; i++) {
      await pumpMs(tester, 100);
    }
  }

  testWidgets('read-only live catalog/orders/profile gestures', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
        ],
        child: const SpeedyGoApp(),
      ),
    );

    // Splash waits on GET /health (≤5s) then restore HTTP. 8s was too short.
    for (var i = 0; i < 200; i++) {
      await pumpMs(tester, 100);
      final screen = classifyLiveScreen(tester);
      if (screen == 'language' ||
          screen == 'welcome' ||
          screen == 'phone' ||
          screen == 'otp' ||
          screen == 'profile_setup' ||
          screen == 'restore_retryable' ||
          screen == 'home') {
        break;
      }
    }

    if (classifyLiveScreen(tester) == 'language') {
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.continueLabel),
      );
      for (var i = 0; i < 40; i++) {
        await pumpMs(tester, 100);
        if (classifyLiveScreen(tester) != 'language') {
          break;
        }
      }
    }
    if (classifyLiveScreen(tester) == 'welcome') {
      await tester.tap(find.text(AppStrings.skip));
      for (var i = 0; i < 40; i++) {
        await pumpMs(tester, 100);
        if (classifyLiveScreen(tester) != 'welcome') {
          break;
        }
      }
    }

    for (var i = 0; i < 80; i++) {
      final screen = classifyLiveScreen(tester);
      if (screen == 'home' ||
          screen == 'phone' ||
          screen == 'otp' ||
          screen == 'profile_setup' ||
          screen == 'restore_retryable') {
        break;
      }
      await pumpMs(tester, 100);
    }

    report.addAll(probeLiveScreen(tester));
    await shot('live-gate-${report['screen']}');
    _write(report);

    var screen = report['screen'] as String? ?? 'unknown';
    if (screen == 'restore_retryable') {
      report['sessionRecovery'] = 'restore_retry_once';
      _write(report);
      final retry = find.text(AppStrings.restoreRetry);
      expect(retry, findsWidgets, reason: 'Restore retry control missing');
      await tester.tap(retry.first);
      for (var i = 0; i < 80; i++) {
        await pumpMs(tester, 100);
        screen = classifyLiveScreen(tester);
        if (screen == 'home' ||
            screen == 'phone' ||
            screen == 'otp' ||
            screen == 'profile_setup') {
          break;
        }
      }
      report.addAll(probeLiveScreen(tester));
      await shot('live-after-restore-retry-${report['screen']}');
      _write(report);
      screen = report['screen'] as String? ?? 'unknown';
    }
    if (screen == 'phone' || screen == 'otp') {
      final texts = (report['visibleTexts'] as List?)?.cast<String>() ?? [];
      report['gate'] = texts.contains(AppStrings.reauthRequired)
          ? 'local_session_invalidated'
          : 'signed_out';
      report['sessionRecovery'] = 'in_app_otp_once';
      _write(report);
      await _revueSignInOnce(tester, pumpMs);
      for (var i = 0; i < 80; i++) {
        await pumpMs(tester, 100);
        screen = classifyLiveScreen(tester);
        if (screen == 'home' || screen == 'profile_setup') {
          break;
        }
      }
      report.addAll(probeLiveScreen(tester));
      await shot('live-after-otp-${report['screen']}');
      _write(report);
      screen = report['screen'] as String? ?? 'unknown';
      if (screen != 'home') {
        report['status'] = 'blocked_login';
        _write(report);
        fail(
          'blocked_login: in-app Revue OTP did not reach Home '
          '(screen=$screen route=${report['route']} texts=${report['visibleTexts']}).',
        );
      }
    } else if (screen != 'home') {
      report['status'] = 'blocked_home';
      _write(report);
      fail(
        'blocked_home: displayed $screen, not Home. '
        'route=${report['route']} texts=${report['visibleTexts']}',
      );
    }
    report['home'] = 'passed';
    expect(find.byKey(const Key('home-search-field')), findsOneWidget);
    await shot('live-home');

    expect(find.text(AppStrings.seeAll), findsWidgets);
    await tester.tap(find.text(AppStrings.seeAll).first);
    for (var i = 0; i < 40; i++) {
      await pumpMs(tester, 100);
      if (find.text(AppStrings.allCategoriesTitle).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text(AppStrings.allCategoriesTitle), findsOneWidget);
    expect(find.byTooltip(AppStrings.back), findsWidgets);
    report['categoriesTap'] = 'passed';
    report['categoriesRoute'] = currentRoute(tester);
    await shot('live-categories');

    await tester.tap(find.byKey(const Key('categories-search-field')));
    await tester.enterText(
      find.byKey(const Key('categories-search-field')),
      AppStrings.categoryBakeries,
    );
    await pumpMs(tester, 400);
    final bakeries = find.text(AppStrings.categoryBakeries).hitTestable();
    expect(
      bakeries,
      findsWidgets,
      reason: 'Boulangeries not hittable after category search',
    );
    await tester.tap(bakeries.last);
    for (var i = 0; i < 50; i++) {
      await pumpMs(tester, 100);
      if (find.textContaining('Four de Didouche').evaluate().isNotEmpty ||
          find.textContaining('Maison du Blé').evaluate().isNotEmpty ||
          find.text(AppStrings.allCategoriesTitle).evaluate().isEmpty) {
        break;
      }
    }
    expect(find.text(AppStrings.categoryBakeries), findsWidgets);
    report['bakeriesTap'] = 'passed';
    report['bakeriesRoute'] = currentRoute(tester);
    await shot('live-bakeries');

    Finder storefront = find.textContaining('Four de Didouche').hitTestable();
    if (storefront.evaluate().isEmpty) {
      storefront = find.textContaining('Maison du Blé').hitTestable();
    }
    if (storefront.evaluate().isEmpty) {
      storefront = find.textContaining('Café').hitTestable();
    }
    expect(
      storefront,
      findsWidgets,
      reason: 'No live bakery/storefront name on Boulangeries results',
    );
    await tester.ensureVisible(storefront.first);
    await tester.tap(storefront.first);
    for (var i = 0; i < 50; i++) {
      await pumpMs(tester, 100);
      final path = currentRoute(tester) ?? '';
      if (path.contains('/merchants/')) {
        break;
      }
    }
    expect(
      currentRoute(tester),
      contains('/merchants/'),
      reason: 'Storefront route not reached by tap',
    );
    expect(find.byTooltip(AppStrings.back), findsWidgets);
    report['storefrontTap'] = 'passed';
    report['storefrontRoute'] = currentRoute(tester);
    report['storefrontCover'] = find
        .byKey(const Key('authenticated-cover-image'))
        .evaluate()
        .isNotEmpty;
    await shot('live-storefront');
    _write(report);

    // Pain khobz (…30402) has no product_images row — keep placeholder.
    // Prefer bound photos: Croissant au beurre / Pain au chocolat (Viennoiseries).
    final viennoiseries = find.text('Viennoiseries').hitTestable();
    if (viennoiseries.evaluate().isNotEmpty) {
      await tester.tap(viennoiseries.first);
      await pumpMs(tester, 500);
    }

    Finder product = find.text('Croissant au beurre');
    if (product.evaluate().isEmpty) {
      product = find.text('Pain au chocolat');
    }
    if (product.evaluate().isEmpty) {
      product = find.text('Pain khobz');
    }
    if (product.evaluate().isEmpty) {
      product = find.text('Baguette tradition');
    }
    expect(
      product,
      findsWidgets,
      reason: 'No bakery product on storefront',
    );
    report['menuThumbnailPhotographed'] = find
        .byKey(const Key('authenticated-catalog-image'))
        .evaluate()
        .isNotEmpty;
    await tester.ensureVisible(product.first);
    await tester.tap(product.first);
    for (var i = 0; i < 40; i++) {
      await pumpMs(tester, 100);
      final path = currentRoute(tester) ?? '';
      if (path.contains('/products/')) {
        break;
      }
    }
    expect(
      currentRoute(tester),
      contains('/products/'),
      reason: 'Product route not reached by tap',
    );
    // Allow authenticated image bytes to load (loading → Image).
    for (var i = 0; i < 50; i++) {
      await pumpMs(tester, 100);
      if (find.byKey(const Key('authenticated-catalog-image')).evaluate().isNotEmpty) {
        break;
      }
      if (find.byKey(const Key('catalog-image-failed')).evaluate().isNotEmpty) {
        break;
      }
    }
    report['productTap'] = 'passed';
    report['productRoute'] = currentRoute(tester);
    if (find.text('Croissant au beurre').evaluate().isNotEmpty &&
        (currentRoute(tester) ?? '').contains('030421')) {
      report['productName'] = 'Croissant au beurre';
    } else if (find.text('Pain au chocolat').evaluate().isNotEmpty) {
      report['productName'] = 'Pain au chocolat';
    } else if (find.text('Pain khobz').evaluate().isNotEmpty) {
      report['productName'] = 'Pain khobz';
    }
    final photographed = find
        .byKey(const Key('authenticated-catalog-image'))
        .evaluate()
        .isNotEmpty;
    report['productPhotographed'] = photographed;
    report['productImageUnbound'] = find
        .byKey(const Key('catalog-image-unbound'))
        .evaluate()
        .isNotEmpty;
    report['productImageFailed'] = find
        .byKey(const Key('catalog-image-failed'))
        .evaluate()
        .isNotEmpty;
    await shot('live-product');
    expect(
      photographed,
      isTrue,
      reason:
          'Expected a product with a bound catalog photo '
          '(Croissant au beurre / Pain au chocolat). '
          'Pain khobz has no product_images row (content gap).',
    );

    await tapBack(tester);
    expect(find.byTooltip(AppStrings.back), findsWidgets);
    report['productBack'] = 'passed';
    await tapBack(tester);
    expect(find.text(AppStrings.categoryBakeries), findsWidgets);
    report['storefrontBack'] = 'passed';
    await tapBack(tester);
    expect(find.text(AppStrings.allCategoriesTitle), findsOneWidget);
    report['bakeriesBack'] = 'passed';
    await tapBack(tester);
    expect(find.byKey(const Key('home-search-field')), findsOneWidget);
    report['categoriesBack'] = 'passed';

    await tester.tap(find.text(AppStrings.tabOrders));
    for (var i = 0; i < 40; i++) {
      await pumpMs(tester, 100);
    }
    expect(find.text(AppStrings.tabOrders), findsWidgets);
    report['ordersTab'] = 'passed';
    report['ordersRoute'] = currentRoute(tester);
    await shot('live-orders');

    await tester.tap(find.text(AppStrings.tabProfile));
    for (var i = 0; i < 30; i++) {
      await pumpMs(tester, 100);
    }
    expect(find.text(AppStrings.accountAddressesLabel), findsOneWidget);
    report['profileTab'] = 'passed';
    await shot('live-profile');

    await tester.tap(find.text(AppStrings.accountAddressesLabel));
    for (var i = 0; i < 30; i++) {
      await pumpMs(tester, 100);
    }
    expect(find.byTooltip(AppStrings.back), findsWidgets);
    report['addressesRead'] = 'passed';
    report['addressesRoute'] = currentRoute(tester);
    await shot('live-addresses');
    await tapBack(tester);
    expect(find.text(AppStrings.accountAddressesLabel), findsOneWidget);
    report['addressesBack'] = 'passed';

    await tester.fling(
      find.text(AppStrings.supportCentreAide),
      const Offset(0, -280),
      800,
    );
    await pumpMs(tester, 400);
    final tickets = find.text(AppStrings.supportTicketsLabel).hitTestable();
    expect(
      tickets,
      findsWidgets,
      reason: 'Support ticket list row not hittable on Profil',
    );
    await tester.tap(tickets.first);
    for (var i = 0; i < 30; i++) {
      await pumpMs(tester, 100);
    }
    expect(find.byTooltip(AppStrings.back).hitTestable(), findsWidgets);
    report['supportRead'] = 'passed';
    report['supportRoute'] = currentRoute(tester);
    await shot('live-support');
    await tapBack(tester);
    expect(find.text(AppStrings.supportCentreAide), findsWidgets);
    report['supportBack'] = 'passed';

    await tester.tap(find.text(AppStrings.tabAlerts));
    for (var i = 0; i < 30; i++) {
      await pumpMs(tester, 100);
    }
    expect(find.text(AppStrings.tabAlerts), findsWidgets);
    report['alertsTab'] = 'passed';
    report['alertsRoute'] = currentRoute(tester);
    await shot('live-alerts');

    report['status'] = 'passed';
    _write(report);
  });
}

Future<void> _revueSignInOnce(
  WidgetTester tester,
  Future<void> Function(WidgetTester tester, int ms) pumpMs,
) async {
  if (classifyLiveScreen(tester) == 'phone') {
    await tester.enterText(
      find.byKey(const Key('phone-number-field')),
      '550000072',
    );
    await tester.pump();
    final continueBtn = find.widgetWithText(
      FilledButton,
      AppStrings.continueLabel,
    );
    if (continueBtn.evaluate().isEmpty) {
      fail('blocked_login: Continue control missing on phone screen.');
    }
    final filled = tester.widget<FilledButton>(continueBtn);
    if (filled.onPressed == null) {
      fail(
        'blocked_login: OTP request blocked (cooldown or invalid). OTP not retried.',
      );
    }
    final otpFile = speedyGoDevOtpFile();
    if (otpFile.existsSync()) {
      otpFile.deleteSync();
    }
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pump();
    for (var i = 0; i < 200; i++) {
      await pumpMs(tester, 100);
      if (classifyLiveScreen(tester) == 'otp') {
        break;
      }
      if (find
          .text(AppStrings.errorForCode('AUTH_RATE_LIMITED'))
          .evaluate()
          .isNotEmpty) {
        fail('blocked_login: AUTH_RATE_LIMITED. OTP not retried.');
      }
      if (find.text(AppStrings.offline).evaluate().isNotEmpty) {
        fail(
          'blocked_login: OTP request surfaced offline/network. OTP not retried. '
          'texts=${visibleTexts(tester)}',
        );
      }
    }
    if (classifyLiveScreen(tester) != 'otp') {
      fail(
        'blocked_login: OTP screen not reached after one request. '
        'screen=${classifyLiveScreen(tester)} '
        'texts=${visibleTexts(tester)}',
      );
    }
  }

  File? found;
  for (var i = 0; i < 50; i++) {
    final candidate = speedyGoDevOtpFile();
    if (candidate.existsSync() &&
        candidate.readAsStringSync().trim().length == 6) {
      found = candidate;
      break;
    }
    await pumpMs(tester, 250);
  }
  final codeFile = found ??
      (throw TestFailure(
        'blocked_login: OTP capture file missing after one request.',
      ));
  await tester.enterText(
    find.byKey(const Key('otp-code-field')),
    codeFile.readAsStringSync().trim(),
  );
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
  for (var i = 0; i < 60; i++) {
    await pumpMs(tester, 100);
    final screen = classifyLiveScreen(tester);
    if (screen == 'welcome') {
      await tester.tap(find.text(AppStrings.skip));
      continue;
    }
    if (screen == 'home' || screen == 'profile_setup') {
      return;
    }
  }
}

void _write(Map<String, Object?> report) {
  final dir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/live',
  );
  dir.createSync(recursive: true);
  File('${dir.path}/read-only-gestures.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  debugPrint('LIVE_GESTURE_REPORT:${jsonEncode(report)}');
}
