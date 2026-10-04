import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

/// Transient tracking snapshot status (not a Delivery DB status).
const trackingSnapshotStatuses = {'LIVE', 'STALE', 'UNAVAILABLE', 'NO_DRIVER'};

class TrackingLocation {
  const TrackingLocation({
    required this.deliveryId,
    required this.assignedDriverId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
  });

  final String deliveryId;
  final String assignedDriverId;
  final double latitude;
  final double longitude;
  final String recordedAt;
  final double? accuracyMeters;

  factory TrackingLocation.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (lat is! num || lon is! num) {
      throw const OrderParseException('tracking coordinates must be numbers');
    }
    final accuracy = json['accuracyMeters'];
    return TrackingLocation(
      deliveryId: orderReqString(json, 'deliveryId'),
      assignedDriverId: orderReqString(json, 'assignedDriverId'),
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      recordedAt: orderReqString(json, 'recordedAt'),
      accuracyMeters: accuracy is num ? accuracy.toDouble() : null,
    );
  }
}

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.orderId,
    required this.driverAssigned,
    required this.status,
    required this.isStale,
    this.deliveryId,
    this.assignedDriverId,
    this.location,
  });

  final String? deliveryId;
  final String orderId;
  final bool driverAssigned;
  final String? assignedDriverId;
  final String status;
  final bool isStale;
  final TrackingLocation? location;

  bool get isLive => status == 'LIVE' && location != null;

  factory TrackingSnapshot.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    return TrackingSnapshot(
      deliveryId: json['deliveryId']?.toString(),
      orderId: orderReqString(json, 'orderId'),
      driverAssigned: json['driverAssigned'] == true,
      assignedDriverId: json['assignedDriverId']?.toString(),
      status: orderReqString(json, 'status'),
      isStale: json['isStale'] == true,
      location: rawLocation is Map
          ? TrackingLocation.fromJson(orderAsMap(rawLocation, 'location'))
          : null,
    );
  }
}

class DeliveryEvent {
  const DeliveryEvent({
    required this.type,
    required this.occurredAt,
    this.driverId,
  });

  final String type;
  final String occurredAt;
  final String? driverId;

  factory DeliveryEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryEvent(
      type: orderReqString(json, 'type'),
      occurredAt: orderReqString(json, 'occurredAt'),
      driverId: json['driverId']?.toString(),
    );
  }
}

class DeliveryPickup {
  const DeliveryPickup({
    required this.merchantBranchId,
    required this.name,
    required this.addressText,
    required this.latitude,
    required this.longitude,
  });

  final String merchantBranchId;
  final String name;
  final String addressText;
  final double latitude;
  final double longitude;

  factory DeliveryPickup.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (lat is! num || lon is! num) {
      throw const OrderParseException('pickup coordinates must be numbers');
    }
    return DeliveryPickup(
      merchantBranchId: orderReqString(json, 'merchantBranchId'),
      name: orderReqString(json, 'name'),
      addressText: orderReqString(json, 'addressText'),
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
    );
  }
}

class DeliveryDropoff {
  const DeliveryDropoff({
    required this.addressText,
    required this.latitude,
    required this.longitude,
    this.instructions,
  });

  final String addressText;
  final double latitude;
  final double longitude;
  final String? instructions;

  factory DeliveryDropoff.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (lat is! num || lon is! num) {
      throw const OrderParseException('dropoff coordinates must be numbers');
    }
    return DeliveryDropoff(
      addressText: orderReqString(json, 'addressText'),
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      instructions: json['instructions']?.toString(),
    );
  }
}

/// Customer-visible delivery aggregate. Absent Delivery → HTTP DELIVERY_NOT_FOUND.
class CustomerDeliveryDetail {
  const CustomerDeliveryDetail({
    required this.id,
    required this.orderId,
    required this.publicReference,
    required this.status,
    required this.orderStatus,
    required this.fulfillmentStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.pickup,
    required this.dropoff,
    required this.events,
    this.assignedDriverId,
    this.driverSearchStartedAt,
    this.pickedUpAt,
    this.estimatedArrivalAt,
    this.arrivedCustomerAt,
    this.deliveredAt,
    this.deliveryFeeMinor,
  });

  final String id;
  final String orderId;
  final String publicReference;
  final String status;
  final String orderStatus;
  final String fulfillmentStatus;
  final String? assignedDriverId;
  final String? driverSearchStartedAt;
  final String? pickedUpAt;
  final String? estimatedArrivalAt;
  final String? arrivedCustomerAt;
  final String? deliveredAt;
  final String createdAt;
  final String updatedAt;
  final DeliveryPickup pickup;
  final DeliveryDropoff dropoff;
  final String? deliveryFeeMinor;
  final List<DeliveryEvent> events;

  bool get isTerminal => terminalDeliveryStatuses.contains(status);

  /// Compatibility shim for callers that only need status.
  CustomerDelivery get asSummary => CustomerDelivery(
    id: id,
    orderId: orderId,
    publicReference: publicReference,
    status: status,
  );

  factory CustomerDeliveryDetail.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    if (rawEvents is! List) {
      throw const OrderParseException('events must be a list');
    }
    return CustomerDeliveryDetail(
      id: orderReqString(json, 'id'),
      orderId: orderReqString(json, 'orderId'),
      publicReference: orderReqString(json, 'publicReference'),
      status: orderReqString(json, 'status'),
      orderStatus: orderReqString(json, 'orderStatus'),
      fulfillmentStatus: orderReqString(json, 'fulfillmentStatus'),
      assignedDriverId: json['assignedDriverId']?.toString(),
      driverSearchStartedAt: json['driverSearchStartedAt']?.toString(),
      pickedUpAt: json['pickedUpAt']?.toString(),
      estimatedArrivalAt: json['estimatedArrivalAt']?.toString(),
      arrivedCustomerAt: json['arrivedCustomerAt']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
      createdAt: orderReqString(json, 'createdAt'),
      updatedAt: orderReqString(json, 'updatedAt'),
      pickup: DeliveryPickup.fromJson(orderAsMap(json['pickup'], 'pickup')),
      dropoff: DeliveryDropoff.fromJson(orderAsMap(json['dropoff'], 'dropoff')),
      deliveryFeeMinor: json['deliveryFeeMinor']?.toString(),
      events: [
        for (final event in rawEvents)
          DeliveryEvent.fromJson(orderAsMap(event, 'event')),
      ],
    );
  }
}

enum OrderTrackingStage {
  awaitingMerchant,
  accepted,
  preparing,
  readyAwaitingDelivery,
  searchingDriver,
  driverAssigned,
  toPickup,
  atPickup,
  pickedUp,
  inTransit,
  arrivedCustomer,
  delivered,
  completed,
  cancelled,
  failed,
  unknown,
}

/// Derive UI stage from authoritative Order + optional Delivery.
/// Missing Delivery (DELIVERY_NOT_FOUND) is never treated as driver search.
OrderTrackingStage resolveOrderTrackingStage({
  required OrderDetail order,
  CustomerDeliveryDetail? delivery,
  bool deliveryNotFound = false,
}) {
  if (order.status == 'CANCELLED') {
    return OrderTrackingStage.cancelled;
  }
  if (order.status == 'FAILED') {
    return OrderTrackingStage.failed;
  }
  if (order.status == 'COMPLETED') {
    return OrderTrackingStage.completed;
  }

  if (delivery != null) {
    switch (delivery.status) {
      case 'CANCELLED':
        return OrderTrackingStage.cancelled;
      case 'FAILED':
        return OrderTrackingStage.failed;
      case 'DELIVERED':
        return OrderTrackingStage.delivered;
      case 'SEARCHING_DRIVER':
        return OrderTrackingStage.searchingDriver;
      case 'DRIVER_ASSIGNED':
        return OrderTrackingStage.driverAssigned;
      case 'TO_PICKUP':
        return OrderTrackingStage.toPickup;
      case 'AT_PICKUP':
        return OrderTrackingStage.atPickup;
      case 'PICKED_UP':
        return OrderTrackingStage.pickedUp;
      case 'IN_TRANSIT':
        return OrderTrackingStage.inTransit;
      case 'ARRIVED_CUSTOMER':
        return OrderTrackingStage.arrivedCustomer;
    }
  }

  if (order.awaitingMerchantAcceptance) {
    return OrderTrackingStage.awaitingMerchant;
  }
  switch (order.fulfillmentStatus) {
    case 'ACCEPTED':
      return OrderTrackingStage.accepted;
    case 'PREPARING':
      return OrderTrackingStage.preparing;
    case 'READY':
      // No Delivery yet is expected until Matching starts.
      if (deliveryNotFound || delivery == null) {
        return OrderTrackingStage.readyAwaitingDelivery;
      }
      return OrderTrackingStage.readyAwaitingDelivery;
  }

  if (order.status == 'CONFIRMED') {
    return OrderTrackingStage.accepted;
  }
  if (order.status == 'ACTIVE') {
    return OrderTrackingStage.preparing;
  }
  return OrderTrackingStage.unknown;
}

String orderTrackingStageTitle(OrderTrackingStage stage) {
  switch (stage) {
    case OrderTrackingStage.awaitingMerchant:
      return AppStrings.trackingAwaitingMerchantTitle;
    case OrderTrackingStage.accepted:
      return AppStrings.orderStatusAccepted;
    case OrderTrackingStage.preparing:
      return AppStrings.orderStatusPreparing;
    case OrderTrackingStage.readyAwaitingDelivery:
      return AppStrings.orderStatusReady;
    case OrderTrackingStage.searchingDriver:
      return AppStrings.orderStatusSearchingDriver;
    case OrderTrackingStage.driverAssigned:
      return AppStrings.orderStatusDriverAssigned;
    case OrderTrackingStage.toPickup:
      return AppStrings.orderStatusToPickup;
    case OrderTrackingStage.atPickup:
      return AppStrings.orderStatusAtPickup;
    case OrderTrackingStage.pickedUp:
      return AppStrings.orderStatusPickedUp;
    case OrderTrackingStage.inTransit:
      return AppStrings.orderStatusInTransit;
    case OrderTrackingStage.arrivedCustomer:
      return AppStrings.trackingNearbyTitle;
    case OrderTrackingStage.delivered:
    case OrderTrackingStage.completed:
      return AppStrings.trackingCompletedTitle;
    case OrderTrackingStage.cancelled:
      return AppStrings.orderStatusCancelled;
    case OrderTrackingStage.failed:
      return AppStrings.trackingFailedTitle;
    case OrderTrackingStage.unknown:
      return AppStrings.trackingUnknownTitle;
  }
}

String orderTrackingStageBody(OrderTrackingStage stage) {
  switch (stage) {
    case OrderTrackingStage.awaitingMerchant:
      return AppStrings.trackingAwaitingMerchantBody;
    case OrderTrackingStage.accepted:
      return AppStrings.trackingAcceptedBody;
    case OrderTrackingStage.preparing:
      return AppStrings.trackingPreparingBody;
    case OrderTrackingStage.readyAwaitingDelivery:
      return AppStrings.trackingReadyBody;
    case OrderTrackingStage.searchingDriver:
      return AppStrings.trackingSearchingBody;
    case OrderTrackingStage.driverAssigned:
    case OrderTrackingStage.toPickup:
    case OrderTrackingStage.atPickup:
      return AppStrings.trackingAssignedBody;
    case OrderTrackingStage.pickedUp:
    case OrderTrackingStage.inTransit:
      return AppStrings.trackingInTransitBody;
    case OrderTrackingStage.arrivedCustomer:
      return AppStrings.trackingNearbyBody;
    case OrderTrackingStage.delivered:
    case OrderTrackingStage.completed:
      return AppStrings.trackingCompletedBody;
    case OrderTrackingStage.cancelled:
      return AppStrings.trackingCancelledBody;
    case OrderTrackingStage.failed:
      return AppStrings.trackingFailedBody;
    case OrderTrackingStage.unknown:
      return AppStrings.trackingUnknownBody;
  }
}

bool orderTrackingStageIsTerminal(OrderTrackingStage stage) {
  switch (stage) {
    case OrderTrackingStage.delivered:
    case OrderTrackingStage.completed:
    case OrderTrackingStage.cancelled:
    case OrderTrackingStage.failed:
      return true;
    default:
      return false;
  }
}

bool shouldAcceptRecordedAt({
  required String? previousRecordedAt,
  required String incomingRecordedAt,
}) {
  if (previousRecordedAt == null) {
    return true;
  }
  final prevAt = DateTime.tryParse(previousRecordedAt)?.toUtc();
  final nextAt = DateTime.tryParse(incomingRecordedAt)?.toUtc();
  if (prevAt == null || nextAt == null) {
    return true;
  }
  return nextAt.isAfter(prevAt);
}

String trackingSnapshotStatusLabel(String status) {
  switch (status) {
    case 'LIVE':
      return AppStrings.trackingLive;
    case 'STALE':
      return AppStrings.trackingStale;
    case 'UNAVAILABLE':
      return AppStrings.trackingUnavailable;
    case 'NO_DRIVER':
      return AppStrings.trackingNoDriver;
    default:
      return status;
  }
}
