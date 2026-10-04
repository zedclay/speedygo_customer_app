import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';

import '../../helpers/order_fixtures.dart';

void main() {
  test('awaiting merchant is not searching driver', () {
    final stage = resolveOrderTrackingStage(
      order: sampleOrderDetail(),
      deliveryNotFound: true,
    );
    expect(stage, OrderTrackingStage.awaitingMerchant);
  });

  test('READY without delivery is readyAwaitingDelivery not search', () {
    final stage = resolveOrderTrackingStage(
      order: sampleOrderDetail(
        status: 'ACTIVE',
        fulfillmentStatus: 'READY',
      ),
      deliveryNotFound: true,
    );
    expect(stage, OrderTrackingStage.readyAwaitingDelivery);
    expect(stage, isNot(OrderTrackingStage.searchingDriver));
  });

  test('SEARCHING_DRIVER only when delivery status says so', () {
    final stage = resolveOrderTrackingStage(
      order: sampleOrderDetail(
        status: 'ACTIVE',
        fulfillmentStatus: 'READY',
      ),
      delivery: sampleDelivery(status: 'SEARCHING_DRIVER'),
    );
    expect(stage, OrderTrackingStage.searchingDriver);
  });

  test('cancelled order is terminal cancelled', () {
    final stage = resolveOrderTrackingStage(
      order: sampleOrderDetail(status: 'CANCELLED'),
      deliveryNotFound: true,
    );
    expect(stage, OrderTrackingStage.cancelled);
    expect(orderTrackingStageIsTerminal(stage), isTrue);
    expect(
      orderTrackingStageTitle(stage),
      AppStrings.orderStatusCancelled,
    );
  });

  test('unknown status is not completed', () {
    final stage = resolveOrderTrackingStage(
      order: sampleOrderDetail(
        status: 'CREATED',
        fulfillmentStatus: 'READY',
      ),
    );
    // CREATED + READY is inconsistent; must not look completed.
    expect(stage, isNot(OrderTrackingStage.completed));
    expect(stage, isNot(OrderTrackingStage.delivered));
  });

  test('older recordedAt is rejected', () {
    expect(
      shouldAcceptRecordedAt(
        previousRecordedAt: '2026-09-10T12:00:00.000Z',
        incomingRecordedAt: '2026-09-10T11:00:00.000Z',
      ),
      isFalse,
    );
    expect(
      shouldAcceptRecordedAt(
        previousRecordedAt: '2026-09-10T12:00:00.000Z',
        incomingRecordedAt: '2026-09-10T12:00:01.000Z',
      ),
      isTrue,
    );
  });
}
