import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

final orderDetailControllerProvider =
    FutureProvider.family<OrderDetail, String>((ref, orderId) async {
      ref.watch(catalogScopeProvider);
      return ref.read(ordersApiProvider).getOrder(orderId);
    });
