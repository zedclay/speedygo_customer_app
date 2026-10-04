import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';

/// Live Home categories + API cover. Screenshots under live-* only.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    debugPrint('LIVE_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  testWidgets('live home category filter and api cover', (tester) async {
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
    await tester.pumpAndSettle();
    for (var i = 0; i < 40; i++) {
      if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
        break;
      }
      if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty) {
        await tester.tap(
          find.widgetWithText(FilledButton, AppStrings.continueLabel),
        );
        await tester.pumpAndSettle();
      }
      if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.skip));
        await tester.pumpAndSettle();
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), '550667788');
      await tester.pump();
      final continueBtn = find.widgetWithText(
        FilledButton,
        AppStrings.continueLabel,
      );
      final otpFile = speedyGoDevOtpFile();
      for (var attempt = 0; attempt < 4; attempt++) {
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();
        if (find
            .widgetWithText(FilledButton, AppStrings.verify)
            .evaluate()
            .isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(seconds: 25));
      }
      for (var i = 0; i < 20; i++) {
        if (otpFile.existsSync() &&
            otpFile.readAsStringSync().trim().length == 6) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.enterText(
        find.byType(TextField),
        otpFile.readAsStringSync().trim(),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
      await tester.pumpAndSettle();
    }

    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.categories), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('DEMO Cover Hydra'), findsWidgets);
    await shot('live-home-categories');

    await tester.tap(find.text('Restaurants'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('DEMO Cover Hydra'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('authenticated-cover-image')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.text('DEMO Cover Hydra'), findsOneWidget);
    await shot('live-home-category-filtered');

    const demoBranchId = '687501cc-cee8-4ce2-8dec-56c1a18bab4e';
    final card = find.byKey(const ValueKey(demoBranchId));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    for (var i = 0; i < 40; i++) {
      if (find.byKey(const Key('authenticated-cover-image')).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.text('DEMO Cover Hydra'), findsWidgets);
    expect(find.text(AppStrings.productsEmptyUnfiltered), findsOneWidget);
    await shot('live-storefront-api-cover');
    await shot('live-storefront-empty');

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.searchHint));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Demo Cafe');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Demo Cafe Hydra'), findsWidgets);
    await tester.tap(find.text('Demo Cafe Hydra').first);
    await tester.pumpAndSettle();
    expect(find.text('Demo Cafe Hydra'), findsWidgets);
    expect(find.text(AppStrings.productsEmptyUnfiltered), findsNothing);
    expect(find.text('Espresso Demo'), findsOneWidget);
    await shot('live-storefront-with-products');
  });
}
