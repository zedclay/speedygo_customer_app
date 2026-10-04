import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('existing customer reaches temporary home and keeps session', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [splashAnimateProvider.overrideWithValue(false)],
        child: const SpeedyGoApp(),
      ),
    );
    await tester.pumpAndSettle();

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

    if (find.text(AppStrings.phoneTitle).evaluate().isEmpty) {
      expect(find.text(AppStrings.searchHint), findsOneWidget);
      return;
    }

    await tester.enterText(find.byType(TextField), '550667788');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();

    if (find.text(AppStrings.otpTitle).evaluate().isNotEmpty) {
      final code = speedyGoDevOtpFile().readAsStringSync().trim();
      await tester.enterText(find.byType(TextField), code);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
      await tester.pumpAndSettle();
    }

    expect(find.text(AppStrings.welcomeDiscoverTitle), findsNothing);
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.textContaining('👋'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}
