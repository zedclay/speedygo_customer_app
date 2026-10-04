import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/checkout/presentation/checkout_payment_method_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

void main() {
  testWidgets('profile payment methods do not open checkout method', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.accountPaymentMethodsTitle),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AppStrings.accountPaymentMethodsTitle));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.accountPaymentMethodsBody), findsOneWidget);
    expect(find.byType(CheckoutPaymentMethodScreen), findsNothing);
    expect(find.byKey(const Key('checkout-method-cod')), findsNothing);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tabProfile), findsOneWidget);
  });

  testWidgets('account delete has no password field and does not call API', (
    tester,
  ) async {
    await tester.pumpWidget(readyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.accountDeleteTitle),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AppStrings.accountDeleteTitle));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.accountDeleteBody), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('password'), findsNothing);
    await tester.tap(find.text(AppStrings.accountDeleteAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deleteUnavailable), findsOneWidget);
  });

  testWidgets('cart checkout is disabled when cart is not ready', (
    tester,
  ) async {
    final cart = FakeCartClient(
      bootstrap: CartBootstrap(
        cartExists: true,
        cart: espressoCheckoutCart(cartReady: false),
      ),
    );
    await tester.pumpWidget(readyApp(cart: cart));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(HomeScreen))).push(AppRoutes.cart);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cartNotReady), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('checkout-review-cta')))
          .onPressed,
      isNull,
    );
  });
}
