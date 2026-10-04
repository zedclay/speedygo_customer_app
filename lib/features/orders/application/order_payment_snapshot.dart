import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';

/// Read-only payment snapshot for confirmation / detail chrome.
///
/// Does not initiate checkout. Missing or failed GET → null (treat as
/// unconfirmed for ELECTRONIC display). Gate-off must not rewrite a
/// server SUCCEEDED into pending.
final orderPaymentSnapshotProvider =
    FutureProvider.autoDispose.family<CustomerPayment?, String>((
      ref,
      orderId,
    ) async {
      try {
        return await ref.read(ordersApiProvider).getPayment(orderId);
      } catch (_) {
        return null;
      }
    });
