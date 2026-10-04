import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/orders/application/orders_list_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

/// Card lift from Stitch `historique_des_commandes_speedygo`.
const _kOrderCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class OrdersTabScreen extends ConsumerStatefulWidget {
  const OrdersTabScreen({super.key});

  @override
  ConsumerState<OrdersTabScreen> createState() => _OrdersTabScreenState();
}

class _OrdersTabScreenState extends ConsumerState<OrdersTabScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  OrdersListFilter get _filter {
    switch (_tabs.index) {
      case 1:
        return OrdersListFilter.completed;
      case 2:
        return OrdersListFilter.cancelled;
      default:
        return OrdersListFilter.inProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersListControllerProvider);
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          AppStrings.tabOrders,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceVariant.withValues(
                alpha: 0.6,
              ),
              labelStyle: labelStyle?.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: labelStyle,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: AppStrings.ordersTabInProgress),
                Tab(text: AppStrings.ordersTabCompleted),
                Tab(text: AppStrings.ordersTabCancelled),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(ordersListControllerProvider.notifier).refresh(),
        child: _body(context, orders),
      ),
    );
  }

  Widget _body(BuildContext context, OrdersListState orders) {
    if (orders.loading && orders.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.errorMessage != null && orders.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: CatalogStatusView(
              message: orders.errorMessage!,
              onRetry: () =>
                  ref.read(ordersListControllerProvider.notifier).refresh(),
            ),
          ),
        ],
      );
    }

    final visible = orders.filtered(_filter);
    if (orders.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: const CatalogStatusView(
              message: AppStrings.ordersEmpty,
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ],
      );
    }
    if (visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          const CatalogStatusView(
            message: AppStrings.ordersEmptyFiltered,
            icon: Icons.filter_list_off_outlined,
          ),
          if (orders.hasMore) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.ordersOlderHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            CatalogLoadMoreBar(
              hasMore: orders.hasMore,
              loadingMore: orders.loadingMore,
              loadMoreError: orders.loadMoreError,
              onLoadMore: () =>
                  ref.read(ordersListControllerProvider.notifier).loadMore(),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: visible.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == visible.length) {
          return CatalogLoadMoreBar(
            hasMore: orders.hasMore,
            loadingMore: orders.loadingMore,
            loadMoreError: orders.loadMoreError,
            onLoadMore: () =>
                ref.read(ordersListControllerProvider.notifier).loadMore(),
          );
        }
        final order = visible[index];
        return _OrderTile(
          key: Key('order-list-tile-${order.id}'),
          order: order,
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final status = _listStatusLabel(order);
    final badge = _statusBadgeColors(order);
    return Material(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(AppRoutes.order(order.id)),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
            ),
            boxShadow: const [_kOrderCardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        order.publicReference,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badge.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: badge.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    _formatOrderDate(order.createdAt),
                    order.paymentMethod == 'COD'
                        ? AppStrings.orderPaymentCod
                        : AppStrings.orderPaymentElectronic,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        MoneyFormat.dzd(order.financial.customerTotalMinor),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.outline.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _listStatusLabel(OrderSummary order) {
  if (order.isCancelled) {
    return AppStrings.orderStatusCancelled;
  }
  if (order.isCompleted) {
    return AppStrings.orderStatusCompleted;
  }
  return activeOrderStatusLabel(
    fulfillmentStatus: order.fulfillmentStatus,
    orderStatus: order.status,
  );
}

({Color background, Color foreground}) _statusBadgeColors(OrderSummary order) {
  if (order.isCancelled) {
    return (
      background: AppColors.error.withValues(alpha: 0.1),
      foreground: AppColors.error,
    );
  }
  if (order.isCompleted) {
    return (
      background: AppColors.tertiary.withValues(alpha: 0.1),
      foreground: AppColors.tertiary,
    );
  }
  return (
    background: AppColors.primaryContainer.withValues(alpha: 0.2),
    foreground: AppColors.primary,
  );
}

String _formatOrderDate(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) {
    return '';
  }
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}
