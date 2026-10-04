import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';

/// Explicit internal destinations only — never execute payload routes/URLs.
enum NotificationDestinationKind {
  none,
  orderDetail,
  orderTracking,
  ordersList,
}

class NotificationDestination {
  const NotificationDestination.open(this.location)
    : kind = NotificationDestinationKind.orderDetail,
      unavailableReason = null;

  const NotificationDestination.tracking(this.location)
    : kind = NotificationDestinationKind.orderTracking,
      unavailableReason = null;

  const NotificationDestination.orders()
    : kind = NotificationDestinationKind.ordersList,
      location = AppRoutes.orders,
      unavailableReason = null;

  const NotificationDestination.unavailable(this.unavailableReason)
    : kind = NotificationDestinationKind.none,
      location = null;

  final NotificationDestinationKind kind;
  final String? location;
  final String? unavailableReason;

  bool get canOpen => location != null && location!.isNotEmpty;
}

/// Order-sourced types whose `sourceId` is an Order id (backend emit matrix).
const _orderSourceTypes = <String>{
  'ORDER_ACCEPTED',
  'ORDER_REJECTED',
  'ORDER_CANCELLED',
  'ORDER_READY',
  'DRIVER_ASSIGNED',
  'DELIVERY_COMPLETED',
};

const _trackingPreferredTypes = <String>{
  'ORDER_ACCEPTED',
  'ORDER_READY',
  'DRIVER_ASSIGNED',
  'DELIVERY_COMPLETED',
};

/// Types that exist in the contract but have no Customer destination here
/// (wrong actor, or sourceId is not an Order id).
const _noCustomerDestinationTypes = <String>{
  'MATCH_OFFER',
  'PAYMENT_SUCCEEDED',
  'REFUND_REFUNDED',
  'SETTLEMENT_FINALIZED',
  'DRIVER_EARNING_CREATED',
  'MERCHANT_ORDER_CREATED',
};

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isPlausibleSourceId(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty) {
    return false;
  }
  // Reject obvious injection / path payloads.
  if (sourceId.contains('/') ||
      sourceId.contains('\\') ||
      sourceId.contains('://') ||
      sourceId.contains('?') ||
      sourceId.contains('#')) {
    return false;
  }
  return _uuidPattern.hasMatch(sourceId);
}

NotificationDestination resolveNotificationDestination(
  NotificationItem item,
) {
  final type = item.type.trim();
  final sourceId = item.sourceId.trim();

  if (type.isEmpty) {
    return const NotificationDestination.unavailable('unknown_type');
  }

  if (_noCustomerDestinationTypes.contains(type)) {
    return const NotificationDestination.unavailable('no_destination');
  }

  if (_orderSourceTypes.contains(type)) {
    if (!isPlausibleSourceId(sourceId)) {
      return const NotificationDestination.unavailable('malformed_source');
    }
    if (_trackingPreferredTypes.contains(type)) {
      return NotificationDestination.tracking(
        AppRoutes.orderTracking(sourceId),
      );
    }
    return NotificationDestination.open(AppRoutes.order(sourceId));
  }

  return const NotificationDestination.unavailable('unknown_type');
}
