import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_customer_app/app/app.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import 'support/dev_otp_file.dart';

/// Isolated merchant pin (Batch04 Cafe / Street A). Not hardcoded in app source.
const _hydraLat = '36.753001';
const _hydraLng = '3.058001';
const _sbaLat = '35.1939';
const _sbaLng = '-0.6417';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    debugPrint('LIVE_SCREEN:$name');
    try {
      await binding.takeScreenshot(name);
    } catch (error) {
      debugPrint('LIVE_SCREEN_FAIL:$name $error');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> settle(WidgetTester tester, {int frames = 40}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    int frames = 50,
  }) async {
    for (var i = 0; i < frames; i++) {
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    return finder.evaluate().isNotEmpty;
  }

  Future<void> loginIfNeeded(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty ||
          find.text(AppStrings.searchHint).evaluate().isNotEmpty ||
          find.text(AppStrings.homeNeedAddress).evaluate().isNotEmpty) {
        break;
      }
      if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty) {
        await tester.tap(
          find.widgetWithText(FilledButton, AppStrings.continueLabel),
        );
        await settle(tester);
      }
      if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.skip));
        await settle(tester);
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text(AppStrings.phoneTitle).evaluate().isEmpty) {
      return;
    }
    await tester.enterText(find.byType(TextField), '551987721');
    await tester.pump();
    final continueBtn = find.widgetWithText(
      FilledButton,
      AppStrings.continueLabel,
    );
    final otpFile = speedyGoDevOtpFile();
    if (otpFile.existsSync()) {
      otpFile.deleteSync();
    }
    for (var attempt = 0; attempt < 4; attempt++) {
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await settle(tester, frames: 20);
      if (find
          .widgetWithText(FilledButton, AppStrings.verify)
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(seconds: 2));
    }
    for (var i = 0; i < 40; i++) {
      if (otpFile.existsSync() &&
          RegExp(r'^\d{6}$').hasMatch(otpFile.readAsStringSync().trim())) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.enterText(
      find.byType(TextField),
      otpFile.readAsStringSync().trim(),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.verify));
    await settle(tester, frames: 50);
    if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.skip));
      await settle(tester);
    }
  }

  Future<void> confirmOsmPin(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('address-choose-map')));
    await tester.tap(find.byKey(const Key('address-choose-map')));
    await settle(tester, frames: 30);
    final confirm = find.byKey(const Key('customer-location-confirm'));
    await waitFor(tester, confirm, frames: 40);
    for (var i = 0; i < 60; i++) {
      final filled = find.descendant(
        of: confirm,
        matching: find.byType(FilledButton),
      );
      if (filled.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(filled).onPressed != null) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await settle(tester, frames: 20);
    }
  }

  Future<void> openAddressForm(WidgetTester tester) async {
    if (find.byKey(const Key('address-label-field')).evaluate().isNotEmpty) {
      return;
    }
    if (find.byKey(const Key('home-address-chip')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('home-address-chip')));
      await settle(tester, frames: 20);
    }
    if (find.byKey(const Key('address-label-field')).evaluate().isEmpty) {
      if (find.text(AppStrings.addAddressShort).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.addAddressShort));
        await settle(tester, frames: 25);
      } else if (find.widgetWithText(FilledButton, AppStrings.addAddress)
          .evaluate()
          .isNotEmpty) {
        final addBtn = find.widgetWithText(
          FilledButton,
          AppStrings.addAddress,
        );
        await tester.ensureVisible(addBtn.first);
        await tester.tap(addBtn.first);
        await settle(tester, frames: 25);
      } else if (find.byKey(const Key('add-address-button')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('add-address-button')));
        await settle(tester, frames: 25);
      }
    }
    var opened = await waitFor(
      tester,
      find.byKey(const Key('address-label-field')),
      frames: 40,
    );
    if (!opened && find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
      final ctx = tester.element(find.text(AppStrings.searchHint).first);
      GoRouter.of(ctx).push(AppRoutes.addressForm);
      opened = await waitFor(
        tester,
        find.byKey(const Key('address-label-field')),
        frames: 40,
      );
    }
    expect(opened, isTrue, reason: 'address form did not open');
  }

  Finder offstageKey(String name) =>
      find.byKey(Key(name), skipOffstage: false);

  void fillOffstageField(WidgetTester tester, String name, String value) {
    final field = tester.widget<TextField>(offstageKey(name));
    field.controller!.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    field.onChanged?.call(value);
  }

  Future<void> saveAddress(
    WidgetTester tester, {
    required String label,
    required String text,
    required String lat,
    required String lng,
  }) async {
    await openAddressForm(tester);
    await tester.ensureVisible(find.byKey(const Key('address-label-field')));
    await tester.enterText(find.byKey(const Key('address-label-field')), label);
    await tester.enterText(find.byKey(const Key('address-text-field')), text);
    fillOffstageField(tester, 'address-latitude-field', lat);
    fillOffstageField(tester, 'address-longitude-field', lng);
    await tester.pump();
    await confirmOsmPin(tester);
    await tester.ensureVisible(find.byKey(const Key('address-save-button')));
    await tester.tap(find.byKey(const Key('address-save-button')));
    await settle(tester, frames: 40);
  }

  Future<void> returnToHome(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      if (find.byKey(const Key('home-address-chip')).evaluate().isEmpty &&
          find.byType(ListView).evaluate().isNotEmpty) {
        await tester.drag(find.byType(ListView).first, const Offset(0, 1600));
        await settle(tester, frames: 8);
      }
      if (find.byKey(const Key('home-address-chip')).evaluate().isNotEmpty) {
        if (find.text(AppStrings.tabHome).evaluate().isNotEmpty) {
          await tester.tap(find.text(AppStrings.tabHome));
          await settle(tester, frames: 12);
        }
        if (find.byKey(const Key('home-address-chip')).evaluate().isNotEmpty) {
          return;
        }
      }
      if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await settle(tester, frames: 15);
        continue;
      }
      if (find.text(AppStrings.tabHome).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.tabHome));
        await settle(tester, frames: 15);
        continue;
      }
      await settle(tester, frames: 8);
    }
  }

  Future<void> openAddressPicker(WidgetTester tester) async {
    await returnToHome(tester);
    final chip = find.byKey(const Key('home-address-chip'));
    expect(chip, findsOneWidget, reason: 'Home address chip missing');
    await tester.tap(chip);
    await settle(tester, frames: 20);
  }

  testWidgets('populated home after coverage address', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(SecureSessionStore()),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          splashAnimateProvider.overrideWithValue(false),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester);
    await loginIfNeeded(tester);
    await waitFor(tester, find.text(AppStrings.searchHint), frames: 40);
    await tester.tap(find.text(AppStrings.tabHome));
    await settle(tester, frames: 25);

    if (find.text(AppStrings.homeNeedAddress).evaluate().isNotEmpty ||
        find.text(AppStrings.deliverToUnset).evaluate().isNotEmpty) {
      await shot('sim-home-need-address');
      await saveAddress(
        tester,
        label: 'Revue Hydra',
        text: '12 chemin de Hydra, Alger',
        lat: _hydraLat,
        lng: _hydraLng,
      );
    }

    await returnToHome(tester);
    if (find.text('Revue Hydra').evaluate().isEmpty) {
      await openAddressPicker(tester);
      if (find.text('Revue Hydra').evaluate().isEmpty) {
        await saveAddress(
          tester,
          label: 'Revue Hydra',
          text: '12 chemin de Hydra, Alger',
          lat: _hydraLat,
          lng: _hydraLng,
        );
        await returnToHome(tester);
        await openAddressPicker(tester);
      }
      await tester.tap(find.text('Revue Hydra').first);
      await settle(tester, frames: 25);
      await returnToHome(tester);
    }
    await waitFor(tester, find.text('Batch04 Cafe'), frames: 50);
    expect(find.text(AppStrings.homeNeedAddress), findsNothing);
    expect(find.text('Revue Hydra'), findsWidgets);
    expect(find.text('Batch04 Cafe'), findsWidgets);
    await shot('sim-home-populated-fr');
    if (find.text('Batch04 Cafe').evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text('Batch04 Cafe').first);
      await settle(tester, frames: 8);
      await shot('sim-home-populated-fr-card');
    }

    await openAddressPicker(tester);
    if (find.text('Revue SBA').evaluate().isEmpty) {
      if (find.text(AppStrings.addAddressShort).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.addAddressShort));
      } else if (find.text(AppStrings.addAddress).evaluate().isNotEmpty) {
        await tester.tap(find.text(AppStrings.addAddress).last);
      }
      await settle(tester, frames: 20);
      await saveAddress(
        tester,
        label: 'Revue SBA',
        text: 'Centre-ville, Sidi Bel Abbès',
        lat: _sbaLat,
        lng: _sbaLng,
      );
      await returnToHome(tester);
      await openAddressPicker(tester);
    }
    await tester.tap(find.text('Revue SBA').first);
    await settle(tester, frames: 30);
    await returnToHome(tester);
    await shot('sim-home-sba-switch');

    await openAddressPicker(tester);
    await tester.tap(find.text('Revue Hydra').first);
    await settle(tester, frames: 30);
    await returnToHome(tester);
    await waitFor(tester, find.text('Batch04 Cafe'), frames: 40);
    expect(find.text('Batch04 Cafe'), findsWidgets);
    await shot('sim-home-populated-after-switch');

    await tester.tap(find.text(AppStrings.tabProfile));
    await settle(tester, frames: 15);
    await tester.tap(find.byKey(const Key('account-language')));
    await settle(tester, frames: 20);
    await tester.tap(find.byKey(const Key('language-option-ar')));
    await settle(tester, frames: 8);
    await tester.tap(find.text(AppStrings.languageSave));
    await settle(tester, frames: 20);
    await returnToHome(tester);
    await waitFor(tester, find.text('Batch04 Cafe'), frames: 30);
    await shot('sim-home-populated-ar');
    await tester.tap(find.text(AppStrings.tabProfile));
    await settle(tester, frames: 15);
    await tester.tap(find.byKey(const Key('account-language')));
    await settle(tester, frames: 20);
    await tester.tap(find.byKey(const Key('language-option-fr')));
    await settle(tester, frames: 8);
    await tester.tap(find.text(AppStrings.languageSave));
    await settle(tester, frames: 20);
    await returnToHome(tester);
  });
}
