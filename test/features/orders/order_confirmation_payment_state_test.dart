import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/last_created_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_confirmation_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

class _SeededLastCreated extends LastCreatedOrderController {
  _SeededLastCreated(this._order);
  final OrderDetail _order;
  @override
  OrderDetail? build() => _order;
}

Future<void> _pumpConfirmation(
  WidgetTester tester, {
  required OrderDetail order,
  CustomerPayment? payment,
}) async {
  final orders = FakeOrdersClient()
    ..details[order.id] = order
    ..paymentResult = payment;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogScopeProvider.overrideWithValue('test:scope'),
        ordersApiProvider.overrideWithValue(orders),
        lastCreatedOrderProvider.overrideWith(() => _SeededLastCreated(order)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: OrderConfirmationScreen(orderId: order.id),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('COD: collection status + amount due at delivery', (tester) async {
    final order = sampleOrderDetail(paymentMethod: 'COD');
    await _pumpConfirmation(tester, order: order);
    expect(find.text(AppStrings.orderConfirmationSent), findsOneWidget);
    expect(find.text(AppStrings.orderItemsLabel), findsOneWidget);
    expect(
      find.text(AppStrings.orderConfirmationNoPaymentCollected),
      findsOneWidget,
    );
    expect(find.text(AppStrings.orderConfirmationAmountCod), findsOneWidget);
    expect(find.text(AppStrings.checkoutPayable), findsNothing);
    expect(find.text(AppStrings.orderConfirmationAmountPaid), findsNothing);
    expect(find.byKey(const Key('order-confirmation-continue-payment')), findsNothing);
  });

  testWidgets('ELECTRONIC SUCCEEDED: paid amount + confirmed status', (
    tester,
  ) async {
    final order = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    await _pumpConfirmation(
      tester,
      order: order,
      payment: const CustomerPayment(
        paymentId: 'pay-1',
        method: 'ELECTRONIC',
        status: 'SUCCEEDED',
        amountMinor: '1900',
        currency: 'DZD',
        provider: 'mock',
        createdAt: '2026-09-11T00:00:00.000Z',
        updatedAt: '2026-09-11T00:00:00.000Z',
      ),
    );
    expect(
      find.text(AppStrings.orderConfirmationPaymentSucceeded),
      findsOneWidget,
    );
    expect(find.text(AppStrings.orderConfirmationAmountPaid), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmationAmountCod), findsNothing);
    expect(find.text(AppStrings.checkoutPayable), findsNothing);
    expect(find.byKey(const Key('order-confirmation-continue-payment')), findsNothing);
  });

  testWidgets('ELECTRONIC pending: no paid claim + continue CTA', (tester) async {
    final order = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    await _pumpConfirmation(
      tester,
      order: order,
      payment: const CustomerPayment(
        paymentId: 'pay-1',
        method: 'ELECTRONIC',
        status: 'PENDING',
        amountMinor: '1900',
        currency: 'DZD',
        provider: 'mock',
        createdAt: '2026-09-11T00:00:00.000Z',
        updatedAt: '2026-09-11T00:00:00.000Z',
      ),
    );
    expect(
      find.text(AppStrings.orderConfirmationPaymentPending),
      findsOneWidget,
    );
    expect(find.text(AppStrings.orderConfirmationAmountDue), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmationAmountPaid), findsNothing);
    expect(
      find.byKey(const Key('order-confirmation-continue-payment')),
      findsOneWidget,
    );
  });

  testWidgets('ELECTRONIC FAILED: explicit failed status, no paid claim', (
    tester,
  ) async {
    final order = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    await _pumpConfirmation(
      tester,
      order: order,
      payment: const CustomerPayment(
        paymentId: 'pay-1',
        method: 'ELECTRONIC',
        status: 'FAILED',
        amountMinor: '1900',
        currency: 'DZD',
        provider: 'mock',
        createdAt: '2026-09-11T00:00:00.000Z',
        updatedAt: '2026-09-11T00:00:00.000Z',
      ),
    );
    expect(
      find.text(AppStrings.orderConfirmationPaymentFailed),
      findsOneWidget,
    );
    expect(find.text(AppStrings.orderConfirmationAmountDue), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmationAmountPaid), findsNothing);
  });

  testWidgets('payment status is reachable by scrolling above sticky actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final order = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    await _pumpConfirmation(
      tester,
      order: order,
      payment: const CustomerPayment(
        paymentId: 'pay-1',
        method: 'ELECTRONIC',
        status: 'SUCCEEDED',
        amountMinor: '1900',
        currency: 'DZD',
        provider: 'mock',
        createdAt: '2026-09-11T00:00:00.000Z',
        updatedAt: '2026-09-11T00:00:00.000Z',
      ),
    );

    final status = find.byKey(const Key('order-confirmation-payment-status'));
    await tester.ensureVisible(status);
    await tester.pump();
    final statusRect = tester.getRect(status);
    final detailRect = tester.getRect(
      find.byKey(const Key('order-confirmation-detail')),
    );
    expect(statusRect.bottom, lessThanOrEqualTo(detailRect.top + 1));
    expect(find.byKey(const Key('order-confirmation-detail')), findsOneWidget);
    expect(find.byKey(const Key('order-confirmation-home')), findsOneWidget);
  });
}
