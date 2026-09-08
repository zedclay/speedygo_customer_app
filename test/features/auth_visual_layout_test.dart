import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
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
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/onboarding/discover.jpg')),
      findsOneWidget,
    );
    await tester.tap(find.text(AppStrings.next));
    await _pumpOut(tester);
    expect(find.text(AppStrings.welcomeOrderTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.next));
    await _pumpOut(tester);
    expect(find.text(AppStrings.welcomeTrackTitle), findsOneWidget);
    expect(find.text(AppStrings.welcomeTrackLiveTitle), findsOneWidget);
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
}
