import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

import '../test/helpers/fakes.dart';

Widget _app({
  required FakeAuthClient auth,
  required FakeCustomerClient customer,
  MemorySessionStore? store,
  bool onboardingSeen = true,
}) {
  return ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(store ?? MemorySessionStore()),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(
          onboardingSeen: onboardingSeen,
          languageSeen: onboardingSeen,
        ),
      ),
      splashMinDurationProvider.overrideWithValue(Duration.zero),
      authApiProvider.overrideWithValue(auth),
      customerApiProvider.overrideWithValue(customer),
    ],
    child: const SpeedyGoApp(),
  );
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    await binding.takeScreenshot(name);
  } catch (_) {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('visual review: welcome, phone, help, otp, profile, logout', (
    tester,
  ) async {
    final auth = FakeAuthClient();
    final customer = FakeCustomerClient();
    await tester.pumpWidget(
      _app(auth: auth, customer: customer, onboardingSeen: false),
    );
    await tester.pumpAndSettle();
    if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty) {
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.continueLabel),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
    await _shot(binding, '01-welcome-discover');

    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcomeOrderTitle), findsOneWidget);
    await _shot(binding, '02-welcome-order');

    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcomeTrackTitle), findsOneWidget);
    await _shot(binding, '03-welcome-track');

    await tester.tap(find.text(AppStrings.start));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '555123456');
    await tester.pump();
    await tester.showKeyboard(find.byType(TextField));
    await tester.pumpAndSettle();
    await _shot(binding, '04-phone-keyboard');

    await tester.tap(find.text(AppStrings.needHelp));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.helpUnavailable), findsOneWidget);
    await _shot(binding, '05-phone-help-snackbar');
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.showKeyboard(find.byType(TextField));
    await tester.pumpAndSettle();
    await _shot(binding, '06-otp-keyboard-empty');

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, AppStrings.verify),
    );
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
    await tester.pumpAndSettle();
    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining(AppStrings.fullNameLabel), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Review User');
    await tester.pumpAndSettle();
    await _shot(binding, '07-profile-keyboard');

    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
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
    await _shot(binding, '08-logout-sheet');
  });

  testWidgets('visual review: offline restore retry', (tester) async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final customer = FakeCustomerClient()
      ..meError = const NetworkException('offline');
    await tester.pumpWidget(
      _app(auth: FakeAuthClient(), customer: customer, store: store),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.restoreOfflineTitle), findsOneWidget);
    expect(find.text(AppStrings.restoreRetry), findsOneWidget);
    await _shot(binding, '09-restore-offline');
  });
}
