import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';

class OrderParseException implements Exception {
  const OrderParseException([this.message = 'Invalid order payload']);

  final String message;

  @override
  String toString() => message;
}

const openOrderStatuses = {'CREATED', 'CONFIRMED', 'ACTIVE'};
const terminalDeliveryStatuses = {'DELIVERED', 'FAILED', 'CANCELLED'};

Map<String, dynamic> orderAsMap(Object? value, String label) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw OrderParseException('$label must be an object');
}

String orderReqString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw OrderParseException('$key is required');
  }
  return value;
}

int orderReqInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.parse(value);
  }
  throw OrderParseException('$key must be an integer');
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.fulfillmentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.financial,
  });

  final String id;
  final String publicReference;
  final String status;
  final String fulfillmentStatus;
  final String paymentMethod;
  final String createdAt;
  final OrderFinancial financial;

  bool get isOpen => openOrderStatuses.contains(status);

  bool get isCancelled => status == 'CANCELLED';

  bool get isCompleted => status == 'COMPLETED';

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: orderReqString(json, 'id'),
      publicReference: orderReqString(json, 'publicReference'),
      status: orderReqString(json, 'status'),
      fulfillmentStatus: orderReqString(json, 'fulfillmentStatus'),
      paymentMethod: orderReqString(json, 'paymentMethod'),
      createdAt: orderReqString(json, 'createdAt'),
      financial: OrderFinancial.fromJson(
        orderAsMap(json['financial'], 'financial'),
      ),
    );
  }
}

class OrderPage {
  const OrderPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
  });

  final List<OrderSummary> items;
  final int limit;
  final int offset;
  final int total;

  factory OrderPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) {
      throw const OrderParseException('items must be a list');
    }
    return OrderPage(
      items: raw
          .map((item) => OrderSummary.fromJson(orderAsMap(item, 'order')))
          .toList(),
      limit: orderReqInt(json, 'limit'),
      offset: orderReqInt(json, 'offset'),
      total: orderReqInt(json, 'total'),
    );
  }
}

class CustomerDelivery {
  const CustomerDelivery({
    required this.id,
    required this.orderId,
    required this.publicReference,
    required this.status,
  });

  final String id;
  final String orderId;
  final String publicReference;
  final String status;

  bool get isTerminal => terminalDeliveryStatuses.contains(status);

  factory CustomerDelivery.fromJson(Map<String, dynamic> json) {
    return CustomerDelivery(
      id: orderReqString(json, 'id'),
      orderId: orderReqString(json, 'orderId'),
      publicReference: orderReqString(json, 'publicReference'),
      status: orderReqString(json, 'status'),
    );
  }
}

class ActiveOrderSnapshot {
  const ActiveOrderSnapshot({
    required this.orderId,
    required this.publicReference,
    required this.statusLabel,
  });

  final String orderId;
  final String publicReference;
  final String statusLabel;
}

bool isEligibleActiveOrder({required String status, String? deliveryStatus}) {
  if (!openOrderStatuses.contains(status)) {
    return false;
  }
  if (deliveryStatus != null &&
      terminalDeliveryStatuses.contains(deliveryStatus)) {
    return false;
  }
  return true;
}

String orderMoney(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || !MoneyFormat.isMinorString(value)) {
    throw OrderParseException(
      '$key must be an exact non-negative decimal string',
    );
  }
  return value;
}

class OrderFinancial {
  const OrderFinancial({
    required this.currency,
    required this.merchandiseSubtotalMinor,
    required this.deliveryFeeMinor,
    required this.customerTotalMinor,
  });

  final String currency;
  final String merchandiseSubtotalMinor;
  final String deliveryFeeMinor;
  final String customerTotalMinor;

  factory OrderFinancial.fromJson(Map<String, dynamic> json) {
    return OrderFinancial(
      currency: orderReqString(json, 'currency'),
      merchandiseSubtotalMinor: orderMoney(json, 'merchandiseSubtotalMinor'),
      deliveryFeeMinor: orderMoney(json, 'deliveryFeeMinor'),
      customerTotalMinor: orderMoney(json, 'customerTotalMinor'),
    );
  }
}

class OrderItemOption {
  const OrderItemOption({
    required this.optionNameSnapshot,
    required this.additionalPriceMinor,
  });

  final String optionNameSnapshot;
  final String additionalPriceMinor;

  factory OrderItemOption.fromJson(Map<String, dynamic> json) {
    return OrderItemOption(
      optionNameSnapshot: orderReqString(json, 'optionNameSnapshot'),
      additionalPriceMinor: orderMoney(json, 'additionalPriceMinor'),
    );
  }
}

class OrderItemDetail {
  const OrderItemDetail({
    required this.id,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    required this.options,
  });

  final String id;
  final String? productId;
  final String productNameSnapshot;
  final int quantity;
  final String unitPriceMinor;
  final String lineTotalMinor;
  final List<OrderItemOption> options;

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List) {
      throw const OrderParseException('options must be a list');
    }
    return OrderItemDetail(
      id: orderReqString(json, 'id'),
      productId: json['productId']?.toString(),
      productNameSnapshot: orderReqString(json, 'productNameSnapshot'),
      quantity: orderReqInt(json, 'quantity'),
      unitPriceMinor: orderMoney(json, 'unitPriceMinor'),
      lineTotalMinor: orderMoney(json, 'lineTotalMinor'),
      options: [
        for (final option in rawOptions)
          OrderItemOption.fromJson(orderAsMap(option, 'option')),
      ],
    );
  }
}

class OrderAddressSnapshot {
  const OrderAddressSnapshot({
    required this.addressText,
    required this.latitude,
    required this.longitude,
    this.instructions,
  });

  final String addressText;
  final double latitude;
  final double longitude;
  final String? instructions;

  factory OrderAddressSnapshot.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (lat is! num || lon is! num) {
      throw const OrderParseException('coordinates must be numbers');
    }
    return OrderAddressSnapshot(
      addressText: orderReqString(json, 'addressText'),
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      instructions: json['instructions']?.toString(),
    );
  }
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.fulfillmentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.merchantBranchId,
    required this.financial,
    required this.items,
    required this.deliveryAddress,
  });

  final String id;
  final String publicReference;
  final String status;
  final String fulfillmentStatus;
  final String paymentMethod;
  final String createdAt;
  final String merchantBranchId;
  final OrderFinancial financial;
  final List<OrderItemDetail> items;
  final OrderAddressSnapshot deliveryAddress;

  bool get awaitingMerchantAcceptance =>
      status == 'CREATED' && fulfillmentStatus == 'PENDING_ACCEPTANCE';

  bool get isCancelled => status == 'CANCELLED';

  bool get canCustomerCancel => awaitingMerchantAcceptance;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const OrderParseException('items must be a list');
    }
    return OrderDetail(
      id: orderReqString(json, 'id'),
      publicReference: orderReqString(json, 'publicReference'),
      status: orderReqString(json, 'status'),
      fulfillmentStatus: orderReqString(json, 'fulfillmentStatus'),
      paymentMethod: orderReqString(json, 'paymentMethod'),
      createdAt: orderReqString(json, 'createdAt'),
      merchantBranchId: orderReqString(json, 'merchantBranchId'),
      financial: OrderFinancial.fromJson(
        orderAsMap(json['financial'], 'financial'),
      ),
      items: [
        for (final item in rawItems)
          OrderItemDetail.fromJson(orderAsMap(item, 'item')),
      ],
      deliveryAddress: OrderAddressSnapshot.fromJson(
        orderAsMap(json['deliveryAddress'], 'deliveryAddress'),
      ),
    );
  }
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.addressId,
    required this.paymentMethod,
    required this.expectedMerchandiseSubtotalMinor,
    required this.expectedDeliveryFeeMinor,
    required this.expectedCustomerTotalMinor,
    this.promoCode,
  });

  final String addressId;
  final String paymentMethod;
  final int expectedMerchandiseSubtotalMinor;
  final int expectedDeliveryFeeMinor;
  final int expectedCustomerTotalMinor;
  final String? promoCode;

  factory CreateOrderRequest.fromPreview({
    required CheckoutPreview preview,
    required String addressId,
    required String paymentMethod,
    String? promoCode,
  }) {
    return CreateOrderRequest(
      addressId: addressId,
      paymentMethod: paymentMethod,
      expectedMerchandiseSubtotalMinor: int.parse(
        preview.merchandiseSubtotalMinor,
      ),
      expectedDeliveryFeeMinor: int.parse(preview.deliveryFeeMinor),
      expectedCustomerTotalMinor: int.parse(preview.customerTotalMinor),
      promoCode: promoCode?.trim().isEmpty ?? true ? null : promoCode!.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    final code = promoCode?.trim();
    return {
      'addressId': addressId,
      'paymentMethod': paymentMethod,
      'expectedMerchandiseSubtotalMinor': expectedMerchandiseSubtotalMinor,
      'expectedDeliveryFeeMinor': expectedDeliveryFeeMinor,
      'expectedCustomerTotalMinor': expectedCustomerTotalMinor,
      if (code != null && code.isNotEmpty) 'promoCode': code,
    };
  }
}

class OrderReconfirmationCurrent {
  const OrderReconfirmationCurrent({
    required this.merchandiseSubtotalMinor,
    required this.deliveryFeeMinor,
    required this.customerTotalMinor,
  });

  final String merchandiseSubtotalMinor;
  final String deliveryFeeMinor;
  final String customerTotalMinor;

  factory OrderReconfirmationCurrent.fromJson(Map<String, dynamic> json) {
    return OrderReconfirmationCurrent(
      merchandiseSubtotalMinor: orderMoney(json, 'merchandiseSubtotalMinor'),
      deliveryFeeMinor: orderMoney(json, 'deliveryFeeMinor'),
      customerTotalMinor: orderMoney(json, 'customerTotalMinor'),
    );
  }

  CheckoutPreview applyTo(CheckoutPreview preview) {
    return CheckoutPreview(
      checkoutReady: preview.checkoutReady,
      warnings: preview.warnings,
      cart: preview.cart,
      address: preview.address,
      deliveryZone: preview.deliveryZone,
      pricing: preview.pricing,
      merchandiseSubtotalMinor: merchandiseSubtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor,
      discountMinor: preview.discountMinor,
      promoCode: preview.promoCode,
      customerTotalMinor: customerTotalMinor,
    );
  }
}

class OrderReconfirmationException extends ApiException {
  OrderReconfirmationException({
    required String message,
    required this.changes,
    required this.current,
  }) : super(
         message,
         code: 'ORDER_RECONFIRMATION_REQUIRED',
         statusCode: 409,
       );

  final List<String> changes;
  final OrderReconfirmationCurrent current;
}

String checkoutPreviewFingerprint(CheckoutPreview preview) {
  return [
    preview.merchandiseSubtotalMinor,
    preview.deliveryFeeMinor,
    preview.discountMinor,
    preview.customerTotalMinor,
    preview.promoCode ?? '',
    preview.cart.id,
    preview.address.id,
  ].join('|');
}

String activeOrderStatusLabel({
  required String fulfillmentStatus,
  String? deliveryStatus,
  String? orderStatus,
}) {
  if (orderStatus == 'CANCELLED') {
    return AppStrings.orderStatusCancelled;
  }
  if (orderStatus == 'COMPLETED') {
    return AppStrings.orderStatusCompleted;
  }
  switch (deliveryStatus) {
    case 'SEARCHING_DRIVER':
      return AppStrings.orderStatusSearchingDriver;
    case 'DRIVER_ASSIGNED':
      return AppStrings.orderStatusDriverAssigned;
    case 'TO_PICKUP':
      return AppStrings.orderStatusToPickup;
    case 'AT_PICKUP':
      return AppStrings.orderStatusAtPickup;
    case 'PICKED_UP':
      return AppStrings.orderStatusPickedUp;
    case 'IN_TRANSIT':
      return AppStrings.orderStatusInTransit;
    case 'ARRIVED_CUSTOMER':
      return AppStrings.orderStatusArrived;
    case 'DELIVERED':
      return AppStrings.orderStatusCompleted;
  }
  switch (fulfillmentStatus) {
    case 'PENDING_ACCEPTANCE':
      return AppStrings.orderStatusPendingAcceptance;
    case 'ACCEPTED':
      return AppStrings.orderStatusAccepted;
    case 'PREPARING':
      return AppStrings.orderStatusPreparing;
    case 'READY':
      return AppStrings.orderStatusReady;
  }
  return AppStrings.activeOrder;
}

class OrderCancellationResult {
  const OrderCancellationResult({
    required this.orderId,
    required this.orderStatus,
    required this.cancellationAccepted,
    required this.refundRequired,
    this.refundId,
    this.refundStatus,
    this.refundAmountMinor,
    this.cancelledAt,
  });

  final String orderId;
  final String orderStatus;
  final bool cancellationAccepted;
  final bool refundRequired;
  final String? refundId;
  final String? refundStatus;
  final String? refundAmountMinor;
  final String? cancelledAt;

  factory OrderCancellationResult.fromJson(Map<String, dynamic> json) {
    return OrderCancellationResult(
      orderId: orderReqString(json, 'orderId'),
      orderStatus: orderReqString(json, 'orderStatus'),
      cancellationAccepted: json['cancellationAccepted'] == true,
      refundRequired: json['refundRequired'] == true,
      refundId: json['refundId']?.toString(),
      refundStatus: json['refundStatus']?.toString(),
      refundAmountMinor: json['refundAmountMinor']?.toString(),
      cancelledAt: json['cancelledAt']?.toString(),
    );
  }
}

class CustomerRefundItem {
  const CustomerRefundItem({
    required this.refundId,
    required this.amountMinor,
    required this.currency,
    required this.status,
    required this.method,
    required this.reason,
    required this.requestedAt,
    this.completedAt,
  });

  final String refundId;
  final String amountMinor;
  final String currency;
  final String status;
  final String method;
  final String reason;
  final String requestedAt;
  final String? completedAt;

  bool get isCompletedRepayment =>
      status == 'REFUNDED' && completedAt != null && completedAt!.isNotEmpty;

  factory CustomerRefundItem.fromJson(Map<String, dynamic> json) {
    return CustomerRefundItem(
      refundId: orderReqString(json, 'refundId'),
      amountMinor: orderMoney(json, 'amountMinor'),
      currency: orderReqString(json, 'currency'),
      status: orderReqString(json, 'status'),
      method: orderReqString(json, 'method'),
      reason: orderReqString(json, 'reason'),
      requestedAt: orderReqString(json, 'requestedAt'),
      completedAt: json['completedAt']?.toString(),
    );
  }
}

class CustomerOrderRefunds {
  const CustomerOrderRefunds({
    required this.orderId,
    required this.originalPaidMinor,
    required this.reservedRefundMinor,
    required this.successfulRefundMinor,
    required this.remainingRefundableMinor,
    required this.currency,
    required this.refunds,
  });

  final String orderId;
  final String originalPaidMinor;
  final String reservedRefundMinor;
  final String successfulRefundMinor;
  final String remainingRefundableMinor;
  final String currency;
  final List<CustomerRefundItem> refunds;

  bool get hasRefunds => refunds.isNotEmpty;

  factory CustomerOrderRefunds.fromJson(Map<String, dynamic> json) {
    final raw = json['refunds'];
    if (raw is! List) {
      throw const OrderParseException('refunds must be a list');
    }
    return CustomerOrderRefunds(
      orderId: orderReqString(json, 'orderId'),
      originalPaidMinor: orderMoney(json, 'originalPaidMinor'),
      reservedRefundMinor: orderMoney(json, 'reservedRefundMinor'),
      successfulRefundMinor: orderMoney(json, 'successfulRefundMinor'),
      remainingRefundableMinor: orderMoney(json, 'remainingRefundableMinor'),
      currency: orderReqString(json, 'currency'),
      refunds: [
        for (final item in raw)
          CustomerRefundItem.fromJson(orderAsMap(item, 'refund')),
      ],
    );
  }
}

String customerRefundStatusLabel(String status) {
  switch (status) {
    case 'REQUESTED':
      return AppStrings.orderRefundStatusRequested;
    case 'UNDER_REVIEW':
      return AppStrings.orderRefundStatusUnderReview;
    case 'APPROVED':
      return AppStrings.orderRefundStatusApproved;
    case 'PROCESSING':
      return AppStrings.orderRefundStatusProcessing;
    case 'REFUNDED':
      return AppStrings.orderRefundStatusRefunded;
    case 'REJECTED':
      return AppStrings.orderRefundStatusRejected;
    case 'FAILED':
      return AppStrings.orderRefundStatusFailed;
    default:
      return status;
  }
}
