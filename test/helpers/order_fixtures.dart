import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';
import 'catalog_fixtures.dart';

const activeOrderId = '11111111-1111-4111-8111-111111111111';
const activeOrderReference = 'sgo_abc123def456';

OrderSummary sampleOrder({
  String id = activeOrderId,
  String publicReference = activeOrderReference,
  String status = 'CREATED',
  String fulfillmentStatus = 'PENDING_ACCEPTANCE',
  String paymentMethod = 'COD',
  String createdAt = '2026-09-09T21:00:00.000Z',
  String customerTotalMinor = '1900',
}) {
  return OrderSummary(
    id: id,
    publicReference: publicReference,
    status: status,
    fulfillmentStatus: fulfillmentStatus,
    paymentMethod: paymentMethod,
    createdAt: createdAt,
    financial: OrderFinancial(
      currency: 'DZD',
      merchandiseSubtotalMinor: '1400',
      deliveryFeeMinor: '500',
      customerTotalMinor: customerTotalMinor,
    ),
  );
}

OrderPage orderPage(List<OrderSummary> items) {
  return OrderPage(items: items, limit: 20, offset: 0, total: items.length);
}

OrderDetail sampleOrderDetail({
  String id = activeOrderId,
  String publicReference = activeOrderReference,
  String status = 'CREATED',
  String fulfillmentStatus = 'PENDING_ACCEPTANCE',
  String paymentMethod = 'COD',
  String merchandiseSubtotalMinor = '1400',
  String deliveryFeeMinor = '500',
  String customerTotalMinor = '1900',
  String discountMinor = '0',
  String createdAt = '2026-09-09T21:00:00.000Z',
}) {
  return OrderDetail(
    id: id,
    publicReference: publicReference,
    status: status,
    fulfillmentStatus: fulfillmentStatus,
    paymentMethod: paymentMethod,
    createdAt: createdAt,
    merchantBranchId: cafeBranchId,
    financial: OrderFinancial(
      currency: 'DZD',
      merchandiseSubtotalMinor: merchandiseSubtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor,
      discountMinor: discountMinor,
      discountFieldPresent: true,
      customerTotalMinor: customerTotalMinor,
    ),
    items: const [
      OrderItemDetail(
        id: '33333333-3333-4333-8333-333333333333',
        productId: espressoProductId,
        productNameSnapshot: 'Espresso',
        quantity: 1,
        unitPriceMinor: '1400',
        lineTotalMinor: '1400',
        options: [
          OrderItemOption(
            optionNameSnapshot: 'Double',
            additionalPriceMinor: '200',
          ),
        ],
      ),
    ],
    deliveryAddress: const OrderAddressSnapshot(
      addressText: 'Cité 120 logements',
      latitude: 36.75,
      longitude: 3.05,
    ),
  );
}

CustomerDeliveryDetail sampleDelivery({
  String id = '22222222-2222-4222-8222-222222222222',
  String orderId = activeOrderId,
  String publicReference = activeOrderReference,
  String status = 'IN_TRANSIT',
  String orderStatus = 'ACTIVE',
  String fulfillmentStatus = 'READY',
}) {
  return CustomerDeliveryDetail(
    id: id,
    orderId: orderId,
    publicReference: publicReference,
    status: status,
    orderStatus: orderStatus,
    fulfillmentStatus: fulfillmentStatus,
    createdAt: DateTime.now().toUtc().toIso8601String(),
    updatedAt: DateTime.now().toUtc().toIso8601String(),
    pickup: const DeliveryPickup(
      merchantBranchId: cafeBranchId,
      name: 'Café Test',
      addressText: 'Rue Test',
      latitude: 36.75,
      longitude: 3.05,
    ),
    dropoff: const DeliveryDropoff(
      addressText: 'Cité 120 logements',
      latitude: 36.76,
      longitude: 3.06,
    ),
    events: const [],
  );
}

RatingSummary ratedSummary({
  String merchantId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  int count = 12,
  double average = 4.7,
}) {
  return RatingSummary(
    targetType: 'MERCHANT',
    targetId: merchantId,
    count: count,
    average: average,
  );
}
