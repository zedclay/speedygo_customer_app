import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

import '../helpers/fakes.dart';
import '../widget_test.dart' as host;

void _iphoneSe(WidgetTester tester, {double keyboard = 0}) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 40, bottom: 0);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

Future<void> _pumpOut(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('welcome slides fit iPhone SE without overflow', (tester) async {
    _iphoneSe(tester);
    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        onboardingSeen: false,
        languageSeen: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(AppStrings.welcomeDiscoverEyebrow), findsOneWidget);
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
    expect(find.text(AppStrings.welcomeWordmark), findsOneWidget);
    expect(find.text(AppStrings.skip), findsOneWidget);
    expect(find.text(AppStrings.next), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/onboarding/discover.png')),
      findsOneWidget,
    );
    await tester.tap(find.text(AppStrings.next));
    await _pumpOut(tester);
    expect(find.text(AppStrings.welcomeOrderEyebrow), findsOneWidget);
    expect(find.text(AppStrings.welcomeOrderTitle), findsOneWidget);
    expect(find.text(AppStrings.skip), findsOneWidget);
    expect(find.text(AppStrings.next), findsOneWidget);
    await tester.tap(find.text(AppStrings.next));
    await _pumpOut(tester);
    expect(find.text(AppStrings.welcomeTrackEyebrow), findsOneWidget);
    expect(find.text(AppStrings.welcomeTrackTitle), findsOneWidget);
    expect(find.text(AppStrings.welcomeTrackLiveTitle), findsNothing);
    expect(find.text(AppStrings.skip), findsNothing);
    expect(find.text(AppStrings.start), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(280, 0));
    await _pumpOut(tester);
    expect(find.text(AppStrings.welcomeOrderEyebrow), findsOneWidget);
    expect(find.text(AppStrings.skip), findsOneWidget);
    await tester.tap(find.text(AppStrings.skip));
    await _pumpOut(tester);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('welcome commencer reaches phone and does not replay', (
    tester,
  ) async {
    _iphoneSe(tester);
    final launch = MemoryLaunchStore(onboardingSeen: false, languageSeen: true);
    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        launch: launch,
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(AppStrings.next));
    await _pumpOut(tester);
    await tester.tap(find.text(AppStrings.next));
    await _pumpOut(tester);
    expect(find.text(AppStrings.start), findsOneWidget);
    final startTheme = Theme.of(
      tester.element(find.widgetWithText(FilledButton, AppStrings.start)),
    );
    expect(
      startTheme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.primary,
    );
    await tester.tap(find.text(AppStrings.start));
    await _pumpOut(tester);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        launch: launch,
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(AppStrings.welcomeDiscoverEyebrow), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('phone keyboard keeps continue and help visible', (tester) async {
    _iphoneSe(tester, keyboard: 336);
    await tester.pumpWidget(
      host.app(auth: FakeAuthClient(), customer: FakeCustomerClient()),
    );
    await _pumpOut(tester);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.text(AppStrings.continueLabel), findsOneWidget);
    expect(find.text(AppStrings.needHelp), findsOneWidget);
    await tester.tap(find.text(AppStrings.needHelp));
    await _pumpOut(tester);
    expect(find.text(AppStrings.helpUnavailable), findsOneWidget);
  });

  testWidgets('OTP keyboard keeps verify visible and cells empty', (
    tester,
  ) async {
    _iphoneSe(tester, keyboard: 336);
    await tester.pumpWidget(
      host.app(auth: FakeAuthClient(), customer: FakeCustomerClient()),
    );
    await _pumpOut(tester);
    await tester.enterText(find.byType(TextField), '555123456');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await _pumpOut(tester);
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
    expect(find.text(AppStrings.verify), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('OTP incorrect code shows fixture error without leaking a code', (
    tester,
  ) async {
    _iphoneSe(tester);
    final auth = FakeAuthClient()
      ..verifyError = ApiException(
        AppStrings.errorForCode('AUTH_INVALID_OTP'),
        code: 'AUTH_INVALID_OTP',
      );
    await tester.pumpWidget(
      host.app(auth: auth, customer: FakeCustomerClient()),
    );
    await _pumpOut(tester);
    await tester.enterText(find.byType(TextField), '555123456');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await _pumpOut(tester);
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
    await _pumpOut(tester);
    expect(
      find.text(AppStrings.errorForCode('AUTH_INVALID_OTP')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.otpTitle), findsOneWidget);
  });

  testWidgets('profile keyboard keeps continue visible', (tester) async {
    _iphoneSe(tester, keyboard: 336);
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: false,
        profileComplete: false,
        addressReady: false,
      );
    await tester.pumpWidget(
      host.app(auth: FakeAuthClient(), customer: customer, store: store),
    );
    await _pumpOut(tester);
    expect(find.textContaining(AppStrings.fullNameLabel), findsOneWidget);
    expect(find.text(AppStrings.continueLabel), findsOneWidget);
  });

  testWidgets('language screen fits iPhone SE and keeps Arabic disabled', (
    tester,
  ) async {
    _iphoneSe(tester);
    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        onboardingSeen: false,
        languageSeen: false,
      ),
    );
    await _pumpOut(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.languageTitle), findsOneWidget);
    expect(find.text(AppStrings.languageFrench), findsOneWidget);
    expect(find.text(AppStrings.languageArabic), findsOneWidget);
    expect(find.text(AppStrings.languageArabicDisabled), findsOneWidget);
    expect(find.text(AppStrings.continueLabel), findsOneWidget);
    await tester.tap(find.text(AppStrings.languageArabic), warnIfMissed: false);
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await _pumpOut(tester);
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
  });
}
