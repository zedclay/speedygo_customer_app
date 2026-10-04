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

/// Focused read-only proof that a **bound** product photo loads.
/// Pain khobz (…30402) has no `product_images` row — content gap, not a bug.
/// Prefer Croissant au beurre / Pain au chocolat under Viennoiseries.
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

  Future<void> pumpMs(WidgetTester tester, int ms) async {
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: ms)),
    );
    await tester.pump();
  }

  void writeReport() {
    final dir = Directory(
      '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/live',
    );
    dir.createSync(recursive: true);
    File('${dir.path}/product-photo-gestures.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(report),
    );
  }

  testWidgets('live bound product photo on Four de Didouche', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
        ],
        child: const SpeedyGoApp(),
      ),
    );

    // Same gate as audit_live_read_gestures_test: wait through splash/restore.
    for (var i = 0; i < 300; i++) {
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

    for (var i = 0; i < 120; i++) {
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
    await shot('live-photo-gate-${report['screen']}');
    writeReport();

    var screen = report['screen'] as String? ?? 'unknown';
    if (screen == 'restore_retryable') {
      final retry = find.text(AppStrings.restoreRetry);
      expect(retry, findsWidgets);
      await tester.tap(retry.first);
      for (var i = 0; i < 120; i++) {
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
      await shot('live-photo-after-retry-${report['screen']}');
      writeReport();
      screen = report['screen'] as String? ?? 'unknown';
    }
    if (screen == 'phone' || screen == 'otp') {
      report['sessionRecovery'] = 'in_app_otp_once';
      writeReport();
      await _revueSignInOnce(tester, pumpMs);
      for (var i = 0; i < 120; i++) {
        await pumpMs(tester, 100);
        screen = classifyLiveScreen(tester);
        if (screen == 'home' || screen == 'profile_setup') {
          break;
        }
      }
      report.addAll(probeLiveScreen(tester));
      await shot('live-photo-after-otp-${report['screen']}');
      writeReport();
      screen = report['screen'] as String? ?? 'unknown';
    }
    if (screen != 'home') {
      report['status'] = 'blocked_home';
      writeReport();
      fail(
        'blocked_home: displayed $screen, not Home. '
        'route=${report['route']} texts=${report['visibleTexts']}',
      );
    }

    for (var i = 0; i < 80; i++) {
      await pumpMs(tester, 100);
      if (find.text(AppStrings.seeAll).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const Key('home-search-field')), findsOneWidget);
    expect(find.text(AppStrings.seeAll), findsWidgets);
    report['home'] = 'passed';
    await shot('live-photo-home');

    await tester.tap(find.text(AppStrings.seeAll).first);
    for (var i = 0; i < 40; i++) {
      await pumpMs(tester, 100);
      if (find.text(AppStrings.allCategoriesTitle).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.byKey(const Key('categories-search-field')));
    await tester.enterText(
      find.byKey(const Key('categories-search-field')),
      AppStrings.categoryBakeries,
    );
    await pumpMs(tester, 400);
    final bakeries = find.text(AppStrings.categoryBakeries).hitTestable();
    expect(bakeries, findsWidgets);
    await tester.tap(bakeries.last);
    for (var i = 0; i < 50; i++) {
      await pumpMs(tester, 100);
      if (find.textContaining('Four de Didouche').evaluate().isNotEmpty) {
        break;
      }
    }

    final storefront = find.textContaining('Four de Didouche').hitTestable();
    expect(storefront, findsWidgets);
    await tester.ensureVisible(storefront.first);
    await tester.tap(storefront.first);
    for (var i = 0; i < 50; i++) {
      await pumpMs(tester, 100);
      if ((currentRoute(tester) ?? '').contains('/merchants/')) {
        break;
      }
    }
    expect(currentRoute(tester), contains('/merchants/'));
    report['storefrontRoute'] = currentRoute(tester);
    await shot('live-photo-storefront');

    // Category chips may still be loading; scroll the chip row if needed.
    Finder viennoiseries = find.text('Viennoiseries');
    for (var i = 0; i < 40; i++) {
      await pumpMs(tester, 100);
      if (viennoiseries.evaluate().isNotEmpty) {
        break;
      }
    }
    if (viennoiseries.evaluate().isNotEmpty &&
        viennoiseries.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(viennoiseries.first);
      await pumpMs(tester, 300);
      final chips = find.byType(Scrollable);
      if (chips.evaluate().isNotEmpty) {
        await tester.drag(chips.first, const Offset(-180, 0));
        await pumpMs(tester, 300);
      }
    }
    viennoiseries = find.text('Viennoiseries').hitTestable();
    if (viennoiseries.evaluate().isEmpty) {
      // Fall back: product may already be on Tous.
      viennoiseries = find.text('Tous').hitTestable();
      if (viennoiseries.evaluate().isNotEmpty) {
        await tester.tap(viennoiseries.first);
        await pumpMs(tester, 400);
      }
    } else {
      expect(
        viennoiseries,
        findsWidgets,
        reason: 'Viennoiseries chip required for photographed products',
      );
      await tester.tap(viennoiseries.first);
      await pumpMs(tester, 600);
    }

    Finder product = find.text('Croissant au beurre');
    var productName = 'Croissant au beurre';
    for (var i = 0; i < 30; i++) {
      await pumpMs(tester, 100);
      if (product.evaluate().isNotEmpty) {
        break;
      }
    }
    if (product.evaluate().isEmpty) {
      product = find.text('Pain au chocolat');
      productName = 'Pain au chocolat';
    }
    product = product.hitTestable();
    expect(
      product,
      findsWidgets,
      reason: 'Bound-photo product not visible under Viennoiseries/Tous',
    );

    for (var i = 0; i < 40; i++) {
      await pumpMs(tester, 100);
      if (find
          .byKey(const Key('authenticated-catalog-image'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    report['menuThumbnailPhotographed'] = find
        .byKey(const Key('authenticated-catalog-image'))
        .evaluate()
        .isNotEmpty;
    expect(
      report['menuThumbnailPhotographed'],
      isTrue,
      reason: 'Menu thumbnail for $productName should load bound JPEG',
    );
    await shot('live-photo-menu');

    await tester.ensureVisible(product.first);
    await tester.tap(product.first);
    for (var i = 0; i < 50; i++) {
      await pumpMs(tester, 100);
      if ((currentRoute(tester) ?? '').contains('/products/')) {
        break;
      }
    }
    expect(currentRoute(tester), contains('/products/'));
    for (var i = 0; i < 50; i++) {
      await pumpMs(tester, 100);
      if (find
          .byKey(const Key('authenticated-catalog-image'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      if (find.byKey(const Key('catalog-image-failed')).evaluate().isNotEmpty) {
        break;
      }
    }

    report['productName'] = productName;
    report['productRoute'] = currentRoute(tester);
    report['productPhotographed'] = find
        .byKey(const Key('authenticated-catalog-image'))
        .evaluate()
        .isNotEmpty;
    report['productImageUnbound'] = find
        .byKey(const Key('catalog-image-unbound'))
        .evaluate()
        .isNotEmpty;
    report['productImageFailed'] = find
        .byKey(const Key('catalog-image-failed'))
        .evaluate()
        .isNotEmpty;
    report['painKhobzContentGap'] =
        'Pain khobz …30402 has no product_images row; placeholder is correct';
    await shot('live-photo-product');
    writeReport();

    expect(
      report['productPhotographed'],
      isTrue,
      reason:
          'Product detail for $productName must show authenticated-catalog-image',
    );
    expect(
      report['productImageFailed'],
      isFalse,
      reason: 'Bound product image must not fail HTTP/content-type checks',
    );
    // Storefront behind may still expose unbound placeholders (e.g. Pain khobz).
    report['status'] = 'passed';
    writeReport();
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
          'blocked_login: OTP request surfaced offline/network. OTP not retried.',
        );
      }
    }
    if (classifyLiveScreen(tester) != 'otp') {
      fail(
        'blocked_login: OTP screen not reached after one request. '
        'screen=${classifyLiveScreen(tester)} texts=${visibleTexts(tester)}',
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
