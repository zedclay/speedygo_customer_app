import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_active_order_card.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';

/// Shared active-order overlay. Shown only when an eligible order exists.
class DiscoveryOverlay extends ConsumerWidget {
  const DiscoveryOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrder = switch (ref.watch(activeOrderControllerProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return Stack(
      children: [
        child,
        if (activeOrder != null)
          Positioned(
            left: HomeLayout.margin,
            right: HomeLayout.margin,
            bottom: 16,
            child: HomeActiveOrderCard(
              publicReference: activeOrder.publicReference,
              statusLabel: activeOrder.statusLabel,
              onTap: () =>
                  context.push(AppRoutes.orderTracking(activeOrder.orderId)),
            ),
          ),
      ],
    );
  }
}

double discoveryListBottomPadding(WidgetRef ref) {
  final activeOrder = switch (ref.watch(activeOrderControllerProvider)) {
    AsyncData(:final value) => value,
    _ => null,
  };
  return activeOrder == null
      ? HomeLayout.listBottomGap
      : HomeLayout.listBottomGapWithOrder;
}
