import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/presentation/splash_screen.dart';

import '../test/helpers/fakes.dart';

/// Harness only. Production splash duration is unchanged.
Widget _harness() {
  return ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(onboardingSeen: true, languageSeen: true),
      ),
      splashMinDurationProvider.overrideWithValue(const Duration(seconds: 3)),
      splashAnimateProvider.overrideWithValue(true),
      authApiProvider.overrideWithValue(FakeAuthClient()),
      customerApiProvider.overrideWithValue(FakeCustomerClient()),
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

  testWidgets('splash logo flips then yields to phone', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    await _shot(binding, 'splash-00-upright');

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(SplashScreen), findsOneWidget);
    await _shot(binding, 'splash-01-quarter');

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(SplashScreen), findsOneWidget);
    await _shot(binding, 'splash-02-half');

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    await _shot(binding, 'splash-03-phone');
  });
}
