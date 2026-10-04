import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';

/// Live Home → search → storefront → product against 127.0.0.1:3000.
/// Screenshots are named `live-populated-*` to distinguish mocked review shots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    debugPrint('LIVE_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  testWidgets('live home search storefront product and back', (tester) async {
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
      if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
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
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField), '550667788');
    await tester.pump();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.otpTitle), findsOneWidget);

    final otpFile = speedyGoDevOtpFile();
    for (var i = 0; i < 20; i++) {
      if (otpFile.existsSync() && otpFile.readAsStringSync().trim().length == 6) {
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
    await tester.pumpAndSettle();

    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
    if (find.textContaining(AppStrings.fullNameLabel).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), 'Review User');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.continueLabel),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text('Demo Cafe Hydra'), findsOneWidget);
    expect(find.text(AppStrings.storefrontsEmpty), findsNothing);
    await shot('live-populated-home');

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'es');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Espresso Demo'), findsOneWidget);
    expect(find.text(MoneyFormat.dzd('1200')), findsWidgets);
    await shot('live-populated-search');

    await tester.tap(find.text('Espresso Demo'));
    await tester.pumpAndSettle();
    expect(find.textContaining(AppStrings.customizeProduct), findsWidgets);
    expect(find.text(MoneyFormat.dzd('1200')), findsWidgets);
    expect(find.text('Taille Demo'), findsOneWidget);
    await shot('live-populated-product-from-search');

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo Cafe Hydra'));
    await tester.pumpAndSettle();
    expect(find.text('Boissons Demo'), findsOneWidget);
    expect(find.text('Espresso Demo'), findsOneWidget);
    await shot('live-populated-storefront');

    await tester.tap(find.text('Espresso Demo'));
    await tester.pumpAndSettle();
    expect(find.text(MoneyFormat.dzd('1200')), findsWidgets);
    expect(find.text(MoneyFormat.dzd('200')), findsOneWidget);
    await shot('live-populated-product');

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text('Demo Cafe Hydra'), findsOneWidget);
  });
}
