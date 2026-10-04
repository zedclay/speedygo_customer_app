import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_cancel_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/orders_tab_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

void main() {
  testWidgets('detail offers cancel only while awaiting merchant', (
    tester,
  ) async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('test:ui'),
        ordersApiProvider.overrideWithValue(orders),
        coverImageBytesProvider.overrideWith((ref, path) async => null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OrderDetailScreen(orderId: detail.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('order-detail-cancel-entry')), findsOneWidget);
  });

  testWidgets('cancelled COD detail never claims money was refunded', (
    tester,
  ) async {
    final detail = sampleOrderDetail(status: 'CANCELLED');
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('test:ui'),
        ordersApiProvider.overrideWithValue(orders),
        coverImageBytesProvider.overrideWith((ref, path) async => null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OrderDetailScreen(orderId: detail.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('order-detail-cod-no-refund')), findsWidgets);
    expect(find.textContaining('recédité'), findsNothing);
    expect(find.text(AppStrings.orderRefundStatusRefunded), findsNothing);
    expect(find.byKey(const Key('order-detail-cancel-entry')), findsNothing);
  });

  testWidgets('cancel confirm updates list status to Annulée', (tester) async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient(
      orders: orderPage([sampleOrder()]),
    )..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('test:ui'),
        ordersApiProvider.overrideWithValue(orders),
        coverImageBytesProvider.overrideWith((ref, path) async => null),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.orderCancel(detail.id),
      routes: [
        GoRoute(
          path: '/orders/:orderId/cancel',
          builder: (context, state) => OrderCancelScreen(
            orderId: state.pathParameters['orderId'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (_, _) => const OrdersTabScreen(),
        ),
        GoRoute(
          path: '/orders/:orderId',
          builder: (context, state) => OrderDetailScreen(
            orderId: state.pathParameters['orderId'] ?? '',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.orderCancelEligibleTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.orderCancelCodNoRefund),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.orderCancelCodNoRefund), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('order-cancel-confirm')));
    await tester.tap(find.byKey(const Key('order-cancel-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('order-cancel-accepted')), findsOneWidget);
    expect(
      find.textContaining(AppStrings.orderCancelCodNoRefund),
      findsWidgets,
    );

    await tester.tap(find.text(AppStrings.orderSubmissionViewOrders));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(OrdersTabScreen), findsOneWidget);
    await tester.tap(find.text(AppStrings.ordersTabCancelled));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.orderStatusCancelled), findsWidgets);
    expect(find.text(activeOrderReference), findsWidgets);
    expect(orders.cancelCount, 1);
    expect(orders.orders.items.single.status, 'CANCELLED');
  });
}