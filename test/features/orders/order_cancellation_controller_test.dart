import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/order_cancellation_controller.dart';
import 'package:speedygo_customer_app/features/orders/application/orders_list_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

ProviderContainer _container(FakeOrdersClient orders) {
  return ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue('test:cancel'),
      ordersApiProvider.overrideWithValue(orders),
    ],
  );
}

void main() {
  test('OrderCancellationResult and refunds parse contract fields', () {
    final cancel = OrderCancellationResult.fromJson({
      'orderId': activeOrderId,
      'orderStatus': 'CANCELLED',
      'cancellationAccepted': true,
      'refundRequired': false,
      'refundId': null,
      'refundStatus': null,
      'refundAmountMinor': null,
      'cancelledAt': '2026-09-09T21:00:00.000Z',
    });
    expect(cancel.cancellationAccepted, isTrue);
    expect(cancel.refundRequired, isFalse);

    final refunds = CustomerOrderRefunds.fromJson({
      'orderId': activeOrderId,
      'originalPaidMinor': '1900',
      'reservedRefundMinor': '1900',
      'successfulRefundMinor': '0',
      'remainingRefundableMinor': '0',
      'currency': 'DZD',
      'refunds': [
        {
          'refundId': 'r1',
          'amountMinor': '1900',
          'currency': 'DZD',
          'status': 'REQUESTED',
          'method': 'MANUAL_OTHER',
          'reason': 'Customer cancelled',
          'requestedAt': '2026-09-09T21:00:00.000Z',
          'completedAt': null,
        },
      ],
    });
    expect(refunds.hasRefunds, isTrue);
    expect(refunds.refunds.single.isCompletedRepayment, isFalse);
    expect(
      customerRefundStatusLabel('REQUESTED'),
      AppStrings.orderRefundStatusRequested,
    );
  });

  test('cancelled status label does not reuse pending acceptance', () {
    expect(
      activeOrderStatusLabel(
        fulfillmentStatus: 'PENDING_ACCEPTANCE',
        orderStatus: 'CANCELLED',
      ),
      AppStrings.orderStatusCancelled,
    );
  });

  test('confirm cancels eligible COD without claiming a refund', () async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient(
      orders: orderPage([sampleOrder()]),
      cancelResult: OrderCancellationResult(
        orderId: detail.id,
        orderStatus: 'CANCELLED',
        cancellationAccepted: true,
        refundRequired: false,
        cancelledAt: '2026-09-09T21:00:00.000Z',
      ),
    )..details[detail.id] = detail;

    final container = _container(orders);
    addTearDown(container.dispose);
    container.listen(orderCancellationControllerProvider, (_, _) {});
    container.listen(ordersListControllerProvider, (_, _) {});
    container.listen(activeOrderControllerProvider, (_, _) {});

    final result = await container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);

    expect(result?.cancellationAccepted, isTrue);
    expect(orders.cancelCount, 1);
    expect(
      container.read(orderCancellationControllerProvider).phase,
      OrderCancellationPhase.accepted,
    );
    expect(
      container.read(orderCancellationControllerProvider).message,
      contains(AppStrings.orderCancelCodNoRefund),
    );
    expect(
      container.read(ordersListControllerProvider).items.single.status,
      'CANCELLED',
    );
    expect(container.read(activeOrderControllerProvider).value, isNull);
  });

  test('disallowed state rejects without POST', () async {
    final detail = sampleOrderDetail(
      status: 'ACTIVE',
      fulfillmentStatus: 'ACCEPTED',
    );
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = _container(orders);
    addTearDown(container.dispose);

    final result = await container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);

    expect(result, isNull);
    expect(orders.cancelCount, 0);
    expect(
      container.read(orderCancellationControllerProvider).phase,
      OrderCancellationPhase.rejected,
    );
  });

  test('double tap while in flight does not duplicate cancel POST', () async {
    final detail = sampleOrderDetail();
    final gate = Completer<void>();
    final orders = FakeOrdersClient()
      ..gateCancel = gate
      ..details[detail.id] = detail;
    final container = _container(orders);
    addTearDown(container.dispose);

    final first = container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);
    final second = container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);
    await Future<void>.delayed(Duration.zero);
    expect(orders.cancelCount, 1);
    gate.complete();
    await Future.wait([first, second]);
    expect(orders.cancelCount, 1);
  });

  test('timeout enters pending verification without auto re-POST', () async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient(
      cancelError: const NetworkException(
        AppStrings.offline,
        code: 'NETWORK_TIMEOUT',
      ),
    )..details[detail.id] = detail;
    final container = _container(orders);
    addTearDown(container.dispose);

    final result = await container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);

    expect(result, isNull);
    expect(orders.cancelCount, 1);
    expect(
      container.read(orderCancellationControllerProvider).phase,
      OrderCancellationPhase.pendingVerification,
    );

    final again = await container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);
    expect(again, isNull);
    expect(orders.cancelCount, 1);
  });

  test('verification reconciles cancelled order via GET only', () async {
    final detail = sampleOrderDetail();
    final cancelled = sampleOrderDetail(status: 'CANCELLED');
    final orders = FakeOrdersClient(
      cancelError: const ApiException(
        AppStrings.orderCancelPendingVerification,
        code: 'ORDER_CANCELLATION_SERVER_UNCERTAIN',
        statusCode: 503,
      ),
    )..details[detail.id] = detail;
    final container = _container(orders);
    addTearDown(container.dispose);

    await container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);
    expect(orders.cancelCount, 1);

    orders.details[detail.id] = cancelled;
    orders.cancelError = null;
    final reconciled = await container
        .read(orderCancellationControllerProvider.notifier)
        .retryVerification(detail);

    expect(reconciled?.cancellationAccepted, isTrue);
    expect(orders.cancelCount, 1);
    expect(orders.getCount, greaterThan(0));
    expect(
      container.read(orderCancellationControllerProvider).phase,
      OrderCancellationPhase.accepted,
    );
  });

  test('stale cancel response is ignored after catalog scope change', () async {
    final detail = sampleOrderDetail();
    final gate = Completer<void>();
    final orders = FakeOrdersClient(
      cancelResult: OrderCancellationResult(
        orderId: detail.id,
        orderStatus: 'CANCELLED',
        cancellationAccepted: true,
        refundRequired: false,
      ),
    )
      ..gateCancel = gate
      ..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    container.read(orderCancellationControllerProvider);
    final pending = container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);
    await Future<void>.delayed(Duration.zero);

    container.updateOverrides([
      catalogScopeProvider.overrideWithValue('scope-b'),
      ordersApiProvider.overrideWithValue(orders),
    ]);
    container.read(orderCancellationControllerProvider);
    gate.complete();
    final result = await pending;
    expect(result, isNull);
    expect(
      container.read(orderCancellationControllerProvider).phase,
      OrderCancellationPhase.idle,
    );
  });

  test('server denial maps to rejected without refund copy', () async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient(
      cancelError: const ApiException(
        AppStrings.orderCancelNotEligible,
        code: 'ORDER_CANCELLATION_NOT_ALLOWED',
        statusCode: 409,
      ),
    )..details[detail.id] = detail;
    final container = _container(orders);
    addTearDown(container.dispose);

    await container
        .read(orderCancellationControllerProvider.notifier)
        .confirm(detail);

    expect(
      container.read(orderCancellationControllerProvider).phase,
      OrderCancellationPhase.rejected,
    );
    expect(
      container.read(orderCancellationControllerProvider).message,
      AppStrings.orderCancelNotEligible,
    );
  });
}
