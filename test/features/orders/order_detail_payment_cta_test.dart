import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/config/electronic_payment_config.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_detail_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

CustomerPayment _payment({String status = 'PENDING'}) {
  return CustomerPayment(
    paymentId: 'pay-1',
    method: 'ELECTRONIC',
    status: status,
    amountMinor: '1700',
    currency: 'DZD',
    provider: 'test',
    createdAt: '2026-09-10T00:00:00.000Z',
    updatedAt: '2026-09-10T00:00:00.000Z',
  );
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required FakeOrdersClient orders,
  required String orderId,
  ElectronicPaymentAvailability availability =
      const ElectronicPaymentAvailability(enabledForCheckout: true),
}) async {
  final container = ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue('test:pay'),
      ordersApiProvider.overrideWithValue(orders),
      electronicPaymentAvailabilityProvider.overrideWithValue(availability),
      coverImageBytesProvider.overrideWith((ref, path) async => null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: OrderDetailScreen(orderId: orderId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('hides pay CTA on COMPLETED ELECTRONIC even when flag is on', (
    tester,
  ) async {
    final detail = sampleOrderDetail(
      status: 'COMPLETED',
      fulfillmentStatus: 'READY',
      paymentMethod: 'ELECTRONIC',
    );
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentsByOrder[detail.id] = _payment(status: 'SUCCEEDED');
    await _pumpDetail(tester, orders: orders, orderId: detail.id);
    expect(find.byKey(const Key('order-detail-payment-entry')), findsNothing);
    expect(find.byKey(const Key('order-detail-rate-entry')), findsOneWidget);
  });

  testWidgets('hides pay CTA on CANCELLED ELECTRONIC even when flag is on', (
    tester,
  ) async {
    final detail = sampleOrderDetail(
      status: 'CANCELLED',
      fulfillmentStatus: 'PENDING_ACCEPTANCE',
      paymentMethod: 'ELECTRONIC',
    );
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentsByOrder[detail.id] = _payment();
    await _pumpDetail(tester, orders: orders, orderId: detail.id);
    expect(find.byKey(const Key('order-detail-payment-entry')), findsNothing);
  });

  testWidgets('hides pay CTA when payment succeeded on an open order', (
    tester,
  ) async {
    final detail = sampleOrderDetail(
      status: 'CONFIRMED',
      fulfillmentStatus: 'PREPARING',
      paymentMethod: 'ELECTRONIC',
    );
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentsByOrder[detail.id] = _payment(status: 'SUCCEEDED');
    await _pumpDetail(tester, orders: orders, orderId: detail.id);
    expect(find.byKey(const Key('order-detail-payment-entry')), findsNothing);
  });

  testWidgets('hides pay CTA when eligibility is unknown', (tester) async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    await _pumpDetail(tester, orders: orders, orderId: detail.id);
    expect(find.byKey(const Key('order-detail-payment-entry')), findsNothing);
  });

  testWidgets('hides pay CTA when electronic payments are flagged off', (
    tester,
  ) async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentsByOrder[detail.id] = _payment();
    await _pumpDetail(
      tester,
      orders: orders,
      orderId: detail.id,
      availability: ElectronicPaymentAvailability.disabled,
    );
    expect(find.byKey(const Key('order-detail-payment-entry')), findsNothing);
  });

  testWidgets('shows pay CTA for pending ELECTRONIC when the flag is on', (
    tester,
  ) async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentsByOrder[detail.id] = _payment();
    await _pumpDetail(tester, orders: orders, orderId: detail.id);
    expect(find.byKey(const Key('order-detail-payment-entry')), findsOneWidget);
  });

  testWidgets('promo order detail shows discount and reconciles payable', (
    tester,
  ) async {
    final detail = sampleOrderDetail(
      merchandiseSubtotalMinor: '1400',
      deliveryFeeMinor: '500',
      discountMinor: '400',
      customerTotalMinor: '1500',
    );
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    await _pumpDetail(
      tester,
      orders: orders,
      orderId: detail.id,
      availability: ElectronicPaymentAvailability.disabled,
    );
    expect(find.text(AppStrings.checkoutDiscount), findsOneWidget);
    expect(find.text('−${MoneyFormat.dzd('400')}'), findsOneWidget);
    expect(find.text(AppStrings.checkoutMerchandise), findsOneWidget);
    expect(find.text(MoneyFormat.dzd('1500')), findsWidgets);
  });

  testWidgets('unreconciled missing discount shows total only', (tester) async {
    final base = sampleOrderDetail(
      merchandiseSubtotalMinor: '1400',
      deliveryFeeMinor: '500',
      customerTotalMinor: '1500',
    );
    final detail = OrderDetail(
      id: base.id,
      publicReference: base.publicReference,
      status: base.status,
      fulfillmentStatus: base.fulfillmentStatus,
      paymentMethod: base.paymentMethod,
      createdAt: base.createdAt,
      merchantBranchId: base.merchantBranchId,
      financial: OrderFinancial.fromJson({
        'currency': 'DZD',
        'merchandiseSubtotalMinor': '1400',
        'deliveryFeeMinor': '500',
        'customerTotalMinor': '1500',
      }),
      items: base.items,
      deliveryAddress: base.deliveryAddress,
    );
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    await _pumpDetail(
      tester,
      orders: orders,
      orderId: detail.id,
      availability: ElectronicPaymentAvailability.disabled,
    );
    expect(find.text(AppStrings.checkoutMerchandise), findsNothing);
    expect(find.text(AppStrings.checkoutDeliveryFee), findsNothing);
    expect(find.text(AppStrings.checkoutDiscount), findsNothing);
    expect(find.text(MoneyFormat.dzd('1500')), findsWidgets);
  });
}
