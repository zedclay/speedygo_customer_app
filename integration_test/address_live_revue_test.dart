import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';

import 'support/dev_otp_file.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    debugPrint('LIVE_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    File(
      '/Users/mac/Downloads/speedygo_project/.cache/live-shot-name',
    ).writeAsStringSync(name);
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  Future<void> openAccount(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.tabProfile));
    await tester.pumpAndSettle();
  }

  Future<void> openHome(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
  }

  Future<void> addLabeledAddress(
    WidgetTester tester, {
    required String label,
    required String text,
    required String lat,
    required String lng,
  }) async {
    await tester.tap(find.byKey(const Key('add-address-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('address-label-field')), label);
    await tester.enterText(find.byKey(const Key('address-text-field')), text);
    await tester.enterText(find.byKey(const Key('address-latitude-field')), lat);
    await tester.enterText(
      find.byKey(const Key('address-longitude-field')),
      lng,
    );
    await tester.tap(find.byKey(const Key('address-save-button')));
    await tester.pumpAndSettle();
    expect(find.text(label), findsWidgets);
  }

  Finder cardFor(String label) {
    return find
        .ancestor(
          of: find.text(label).first,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'address-card-',
                ),
          ),
        )
        .first;
  }

  Future<void> tapOnCard(
    WidgetTester tester,
    String label,
    String action,
  ) async {
    await tester.tap(find.descendant(of: cardFor(label), matching: find.text(action)));
    await tester.pumpAndSettle();
  }

  Future<void> deleteLabeled(WidgetTester tester, String label) async {
    expect(find.text(label), findsWidgets);
    await tapOnCard(tester, label, AppStrings.deleteAddress);
    await tester.tap(find.byKey(const Key('confirm-delete-address')));
    await tester.pumpAndSettle();
    expect(find.text(label), findsNothing);
  }

  testWidgets(
    'live Revue default edit Home and delete reconcile',
    (tester) async {
      const alpha = 'Revue check Alpha';
      const beta = 'Revue check Beta';
      const alphaEdited = 'Revue check Alpha edit';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            splashMinDurationProvider.overrideWithValue(Duration.zero),
            splashAnimateProvider.overrideWithValue(false),
          ],
          child: const SpeedyGoApp(),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 50; i++) {
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

      if (find.text(AppStrings.searchHint).evaluate().isNotEmpty &&
          find.textContaining('Revue').evaluate().isEmpty) {
        await openAccount(tester);
        await tester.ensureVisible(find.byKey(const Key('account-logout')));
        await tester.tap(find.byKey(const Key('account-logout')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.logoutConfirmAction));
        await tester.pumpAndSettle();
      }

      if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextField), '550000072');
        await tester.pump();
        final otpCache = speedyGoDevOtpFile();
        if (otpCache.existsSync()) {
          otpCache.deleteSync();
        }
        await tester.tap(
          find.widgetWithText(FilledButton, AppStrings.continueLabel),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.otpTitle), findsOneWidget);
        File? found;
        for (var i = 0; i < 40; i++) {
          final candidate = speedyGoDevOtpFile();
          if (candidate.existsSync() &&
              candidate.readAsStringSync().trim().length == 6) {
            found = candidate;
            break;
          }
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(found, isNotNull);
        final code = found!.readAsStringSync().trim();
        expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
        await tester.enterText(find.byType(TextField), code);
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
        await tester.pumpAndSettle();
      }

      expect(find.text(AppStrings.searchHint), findsOneWidget);
      expect(find.textContaining('Revue'), findsWidgets);

      await openAccount(tester);
      await tester.tap(find.text(AppStrings.addressesTitle));
      await tester.pumpAndSettle();

      if (find.text(alpha).evaluate().isEmpty) {
        await addLabeledAddress(
          tester,
          label: alpha,
          text: 'Revue check Alpha street',
          lat: '36.7538',
          lng: '3.0588',
        );
      }
      if (find.text(beta).evaluate().isEmpty) {
        await addLabeledAddress(
          tester,
          label: beta,
          text: 'Revue check Beta street',
          lat: '36.7548',
          lng: '3.0598',
        );
      }
      expect(find.text(alpha), findsWidgets);
      expect(find.text(beta), findsWidgets);
      await shot('live-address-list-two');

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      await openHome(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('home-address-chip')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);
      await tester.tap(find.text(alpha));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(alpha), findsWidgets);
      await shot('live-address-home-selected-alpha');

      await openAccount(tester);
      await tester.tap(find.text(AppStrings.addressesTitle));
      await tester.pumpAndSettle();
      await tapOnCard(tester, beta, AppStrings.setAsDefault);
      expect(find.text(AppStrings.defaultAddressBadge), findsOneWidget);
      expect(find.text(AppStrings.selectedAddressBadge), findsOneWidget);
      await shot('live-address-list-default-beta');

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      await openHome(tester);
      expect(find.text(alpha), findsWidgets);
      expect(find.text(beta), findsNothing);
      await shot('live-address-home-still-alpha');

      await openAccount(tester);
      await tester.tap(find.text(AppStrings.addressesTitle));
      await tester.pumpAndSettle();
      await tapOnCard(tester, alpha, AppStrings.editAddress);
      await tester.enterText(
        find.byKey(const Key('address-label-field')),
        alphaEdited,
      );
      await tester.tap(find.byKey(const Key('address-save-button')));
      await tester.pumpAndSettle();
      expect(find.text(alphaEdited), findsOneWidget);

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      await openHome(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(alphaEdited), findsWidgets);
      expect(find.text(alpha), findsNothing);
      await shot('live-address-home-after-edit');

      await openAccount(tester);
      await tester.tap(find.text(AppStrings.addressesTitle));
      await tester.pumpAndSettle();
      await deleteLabeled(tester, alphaEdited);
      expect(find.text(beta), findsWidgets);

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      await openHome(tester);
      expect(find.text(beta), findsWidgets);
      expect(find.text(alphaEdited), findsNothing);
      await shot('live-address-home-after-delete-selected');

      await openAccount(tester);
      await tester.tap(find.text(AppStrings.addressesTitle));
      await tester.pumpAndSettle();
      await deleteLabeled(tester, beta);
      await shot('live-address-list-cleaned');
    },
  );
}
