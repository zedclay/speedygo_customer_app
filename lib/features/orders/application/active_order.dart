import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/data/order_api.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';

final ordersApiProvider = Provider<OrdersClient>((ref) {
  return OrdersApi(ref.watch(authInfrastructureProvider).dio);
});

class ActiveOrderController extends AsyncNotifier<ActiveOrderSnapshot?> {
  @override
  Future<ActiveOrderSnapshot?> build() {
    ref.watch(catalogScopeProvider);
    return _load();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<ActiveOrderSnapshot?> _load() async {
    try {
      final page = await ref.read(ordersApiProvider).listOrders();
      OrderSummary? match;
      for (final order in page.items) {
        if (order.isOpen) {
          match = order;
          break;
        }
      }
      if (match == null) {
        return null;
      }
      CustomerDeliveryDetail? delivery;
      try {
        delivery = await ref.read(ordersApiProvider).getDelivery(match.id);
      } catch (_) {
        delivery = null;
      }
      if (!isEligibleActiveOrder(
        status: match.status,
        deliveryStatus: delivery?.status,
      )) {
        return null;
      }
      return ActiveOrderSnapshot(
        orderId: match.id,
        publicReference: match.publicReference,
        statusLabel: activeOrderStatusLabel(
          fulfillmentStatus: match.fulfillmentStatus,
          deliveryStatus: delivery?.status,
          orderStatus: match.status,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

final activeOrderControllerProvider =
    AsyncNotifierProvider<ActiveOrderController, ActiveOrderSnapshot?>(
      ActiveOrderController.new,
    );
