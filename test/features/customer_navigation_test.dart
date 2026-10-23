import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_catalog.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_design_preview_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';

import '../helpers/fakes.dart';
import '../helpers/notification_support_fakes.dart';
import '../widget_test.dart' as host;

Widget readyApp({
  bool navPreview = false,
  MemoryLaunchStore? launch,
  FakeCatalogClient? catalog,
  FakeCustomerClient? customer,
  FakeOrdersClient? orders,
  FakeRatingsClient? ratings,
  FakePromotionsClient? promotions,
  FakeCartClient? cart,
  FakeCheckoutClient? checkout,
  FakeAddressClient? addresses,
  MemoryAddressSelectionStore? addressSelection,
  FakeLocationClient? location,
  FakeAuthClient? auth,
  FakeNotificationsClient? notifications,
  FakeSupportClient? support,
  Future<Uint8List?> Function(String path)? coverImageBytes,
}) {
  final store = MemorySessionStore()
    ..value = const TokenPair(
      accessToken: 'access-1',
      refreshToken: 'refresh-1-token-value',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  final resolvedCustomer =
      customer ??
      (FakeCustomerClient()
        ..meResult = const CustomerMe(
          customerProfileExists: true,
          profileComplete: true,
          addressReady: false,
          profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
        ));
  return host.app(
    auth: auth ?? FakeAuthClient(),
    customer: resolvedCustomer,
    store: store,
    navPreview: navPreview,
    launch: launch,
    catalog: catalog,
    orders: orders,
    ratings: ratings,
    promotions: promotions,
    cart: cart,
    checkout: checkout,
    addresses: addresses,
    addressSelection: addressSelection,
    location: location,
    notifications: notifications,
    support: support,
    coverImageBytes: coverImageBytes,
  );
}

void main() {
  test('catalog maps every Customer HTML directory plus DESIGN.md', () {
    const htmlDirs = {
      'splash_speedygo',
      's_lection_de_la_langue_speedygo_c_002',
      'bienvenue_speedygo',
      'num_ro_de_t_l_phone_speedygo',
      'v_rification_otp_speedygo',
      'profil_speedygo_2',
      'permission_de_localisation_speedygo',
      'notifications_speedygo',
      'r_cup_ration_de_session_speedygo',
      's_lecteur_d_adresse_speedygo_reference',
      'promotions_speedygo',
      'recherche_speedygo',
      'toutes_les_cat_gories_speedygo_c_012',
      'accueil_speedygo',
      'favoris_speedygo',
      'r_sultats_de_recherche_speedygo',
      'd_tails_du_produit_speedygo',
      'd_tails_de_la_commande_speedygo',
      'recherche_de_livreur_speedygo',
      'paiement_speedygo',
      'd_tails_de_l_tat_speedygo',
      'historique_des_commandes_speedygo',
      'code_de_livraison_speedygo',
      'menu_speedygo',
      'avis_speedygo',
      'restaurants_speedygo',
      'ajouter_ou_modifier_une_adresse_speedygo',
      'mode_de_paiement_speedygo',
      'panier_speedygo_c_025',
      'redirection_vers_le_paiement_speedygo',
      'attente_de_confirmation_speedygo',
      'infos_sur_le_marchand_speedygo',
      'r_vision_de_la_commande_speedygo',
      'confirmation_de_commande_speedygo',
      's_lection_de_l_adresse_speedygo',
      'noter_la_commande_speedygo',
      'd_tails_du_marchand_speedygo',
      'commande_termin_e_speedygo',
      'suivi_de_commande_speedygo',
      'soumission_de_la_commande_speedygo',
      're_u_speedygo',
      'configuration_du_produit_speedygo',
      'suivi_de_livraison_speedygo',
      'confirmation_de_l_emplacement_speedygo',
      'instructions_sp_ciales_speedygo',
      'instructions_de_livraison_speedygo',
      'livreur_proximit_speedygo',
      'annuler_la_commande_speedygo',
      's_curit_et_sessions_actives_speedygo',
      'signaler_un_probl_me_speedygo',
      'd_connexion_speedygo',
      'l_gal_et_confidentialit_speedygo',
      'r_diger_un_avis_speedygo',
      'param_tres_des_notifications_speedygo',
      'param_tres_de_la_langue_speedygo',
      'd_tails_du_ticket_support_speedygo',
      'profil_speedygo_1',
      'suppression_du_compte_speedygo',
      'adresses_enregistr_es_speedygo',
    };
    expect(htmlDirs.length, 59);
    final mapped = NavCatalog.all.map((e) => e.designDir).toSet();
    expect(mapped, contains('algerian_velocity'));
    expect(mapped, containsAll(htmlDirs));
  });

  testWidgets('signed-out user cannot open a protected discovery screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      host.app(auth: FakeAuthClient(), customer: FakeCustomerClient()),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.text('Restaurants'), findsNothing);
    expect(find.text(AppStrings.tabHome), findsNothing);
  });

  testWidgets('home opens restaurants and pops back', (tester) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push(AppRoutes.restaurants);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.storefrontsTitle), findsWidgets);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
  });

  testWidgets('normal home does not expose fabricated order or directory', (
    tester,
  ) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.storefrontsTitle), findsOneWidget);
    expect(find.text(AppStrings.allScreens), findsNothing);
    expect(find.text(AppStrings.landingTitle), findsNothing);
    expect(find.text(AppStrings.activeOrder), findsNothing);
    expect(find.text(AppStrings.navPreview), findsNothing);
  });

  testWidgets('preview routes are inaccessible outside preview mode', (
    tester,
  ) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.directory);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.previewBanner), findsNothing);
    router.go(AppRoutes.homeDesignPreview);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text(AppStrings.previewBanner), findsNothing);
    expect(find.text(AppStrings.nearbyMerchants), findsNothing);
    router.go(AppRoutes.orderConfirmation(AppRoutes.navOrder));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchHint), findsOneWidget);
    expect(find.text('Confirmation de commande'), findsNothing);
  });

  testWidgets('preview mode can open the directory and fixtures', (
    tester,
  ) async {
    await tester.pumpWidget(readyApp(navPreview: true));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.directory);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.previewBanner), findsOneWidget);
    router.go(AppRoutes.favorites);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un favori'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.favoritesUnavailable), findsOneWidget);
  });

  testWidgets('preview mode can open the full Home design composition', (
    tester,
  ) async {
    await tester.pumpWidget(readyApp(navPreview: true));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.nearbyMerchants), findsNothing);
    expect(find.text(AppStrings.specialOffer), findsNothing);
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go(AppRoutes.directory);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.previewBanner), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.homeDesignPreviewTitle),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.homeDesignPreviewTitle), findsOneWidget);
    router.go(AppRoutes.homeDesignPreview);
    await tester.pumpAndSettle();
    expect(find.byType(HomeDesignPreviewScreen), findsOneWidget);
    expect(find.text(AppStrings.previewBanner), findsWidgets);
    expect(find.text(AppStrings.categories), findsOneWidget);
    expect(find.text(AppStrings.specialOffer.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.promoCode), findsOneWidget);
    expect(find.text(AppStrings.nearbyMerchants), findsOneWidget);
    expect(find.text(AppStrings.previewMerchantName), findsOneWidget);
    expect(find.text(AppStrings.previewRating), findsOneWidget);
    expect(find.text(AppStrings.activeOrder), findsOneWidget);
    expect(find.text(AppStrings.previewOrderNumber), findsOneWidget);
    expect(find.text(AppStrings.previewAddress), findsOneWidget);
    expect(find.byType(HomeBottomBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('favorites add does not invent a successful save', (
    tester,
  ) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push(AppRoutes.favorites);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un favori'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.favoritesUnavailable), findsOneWidget);
    expect(find.text('Favoris'), findsWidgets);
  });

  testWidgets('order submit does not create an order', (tester) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push(AppRoutes.checkoutSubmit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer la commande'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.submitUnavailable), findsOneWidget);
    expect(find.text('Confirmation de commande'), findsNothing);
    expect(find.text(AppStrings.openPreview), findsNothing);
  });

  testWidgets('account delete does not close the account', (tester) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Supprimer mon compte'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer définitivement'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deleteUnavailable), findsOneWidget);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
  });

  testWidgets('search keeps the typed query and does not call with fixtures', (
    tester,
  ) async {
    final catalog = FakeCatalogClient();
    await tester.pumpWidget(readyApp(catalog: catalog));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'couscous');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('couscous'), findsOneWidget);
    expect(catalog.lastSearchQ, 'couscous');
    expect(catalog.searchCount, 1);
    expect(find.textContaining('API non appelée'), findsNothing);
  });

  testWidgets('both address variants are independently reachable', (
    tester,
  ) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deliverToUnset));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push(AppRoutes.checkoutAddress);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addressPickerTitle), findsOneWidget);
    expect(find.textContaining('s_lection_de_l_adresse'), findsNothing);
  });

  testWidgets('Arabic becomes the active language and is persisted', (
    tester,
  ) async {
    final launch = MemoryLaunchStore(onboardingSeen: false, languageSeen: false);
    await tester.pumpWidget(
      host.app(
        auth: FakeAuthClient(),
        customer: FakeCustomerClient(),
        onboardingSeen: false,
        languageSeen: false,
        launch: launch,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.languageTitle), findsOneWidget);
    expect(find.text(AppStrings.languageArabicDisabled), findsNothing);
    await tester.tap(find.byKey(const Key('language-option-ar')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.continueLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcomeDiscoverTitle), findsOneWidget);
    final locale = ProviderScope.containerOf(
      tester.element(find.text(AppStrings.welcomeDiscoverTitle)),
    ).read(sessionControllerProvider).locale;
    expect(locale, AppLocale.arabic);
    expect(launch.locale, AppLocale.arabic);
  });

  testWidgets(
    'rebuilding the app after leaving a nested route does not duplicate page keys',
    (tester) async {
      await tester.pumpWidget(readyApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go(AppRoutes.accountLanguage);
      await tester.pumpAndSettle();
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      await tester.pumpWidget(readyApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('home greeting uses first name and evening Bonsoir', () {
    expect(
      AppStrings.homeGreeting('Amel Benali', now: DateTime(2026, 9, 8, 20)),
      'Bonsoir, Amel 👋',
    );
    expect(
      AppStrings.homeGreeting(
        'Bousbaa Abdelhafid',
        now: DateTime(2026, 9, 8, 10),
      ),
      'Bonjour, Bousbaa 👋',
    );
  });

  test('fixture routes expose required parameters', () {
    expect(AppRoutes.merchant(AppRoutes.navBranch), '/merchants/nav-branch');
    expect(AppRoutes.order(AppRoutes.navOrder), '/orders/nav-order');
    expect(AppRoutes.product(AppRoutes.navProduct), '/products/nav-product');
    expect(AppRoutes.supportTicket(AppRoutes.navTicket), '/support/nav-ticket');
  });
}
