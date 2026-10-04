import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/presentation/splash_screen.dart';

import '../helpers/fakes.dart';

void _iphoneSe(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 40, bottom: 0);
  addTearDown(tester.view.reset);
}

Widget _splashApp({
  bool animate = true,
  Duration splashMin = const Duration(seconds: 2),
}) {
  return ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(onboardingSeen: true, languageSeen: true),
      ),
      splashMinDurationProvider.overrideWithValue(splashMin),
      splashAnimateProvider.overrideWithValue(animate),
      authApiProvider.overrideWithValue(FakeAuthClient()),
      customerApiProvider.overrideWithValue(FakeCustomerClient()),
    ],
    child: const SpeedyGoApp(),
  );
}

Future<void> _pumpUntilPhone(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('phone screen did not appear');
}

double _flipProgress(WidgetTester tester) {
  final builder = tester.widget<AnimatedBuilder>(
    find.byKey(const Key('splash-logo-flip')),
  );
  return (builder.animation as Animation<double>).value;
}

void main() {
  testWidgets('splash fits iPhone SE without overflow or loading copy', (
    tester,
  ) async {
    _iphoneSe(tester);
    await tester.pumpWidget(
      _splashApp(animate: false, splashMin: const Duration(seconds: 2)),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(find.byKey(const Key('splash-loader')), findsOneWidget);
    expect(find.byKey(const Key('splash-logo-flip')), findsNothing);
    expect(find.byKey(const Key('splash-logo-back')), findsNothing);
    expect(find.text(AppStrings.splashLoading), findsNothing);
    expect(find.textContaining('VERSION'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await _pumpUntilPhone(tester);
  });

  testWidgets('reduced motion keeps the front face static', (tester) async {
    _iphoneSe(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(
          disableAnimations: true,
          reduceMotion: true,
        );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_splashApp(splashMin: const Duration(seconds: 2)));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('splash-logo-flip')), findsNothing);
    expect(find.byKey(const Key('splash-logo-back')), findsNothing);
    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await _pumpUntilPhone(tester);
  });

  testWidgets('logo flips on the Y-axis; back face has no lettering', (
    tester,
  ) async {
    _iphoneSe(tester);
    await tester.pumpWidget(_splashApp(splashMin: const Duration(seconds: 3)));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('splash-logo-flip')), findsOneWidget);
    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(find.byKey(const Key('splash-logo-back')), findsNothing);
    expect(_flipProgress(tester), closeTo(0, 0.02));

    await tester.pump(const Duration(seconds: 1));
    expect(_flipProgress(tester), closeTo(0.25, 0.02));
    expect(find.byKey(const Key('splash-logo-spin')), findsNothing);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(_flipProgress(tester), closeTo(0.5, 0.02));
    expect(find.byKey(const Key('splash-logo-back')), findsOneWidget);
    expect(find.byKey(const Key('splash-logo')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await _pumpUntilPhone(tester);
  });

  testWidgets('startup restore is not blocked by the flip', (tester) async {
    _iphoneSe(tester);
    await tester.pumpWidget(
      _splashApp(animate: true, splashMin: Duration.zero),
    );
    await tester.pump();
    await tester.pump();
    await _pumpUntilPhone(tester);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });
}
