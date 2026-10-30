import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';

/// Live discovery screens against isolated :3017. Not mocked widgets.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    debugPrint('LIVE_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (error) {
      debugPrint('LIVE_SCREEN_FAIL:$name $error');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> settle(WidgetTester tester, {int frames = 40}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> waitFor(WidgetTester tester, Finder finder, {int frames = 50}) async {
    for (var i = 0; i < frames; i++) {
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    return finder.evaluate().isNotEmpty;
  }

  testWidgets('live discovery home search promotions favorites', (tester) async {
    final store = SecureSessionStore();
    await store.clear();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester);

    for (var i = 0; i < 40; i++) {
      if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
        break;
      }
      if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty) {
        await tester.tap(
          find.widgetWithText(FilledButton, AppStrings.continueLabel),
        );
        await settle(tester);
      }
      if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.skip));
        await settle(tester);
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), '551987721');
      await tester.pump();
      final continueBtn = find.widgetWithText(
        FilledButton,
        AppStrings.continueLabel,
      );
      final otpFile = speedyGoDevOtpFile();
      if (otpFile.existsSync()) {
        otpFile.deleteSync();
      }
      for (var attempt = 0; attempt < 4; attempt++) {
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await settle(tester, frames: 20);
        if (find
            .widgetWithText(FilledButton, AppStrings.verify)
            .evaluate()
            .isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(seconds: 2));
      }
      expect(
        find.widgetWithText(FilledButton, AppStrings.verify),
        findsOneWidget,
      );
      for (var i = 0; i < 40; i++) {
        if (otpFile.existsSync() &&
            RegExp(r'^\d{6}$').hasMatch(otpFile.readAsStringSync().trim())) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(otpFile.existsSync(), isTrue);
      final code = otpFile.readAsStringSync().trim();
      expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
      await tester.enterText(find.byType(TextField), code);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
      await settle(tester, frames: 50);
    }

    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await settle(tester);
    }
    if (find.textContaining(AppStrings.fullNameLabel).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), 'Discovery Isolated');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.continueLabel),
      );
      await settle(tester, frames: 40);
    }

    expect(find.text(AppStrings.searchHint), findsWidgets);
    expect(find.text(AppStrings.tabHome), findsOneWidget);
    await settle(tester, frames: 20);
    await shot('sim-home');

    if (find.byKey(const Key('home-promo-open')).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.byKey(const Key('home-promo-open')));
      await tester.tap(find.byKey(const Key('home-promo-open')));
      await settle(tester, frames: 30);
      expect(find.text(AppStrings.promotionsTitle), findsOneWidget);
      await shot('sim-promotions');
      final promoBack = find.byIcon(Icons.arrow_back);
      expect(promoBack, findsWidgets);
      await tester.tap(promoBack.first);
      await settle(tester, frames: 20);
    } else {
      fail('home promo banner missing — isolated promotions expected');
    }

    await tester.tap(find.text(AppStrings.tabSearch));
    await settle(tester, frames: 30);
    expect(find.byKey(const Key('search-query-field')), findsOneWidget);
    await waitFor(tester, find.text(AppStrings.searchSuggestions), frames: 30);
    await shot('sim-search-idle');

    await tester.enterText(find.byKey(const Key('search-query-field')), 'ca');
    await tester.pump();
    await settle(tester, frames: 40);
    expect(find.text(AppStrings.searchMerchantsTab), findsOneWidget);
    expect(find.text(AppStrings.searchProductsTab), findsOneWidget);
    expect(find.byKey(const Key('search-result-count')), findsOneWidget);
    expect(find.text(AppStrings.searchSortName), findsOneWidget);
    await shot('sim-search-results');

    await tester.tap(find.byKey(const Key('search-filters-button')));
    await settle(tester, frames: 15);
    expect(find.byKey(const Key('search-filter-open-now')), findsOneWidget);
    await tester.tap(find.byKey(const Key('search-filter-open-now')));
    await settle(tester, frames: 30);
    await shot('sim-search-results-open-now');

    final heart = find.byIcon(Icons.favorite_border);
    if (heart.evaluate().isNotEmpty) {
      await tester.tap(heart.first);
      await settle(tester, frames: 20);
    }

    await tester.tap(find.text(AppStrings.tabProfile));
    await settle(tester, frames: 20);
    await tester.tap(find.byKey(const Key('account-favorites')));
    await settle(tester, frames: 30);
    expect(find.byKey(const Key('favorites-screen')), findsOneWidget);
    expect(find.text(AppStrings.favoritesTitle), findsWidgets);
    await shot('sim-favorites');

    final back = find.byIcon(Icons.arrow_back);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first);
      await settle(tester, frames: 15);
    }
    await tester.tap(find.byKey(const Key('account-language')));
    await settle(tester, frames: 20);
    await tester.tap(find.byKey(const Key('language-option-ar')));
    await settle(tester, frames: 8);
    await tester.tap(find.text(AppStrings.languageSave));
    await settle(tester, frames: 20);
    await tester.tap(find.text(AppStrings.tabHome));
    await settle(tester, frames: 20);
    await shot('sim-home-ar');
    await tester.tap(find.text(AppStrings.tabProfile));
    await settle(tester, frames: 15);
    await tester.tap(find.byKey(const Key('account-language')));
    await settle(tester, frames: 20);
    await tester.tap(find.byKey(const Key('language-option-fr')));
    await settle(tester, frames: 8);
    await tester.tap(find.text(AppStrings.languageSave));
    await settle(tester, frames: 20);
    await tester.tap(find.text(AppStrings.tabHome));
    await settle(tester, frames: 20);
  });
}
