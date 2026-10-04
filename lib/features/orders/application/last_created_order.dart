import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

class LastCreatedOrderController extends Notifier<OrderDetail?> {
  @override
  OrderDetail? build() {
    ref.watch(catalogScopeProvider);
    return null;
  }

  void set(OrderDetail? order) {
    state = order;
  }
}

final lastCreatedOrderProvider =
    NotifierProvider<LastCreatedOrderController, OrderDetail?>(
      LastCreatedOrderController.new,
    );
