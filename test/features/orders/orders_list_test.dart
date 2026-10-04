import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/orders_tab_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

void main() {
  test('OrderSummary requires financial totals from the list contract', () {
    final summary = OrderSummary.fromJson({
      'id': activeOrderId,
      'publicReference': activeOrderReference,
      'status': 'CREATED',
      'fulfillmentStatus': 'PENDING_ACCEPTANCE',
      'paymentMethod': 'COD',
      'createdAt': '2026-09-09T21:00:00.000Z',
      'financial': {
        'currency': 'DZD',
        'merchandiseSubtotalMinor': '1400',
        'deliveryFeeMinor': '500',
        'customerTotalMinor': '1900',
      },
    });
    expect(summary.financial.customerTotalMinor, '1900');
    expect(summary.paymentMethod, 'COD');
    expect(
      () => OrderSummary.fromJson({
        'id': activeOrderId,
        'publicReference': activeOrderReference,
        'status': 'CREATED',
        'fulfillmentStatus': 'PENDING_ACCEPTANCE',
      }),
      throwsA(isA<OrderParseException>()),
    );
  });

  testWidgets('orders tab pages and filters cancelled separately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final open = sampleOrder();
    final done = sampleOrder(
      id: '22222222-2222-4222-8222-222222222222',
      publicReference: 'sgo_completed001',
      status: 'COMPLETED',
      fulfillmentStatus: 'READY',
    );
    final cancelled = sampleOrder(
      id: '33333333-3333-4333-8333-333333333333',
      publicReference: 'sgo_cancelled001',
      status: 'CANCELLED',
      fulfillmentStatus: 'PENDING_ACCEPTANCE',
    );
    final extra = sampleOrder(
      id: '44444444-4444-4444-8444-444444444444',
      publicReference: 'sgo_extra000001',
    );
    final orders = FakeOrdersClient()
      ..pagedItems = [open, extra, done, cancelled];

    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('test:orders'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.orders,
      routes: [
        GoRoute(
          path: AppRoutes.orders,
          builder: (_, _) => const OrdersTabScreen(),
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

    expect(orders.lastListLimit, 20);
    expect(find.text(activeOrderReference), findsOneWidget);
    expect(find.text(MoneyFormat.dzd('1900')), findsWidgets);
    expect(find.text('sgo_completed001'), findsNothing);
    expect(find.text('sgo_cancelled001'), findsNothing);

    await tester.tap(find.text(AppStrings.ordersTabCompleted));
    await tester.pumpAndSettle();
    expect(find.text('sgo_completed001'), findsOneWidget);
    expect(find.text(activeOrderReference), findsNothing);

    await tester.tap(find.text(AppStrings.ordersTabCancelled));
    await tester.pumpAndSettle();
    expect(find.text('sgo_cancelled001'), findsOneWidget);
    expect(find.text(AppStrings.orderStatusCancelled), findsWidgets);
  });
}
