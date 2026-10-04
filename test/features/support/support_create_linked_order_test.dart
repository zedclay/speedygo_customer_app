import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_create_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

void main() {
  testWidgets('linked support shows publicReference, not raw UUID', (
    tester,
  ) async {
    final order = sampleOrderDetail();
    final orders = FakeOrdersClient()..details[order.id] = order;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('test:scope'),
          ordersApiProvider.overrideWithValue(orders),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: SupportCreateScreen(orderId: order.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(order.publicReference), findsOneWidget);
    expect(find.text(order.id), findsNothing);
    expect(
      find.text(MoneyFormat.dzd(order.financial.customerTotalMinor)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.supportOrderOptional), findsNothing);
    expect(find.byKey(const Key('support-create-order-reference')), findsOneWidget);
  });

  testWidgets('linked support fallback omits UUID when order fails to load', (
    tester,
  ) async {
    final orders = FakeOrdersClient()
      ..getError = Exception('unavailable');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('test:scope'),
          ordersApiProvider.overrideWithValue(orders),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupportCreateScreen(orderId: activeOrderId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('support-create-order-fallback')), findsOneWidget);
    expect(find.text(activeOrderId), findsNothing);
    expect(find.byKey(const Key('support-create-order-reference')), findsNothing);
  });

  testWidgets('general support has no linked-order card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('test:scope'),
          ordersApiProvider.overrideWithValue(FakeOrdersClient()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupportCreateScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('support-create-order-reference')), findsNothing);
    expect(find.text(AppStrings.supportNewTitle), findsOneWidget);
  });
}
