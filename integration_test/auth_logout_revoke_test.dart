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

  testWidgets('logout from a restored session returns to phone', (
    tester,
  ) async {
    final store = SecureSessionStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionStoreProvider.overrideWithValue(store)],
        child: const SpeedyGoApp(),
      ),
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
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.logoutConfirmAction),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(await store.read(), isNull);
  });
}
