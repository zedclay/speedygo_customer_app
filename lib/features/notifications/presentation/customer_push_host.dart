import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/router/app_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/notifications/application/customer_push_controller.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_inbox_controller.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_navigation.dart';
import 'package:speedygo_customer_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';

/// Forwards session transitions to Push and consumes taps only after restore.
class CustomerPushHost extends ConsumerStatefulWidget {
  const CustomerPushHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CustomerPushHost> createState() => _CustomerPushHostState();
}

class _CustomerPushHostState extends ConsumerState<CustomerPushHost> {
  var _consumeScheduled = false;

  bool _navigationReady() {
    return ref.read(sessionControllerProvider).phase == SessionPhase.ready;
  }

  void _maybeConsumePushTap() {
    if (_consumeScheduled || !mounted) return;
    if (ref.read(customerPushControllerProvider).pendingOpen == null) return;
    if (!_navigationReady()) return;
    _consumeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeScheduled = false;
      if (!mounted || !_navigationReady()) return;
      final hint = ref
          .read(customerPushControllerProvider.notifier)
          .takePendingOpen();
      if (hint != null) unawaited(_openFromPush(hint));
    });
  }

  Future<void> _openFromPush(PushOrderHint hint) async {
    final dest = resolveNotificationDestinationFromParts(
      type: hint.type,
      sourceId: hint.orderId,
    );
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!dest.canOpen || dest.location == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.pushOrderInaccessible)),
      );
      return;
    }
    try {
      await ref.read(ordersApiProvider).getOrder(hint.orderId);
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.pushOrderInaccessible)),
      );
      return;
    }
    if (hint.notificationId != null && hint.notificationId!.isNotEmpty) {
      try {
        await ref
            .read(notificationsApiProvider)
            .markRead(hint.notificationId!);
      } catch (_) {}
    }
    ref.invalidate(orderDetailControllerProvider(hint.orderId));
    ref.read(appRouterProvider).push(dest.location!);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      customerPushControllerProvider,
      (_, _) => _maybeConsumePushTap(),
    );
    ref.listen(sessionControllerProvider, (prev, next) {
      ref
          .read(customerPushControllerProvider.notifier)
          .onSessionChanged(prev, next);
      _maybeConsumePushTap();
    });
    return widget.child;
  }
}
