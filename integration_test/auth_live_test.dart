import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live development auth and session routing', (tester) async {
    final store = SecureSessionStore();
    await store.clear();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionStoreProvider.overrideWithValue(store)],
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
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField), '550667788');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    expect(find.textContaining('Renvoyer le code dans'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.errorForCode('AUTH_INVALID_OTP')),
      findsOneWidget,
    );

    final otpFile = File('/tmp/speedygo-dev-otp-last');
    expect(otpFile.existsSync(), isTrue);
    final code = otpFile.readAsStringSync().trim();
    expect(code.length, 6);
    expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);

    await tester.enterText(find.byType(TextField), code);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
    await tester.pumpAndSettle();

    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }

    if (find.text(AppStrings.fullNameLabel).evaluate().isNotEmpty ||
        find.text(AppStrings.profileTitle).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), 'Review User');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.continueLabel),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.homeGreeting('Review User')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, AppStrings.logout),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.logout));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.logoutConfirmTitle), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.logoutConfirmAction),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(await store.read(), isNull);
  });
}
