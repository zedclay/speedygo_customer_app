import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/orders/application/order_tracking_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';

/// Soft lift from Stitch tracking artboards (`suivi_de_commande_speedygo`, etc.).
const _kTrackingCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.focus = OrderTrackingFocus.overview,
  });

  final String orderId;
  final OrderTrackingFocus focus;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orderTrackingControllerProvider(widget.orderId).notifier)
          .setFocus(widget.focus);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(
      orderTrackingControllerProvider(widget.orderId).notifier,
    );
    if (state == AppLifecycleState.resumed) {
      notifier.onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      notifier.onAppBackgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(orderTrackingControllerProvider(widget.orderId));
    final title = switch (tracking.focus) {
      OrderTrackingFocus.statusDetails => AppStrings.trackingStatusDetailsTitle,
      OrderTrackingFocus.map => AppStrings.trackingTitle,
      OrderTrackingFocus.nearby => AppStrings.trackingNearbyTitle,
      OrderTrackingFocus.completed => AppStrings.trackingCompletedTitle,
      OrderTrackingFocus.overview => AppStrings.trackingTitle,
    };

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.supportReportProblem,
            onPressed: () => context.push(
              '${AppRoutes.supportNew}?orderId=${Uri.encodeQueryComponent(widget.orderId)}',
            ),
            icon: const Icon(Icons.support_agent, color: AppColors.primary),
          ),
          IconButton(
            tooltip: AppStrings.trackingRefresh,
            onPressed: tracking.refreshing
                ? null
                : () => ref
                      .read(
                        orderTrackingControllerProvider(widget.orderId).notifier,
                      )
                      .refresh(),
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: tracking.loading && tracking.order == null
          ? const Center(child: CircularProgressIndicator())
          : tracking.order == null
          ? _errorBody(tracking.errorMessage ?? AppStrings.trackingLoadError)
          : _content(context, tracking),
      bottomNavigationBar: tracking.order == null
          ? null
          : _StickyActions(order: tracking.order!),
    );
  }

  Widget _errorBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(
                    orderTrackingControllerProvider(widget.orderId).notifier,
                  )
                  .refresh(),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, OrderTrackingState tracking) {
    final order = tracking.order!;
    final stage = tracking.stage;
    return RefreshIndicator(
      onRefresh: () => ref
          .read(orderTrackingControllerProvider(widget.orderId).notifier)
          .refresh(),
      child: ListView(
        key: const Key('tracking-overview-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
        children: [
          if (tracking.offline || tracking.errorMessage != null) ...[
            _banner(
              tracking.errorMessage ?? AppStrings.trackingOffline,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
          ],
          _hero(context, stage),
          const SizedBox(height: 16),
          _orderSummary(context, order),
          const SizedBox(height: 16),
          _timeline(context, stage),
          if (tracking.focus == OrderTrackingFocus.statusDetails) ...[
            const SizedBox(height: 16),
            _statusDetails(context, tracking),
          ],
          if (tracking.focus == OrderTrackingFocus.map ||
              tracking.tracking?.location != null) ...[
            const SizedBox(height: 16),
            _locationPanel(context, tracking),
          ],
          if (tracking.delivery != null) ...[
            const SizedBox(height: 16),
            _addresses(context, tracking.delivery!),
          ],
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, OrderTrackingStage stage) {
    final icon = switch (stage) {
      OrderTrackingStage.awaitingMerchant => Icons.storefront,
      OrderTrackingStage.searchingDriver => Icons.local_shipping,
      OrderTrackingStage.arrivedCustomer => Icons.near_me,
      OrderTrackingStage.delivered ||
      OrderTrackingStage.completed => Icons.check_circle,
      OrderTrackingStage.cancelled ||
      OrderTrackingStage.failed => Icons.cancel,
      OrderTrackingStage.unknown => Icons.help_outline,
      OrderTrackingStage.preparing ||
      OrderTrackingStage.accepted ||
      OrderTrackingStage.readyAwaitingDelivery => Icons.restaurant,
      _ => Icons.delivery_dining,
    };
    final emphasize = !orderTrackingStageIsTerminal(stage) &&
        stage != OrderTrackingStage.unknown;
    final searching = stage == OrderTrackingStage.searchingDriver;
    final done = stage == OrderTrackingStage.delivered ||
        stage == OrderTrackingStage.completed;
    final failed = stage == OrderTrackingStage.cancelled ||
        stage == OrderTrackingStage.failed;

    final iconColor = failed
        ? AppColors.error
        : done
        ? AppColors.tertiary
        : emphasize
        ? AppColors.primary
        : AppColors.outline;
    final iconBg = failed
        ? AppColors.error.withValues(alpha: 0.12)
        : done
        ? AppColors.tertiaryFixed
        : AppColors.primary.withValues(alpha: 0.1);

    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (searching) ...[
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Container(
                    width: searching ? 56 : 72,
                    height: searching ? 56 : 72,
                    decoration: BoxDecoration(
                      color: searching ? AppColors.primary : iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: searching ? 28 : 36,
                      color: searching ? AppColors.onPrimary : iconColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              orderTrackingStageTitle(stage),
              key: const Key('tracking-stage-title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              orderTrackingStageBody(stage),
              key: const Key('tracking-stage-body'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderSummary(BuildContext context, OrderDetail order) {
    final paymentLabel = order.paymentMethod == 'COD'
        ? AppStrings.orderPaymentCod
        : AppStrings.orderPaymentElectronic;
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.trackingOrderStatusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '#${order.publicReference}',
                    key: const Key('tracking-reference'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MoneyFormat.dzd(order.financial.customerTotalMinor),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  paymentLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(BuildContext context, OrderTrackingStage stage) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: AppStrings.trackingTimelineSent,
        done: true,
        current: stage == OrderTrackingStage.awaitingMerchant,
        icon: Icons.send,
      ),
      _TimelineStep(
        label: AppStrings.trackingTimelineMerchant,
        done: _pastMerchant(stage),
        current: stage == OrderTrackingStage.awaitingMerchant ||
            stage == OrderTrackingStage.accepted,
        icon: Icons.storefront,
      ),
      _TimelineStep(
        label: AppStrings.trackingTimelinePrep,
        done: _pastPrep(stage),
        current: stage == OrderTrackingStage.preparing ||
            stage == OrderTrackingStage.readyAwaitingDelivery,
        icon: Icons.restaurant,
      ),
      _TimelineStep(
        label: AppStrings.trackingTimelineDelivery,
        done: _pastDelivery(stage),
        current: _inDelivery(stage),
        icon: Icons.delivery_dining,
      ),
      _TimelineStep(
        label: AppStrings.trackingTimelineDone,
        done: stage == OrderTrackingStage.delivered ||
            stage == OrderTrackingStage.completed,
        current: stage == OrderTrackingStage.delivered ||
            stage == OrderTrackingStage.completed,
        icon: Icons.home_outlined,
      ),
    ];

    if (stage == OrderTrackingStage.cancelled ||
        stage == OrderTrackingStage.failed ||
        stage == OrderTrackingStage.unknown) {
      return DecoratedBox(
        key: const Key('tracking-timeline'),
        decoration: _cardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            orderTrackingStageTitle(stage),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      key: const Key('tracking-timeline'),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.trackingProgression,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < steps.length; i++)
              _VerticalTimelineRow(
                key: Key('tracking-timeline-step-$i'),
                step: steps[i],
                isLast: i == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  bool _pastMerchant(OrderTrackingStage stage) =>
      stage != OrderTrackingStage.awaitingMerchant;

  bool _pastPrep(OrderTrackingStage stage) =>
      _pastMerchant(stage) &&
      stage != OrderTrackingStage.accepted &&
      stage != OrderTrackingStage.preparing;

  bool _pastDelivery(OrderTrackingStage stage) =>
      stage == OrderTrackingStage.delivered ||
      stage == OrderTrackingStage.completed;

  bool _inDelivery(OrderTrackingStage stage) {
    switch (stage) {
      case OrderTrackingStage.searchingDriver:
      case OrderTrackingStage.driverAssigned:
      case OrderTrackingStage.toPickup:
      case OrderTrackingStage.atPickup:
      case OrderTrackingStage.pickedUp:
      case OrderTrackingStage.inTransit:
      case OrderTrackingStage.arrivedCustomer:
        return true;
      default:
        return false;
    }
  }

  Widget _statusDetails(BuildContext context, OrderTrackingState tracking) {
    final order = tracking.order!;
    final delivery = tracking.delivery;
    return DecoratedBox(
      key: const Key('tracking-status-details'),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.trackingStatusDetailsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _kv(AppStrings.trackingOrderStatusLabel, order.status),
            _kv(AppStrings.trackingFulfillmentLabel, order.fulfillmentStatus),
            if (delivery != null)
              _kv(AppStrings.trackingDeliveryStatusLabel, delivery.status)
            else if (tracking.deliveryNotFound)
              _kv(
                AppStrings.trackingDeliveryStatusLabel,
                'DELIVERY_NOT_FOUND',
              ),
          ],
        ),
      ),
    );
  }

  Widget _locationPanel(BuildContext context, OrderTrackingState tracking) {
    final snapshot = tracking.tracking;
    final location = snapshot?.location;
    return DecoratedBox(
      key: const Key('tracking-location-panel'),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.trackingLocationLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.trackingMapUnavailable,
              key: const Key('tracking-map-unavailable'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.trackingNoCustomerGps,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (snapshot != null) ...[
              const SizedBox(height: 12),
              Text(
                trackingSnapshotStatusLabel(snapshot.status),
                key: const Key('tracking-snapshot-status'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (snapshot.isStale || snapshot.status == 'STALE')
                Text(
                  AppStrings.trackingStaleHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              if (snapshot.assignedDriverId != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.trackingDriverIdLabel} · ${snapshot.assignedDriverId}',
                  key: const Key('tracking-driver-id'),
                ),
              ],
            ],
            if (location != null) ...[
              const SizedBox(height: 8),
              Text(
                '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                key: const Key('tracking-coordinates'),
              ),
              Text(
                '${AppStrings.trackingRecordedAtLabel} · ${location.recordedAt}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addresses(BuildContext context, CustomerDeliveryDetail delivery) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.trackingPickupLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(delivery.pickup.name),
            Text(
              delivery.pickup.addressText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.trackingDropoffLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              delivery.dropoff.addressText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _banner(String text, {required Color color}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.3),
      ),
      boxShadow: const [_kTrackingCardShadow],
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.done,
    required this.current,
    required this.icon,
  });

  final String label;
  final bool done;
  final bool current;
  final IconData icon;
}

class _VerticalTimelineRow extends StatelessWidget {
  const _VerticalTimelineRow({
    super.key,
    required this.step,
    required this.isLast,
  });

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color nodeColor;
    final Color iconColor;
    final IconData glyph;
    if (step.done && !step.current) {
      nodeColor = AppColors.brandGreen;
      iconColor = AppColors.onSurface;
      glyph = Icons.check;
    } else if (step.current) {
      nodeColor = AppColors.primary;
      iconColor = AppColors.onPrimary;
      glyph = step.icon;
    } else {
      nodeColor = AppColors.outlineVariant;
      iconColor = AppColors.surfaceContainerLowest;
      glyph = step.icon;
    }

    final labelColor = step.current
        ? AppColors.primary
        : step.done
        ? AppColors.onSurface
        : AppColors.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceContainerLowest,
                      width: 3,
                    ),
                  ),
                  child: Icon(glyph, size: 16, color: iconColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: step.done
                          ? AppColors.brandGreen
                          : AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 24, top: 4),
              child: Text(
                step.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: labelColor,
                  fontWeight: step.current ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('tracking-sticky-actions'),
      color: AppColors.surface.withValues(alpha: 0.94),
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: const Key('tracking-open-detail'),
                onPressed: () => context.push(AppRoutes.order(order.id)),
                child: const Text(AppStrings.trackingOpenDetail),
              ),
              if (order.canCustomerCancel) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.orderCancel(order.id)),
                  child: Text(
                    AppStrings.orderCancelEntry,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
