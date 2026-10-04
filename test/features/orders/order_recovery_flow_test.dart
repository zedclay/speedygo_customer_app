import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/last_created_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_confirmation_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/orders_tab_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

ProviderContainer _ordersOnly(FakeOrdersClient orders) {
  return ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue('test:scope'),
      ordersApiProvider.overrideWithValue(orders),
      coverImageBytesProvider.overrideWith((ref, path) async => null),
    ],
  );
}

void main() {
  testWidgets('orders tab lists API orders and opens detail', (tester) async {
    final detail = sampleOrderDetail(
      id: activeOrderId,
      publicReference: activeOrderReference,
      customerTotalMinor: '1900',
    );
    final orders = FakeOrdersClient(
      orders: orderPage([
        sampleOrder(
          id: activeOrderId,
          publicReference: activeOrderReference,
          status: 'CREATED',
          fulfillmentStatus: 'PENDING_ACCEPTANCE',
        ),
      ]),
    )..details[activeOrderId] = detail;

    final container = _ordersOnly(orders);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.orders,
      routes: [
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
    expect(orders.listCount, greaterThan(0));
    expect(find.text(activeOrderReference), findsOneWidget);

    await tester.tap(find.byKey(const Key('order-list-tile-$activeOrderId')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.orderDetailTitle), findsOneWidget);
    expect(find.textContaining(activeOrderReference), findsWidgets);
    expect(find.text(MoneyFormat.dzd('1900')), findsWidgets);
    expect(
      find.byKey(const Key('order-detail-awaiting-merchant')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('order-detail-no-payment')), findsOneWidget);
  });

  testWidgets('confirmation is distinct from pending-verification copy', (
    tester,
  ) async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('test:scope'),
        ordersApiProvider.overrideWithValue(orders),
        lastCreatedOrderProvider.overrideWith(
          () => _SeededLastCreated(detail),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OrderConfirmationScreen(orderId: detail.id),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.orderConfirmationSent), findsOneWidget);
    expect(
      find.text(AppStrings.orderSubmissionPendingVerification),
      findsNothing,
    );
  });
}

class _SeededLastCreated extends LastCreatedOrderController {
  _SeededLastCreated(this._order);
  final OrderDetail _order;
  @override
  OrderDetail? build() => _order;
}
