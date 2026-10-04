import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/orders_tab_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';
import '../customer_navigation_test.dart';

void main() {
  testWidgets('Commandes tab switch from home has unique page keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()]))
          ..details[activeOrderId] = sampleOrderDetail(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(OrdersTabScreen), findsOneWidget);
  });

  testWidgets('Commandes after tracking push/pop has unique page keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()]))
          ..details[activeOrderId] = sampleOrderDetail(),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push(AppRoutes.orderTracking(activeOrderId));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(OrdersTabScreen), findsOneWidget);
  });

  testWidgets('go to Commandes while tracking open has unique page keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()]))
          ..details[activeOrderId] = sampleOrderDetail(),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push(AppRoutes.orderTracking(activeOrderId));
    await tester.pumpAndSettle();
    router.go(AppRoutes.orders);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(OrdersTabScreen), findsOneWidget);
  });

  testWidgets('push order detail from Commandes then pop stays stable', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()]))
          ..details[activeOrderId] = sampleOrderDetail(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('order-list-tile-$activeOrderId')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Retour').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(OrdersTabScreen), findsOneWidget);
  });

  testWidgets('Commandes after pushing home categories has unique page keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()]))
          ..details[activeOrderId] = sampleOrderDetail(),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push(AppRoutes.homeCategories);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(OrdersTabScreen), findsOneWidget);
  });

  testWidgets('Commandes tab uses go root and stays unique after revisit', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()]))
          ..details[activeOrderId] = sampleOrderDetail(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersTabScreen), findsOneWidget);
    await tester.tap(find.byKey(Key('order-list-tile-$activeOrderId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retour').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(OrdersTabScreen), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(OrdersTabScreen))).state.uri.path,
      AppRoutes.orders,
    );
  });
}
