import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_parents.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/account/presentation/account_status_screen.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/address_list_screen.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/presentation/active_sessions_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/language_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/phone_screen.dart';
import 'package:speedygo_customer_app/features/checkout/presentation/checkout_payment_method_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:speedygo_customer_app/features/notifications/presentation/notification_inbox_screen.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_create_screen.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_list_screen.dart';

import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

void _phoneFrame(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openProfile(
  WidgetTester tester, {
  Widget? app,
}) async {
  await tester.pumpWidget(app ?? readyApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.person_outline));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('account-hub')), findsOneWidget);
}

Future<void> _openRow(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void _expectProfileShell(WidgetTester tester) {
  expect(find.byType(HomeBottomBar), findsOneWidget);
  expect(find.byIcon(Icons.person), findsOneWidget);
}

Future<void> _backToHub(WidgetTester tester) async {
  await tester.tap(find.byTooltip(AppStrings.back));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('account-hub')), findsOneWidget);
  _expectProfileShell(tester);
}

void main() {
  test('account child paths fall back to the profile hub', () {
    expect(NavParents.forPath(AppRoutes.accountAddresses), AppRoutes.account);
    expect(NavParents.forPath(AppRoutes.accountLanguage), AppRoutes.account);
    expect(NavParents.forPath(AppRoutes.accountSecurity), AppRoutes.account);
    expect(NavParents.forPath(AppRoutes.accountSupport), AppRoutes.account);
    expect(NavParents.forPath(AppRoutes.accountSupportNew), AppRoutes.account);
    expect(NavParents.forPath(AppRoutes.accountLegalPrivacy), AppRoutes.account);
    expect(NavParents.forPath(AppRoutes.legalPrivacy), AppRoutes.account);
    expect(NavParents.forPath(AppRoutes.legalTerms), AppRoutes.account);
  });

  testWidgets('addresses stay on the Profile tab and pop back to the hub', (
    tester,
  ) async {
    _phoneFrame(tester);
    await _openProfile(tester);
    await _openRow(tester, const Key('account-addresses'));
    expect(find.byType(AddressListScreen), findsOneWidget);
    _expectProfileShell(tester);
    await _backToHub(tester);
  });

  testWidgets('language save to Arabic keeps the hub and does not log out', (
    tester,
  ) async {
    _phoneFrame(tester);
    final auth = FakeAuthClient();
    final launch = MemoryLaunchStore(
      onboardingSeen: true,
      languageSeen: true,
      locale: AppLocale.french,
    );
    await _openProfile(tester, app: readyApp(auth: auth, launch: launch));
    await _openRow(tester, const Key('account-language'));
    expect(find.byType(LanguageScreen), findsOneWidget);
    _expectProfileShell(tester);

    await tester.tap(find.byKey(const Key('language-option-ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.languageSave));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account-hub')), findsOneWidget);
    _expectProfileShell(tester);
    expect(find.byType(PhoneScreen), findsNothing);
    expect(auth.logoutCount, 0);
    expect(find.text(AppStrings.tabProfile), findsWidgets);
    expect(find.text(AppStrings.languageArabic), findsWidgets);
    expect(launch.locale, AppLocale.arabic);
    final locale = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('account-hub'))),
    ).read(sessionControllerProvider).locale;
    expect(locale, AppLocale.arabic);
  });

  testWidgets('language back without saving returns to the hub', (tester) async {
    _phoneFrame(tester);
    await _openProfile(tester);
    await _openRow(tester, const Key('account-language'));
    await tester.tap(find.byKey(const Key('language-option-ar')));
    await tester.pumpAndSettle();
    await _backToHub(tester);
    expect(find.text(AppStrings.languageFrench), findsWidgets);
  });

  testWidgets('Arabic back from addresses returns to the hub', (tester) async {
    _phoneFrame(tester);
    await _openProfile(
      tester,
      app: readyApp(
        launch: MemoryLaunchStore(
          onboardingSeen: true,
          languageSeen: true,
          locale: AppLocale.arabic,
        ),
      ),
    );
    expect(find.text(AppStrings.tabProfile), findsWidgets);
    await _openRow(tester, const Key('account-addresses'));
    expect(find.byType(AddressListScreen), findsOneWidget);
    expect(find.byTooltip(AppStrings.back), findsWidgets);
    await _backToHub(tester);
  });

  testWidgets('sessions, support, and deferred pages use the correct routes', (
    tester,
  ) async {
    _phoneFrame(tester);
    await _openProfile(tester);

    await _openRow(tester, const Key('account-payment-methods'));
    expect(find.byType(AccountStatusScreen), findsOneWidget);
    expect(find.text(AppStrings.accountPaymentMethodsBody), findsOneWidget);
    expect(find.byType(CheckoutPaymentMethodScreen), findsNothing);
    _expectProfileShell(tester);
    await _backToHub(tester);

    await _openRow(tester, const Key('account-notifications'));
    expect(find.text(AppStrings.accountNotificationsSettingsBody), findsOneWidget);
    _expectProfileShell(tester);
    await tester.tap(find.byKey(const Key('account-notifications-inbox')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationInboxScreen), findsOneWidget);
    expect(find.byIcon(Icons.notifications), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-hub')), findsOneWidget);

    await _openRow(tester, const Key('account-support-new'));
    expect(find.byType(SupportCreateScreen), findsOneWidget);
    expect(find.text(AppStrings.supportNewTitle), findsOneWidget);
    _expectProfileShell(tester);
    await _backToHub(tester);

    await _openRow(tester, const Key('account-support'));
    expect(find.byType(SupportListScreen), findsOneWidget);
    _expectProfileShell(tester);
    await _backToHub(tester);

    await _openRow(tester, const Key('account-legal-privacy'));
    expect(find.text(AppStrings.legalUnavailableBody), findsOneWidget);
    expect(find.text(AppStrings.legalPrivacyTitle), findsOneWidget);
    _expectProfileShell(tester);
    await _backToHub(tester);

    await _openRow(tester, const Key('account-legal-terms'));
    expect(find.text(AppStrings.legalTermsTitle), findsOneWidget);
    _expectProfileShell(tester);
    await _backToHub(tester);

    await _openRow(tester, const Key('account-security'));
    expect(find.byType(ActiveSessionsScreen), findsOneWidget);
    _expectProfileShell(tester);
    await _backToHub(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('account-delete')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('account-delete')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.accountDeleteBody), findsOneWidget);
    _expectProfileShell(tester);
    await _backToHub(tester);
  });

  testWidgets('profile header does not invent C8 editing or leave the hub', (
    tester,
  ) async {
    _phoneFrame(tester);
    await _openProfile(tester);
    expect(find.text('Amel Benali'), findsOneWidget);
    await tester.tap(find.text('Amel Benali'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-hub')), findsOneWidget);
    expect(find.byType(PhoneScreen), findsNothing);
    final location = GoRouter.of(
      tester.element(find.byKey(const Key('account-hub'))),
    ).state.uri.path;
    expect(location, AppRoutes.account);
  });
}
