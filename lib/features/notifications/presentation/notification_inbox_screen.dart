import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_copy.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_inbox_controller.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_navigation.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';
import 'package:speedygo_customer_app/features/notifications/presentation/notification_copy_text.dart';

/// Inbox list chrome aligned to SpeedyGo tokens / card language from
/// `notifications_speedygo` preview cards — not the OS-permission artboard
/// (`/alerts/permission`, `/account/notifications`).
const _kNotifCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);
const _kPrimaryFixed = Color(0xFFD9E2FF);

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref
          .read(notificationInboxControllerProvider.notifier)
          .refresh(quiet: true);
      ref.read(notificationUnreadCountProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationInboxControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: false,
        title: Text(
          AppStrings.notificationsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              key: const Key('notifications-mark-all'),
              onPressed: state.mutating
                  ? null
                  : () => ref
                      .read(notificationInboxControllerProvider.notifier)
                      .markAllRead(),
              child: Text(
                AppStrings.notificationsMarkAll,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notificationInboxControllerProvider.notifier)
              .refresh();
          await ref.read(notificationUnreadCountProvider.notifier).refresh();
        },
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, NotificationInboxState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('notifications-loading')),
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            state.errorMessage!,
            key: const Key('notifications-error'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('notifications-retry'),
            onPressed: () => ref
                .read(notificationInboxControllerProvider.notifier)
                .refresh(),
            child: Text(AppStrings.retry),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 56,
            color: AppColors.outline.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.notificationsEmpty,
            key: const Key('notifications-empty'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.notificationsEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _EmptyLinkTile(
            icon: Icons.notifications_active_outlined,
            title: AppStrings.notificationsPermissionLink,
            onTap: () => context.push(AppRoutes.alertsPermission),
          ),
          const SizedBox(height: 8),
          _EmptyLinkTile(
            icon: Icons.tune_outlined,
            title: AppStrings.notificationsPrefsLink,
            subtitle: AppStrings.notificationPrefsUnavailable,
            onTap: () => context.push(AppRoutes.accountNotifications),
          ),
        ],
      );
    }

    final showBanner = state.errorMessage != null;
    final showFooter = state.hasMore || state.loadMoreError != null;
    final header = showBanner ? 1 : 0;
    final extra = showFooter ? 1 : 0;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: header + state.items.length + extra,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (showBanner && index == 0) {
          return _InboxErrorBanner(
            message: state.errorMessage!,
            onRetry: () => ref
                .read(notificationInboxControllerProvider.notifier)
                .refresh(),
          );
        }
        final itemIndex = index - header;
        if (itemIndex >= state.items.length) {
          if (state.loadMoreError != null) {
            return _InboxErrorBanner(
              message: state.loadMoreError!,
              pagination: true,
              onRetry: state.loadingMore
                  ? null
                  : () => ref
                      .read(notificationInboxControllerProvider.notifier)
                      .loadMore(),
            );
          }
          return TextButton(
            key: const Key('notifications-load-more'),
            onPressed: state.loadingMore
                ? null
                : () => ref
                    .read(notificationInboxControllerProvider.notifier)
                    .loadMore(),
            child: Text(
              state.loadingMore
                  ? AppStrings.notificationsLoadingMore
                  : AppStrings.notificationsLoadMore,
            ),
          );
        }
        final item = state.items[itemIndex];
        return _NotificationTile(
          item: item,
          busy: state.mutating,
          onOpen: () => _openItem(context, item),
        );
      },
    );
  }

  Future<void> _openItem(BuildContext context, NotificationItem item) async {
    final destination = resolveNotificationDestination(item);
    if (!item.read) {
      await ref
          .read(notificationInboxControllerProvider.notifier)
          .markRead(item.id);
    }
    if (!context.mounted) {
      return;
    }
    if (!destination.canOpen) {
      final message = destination.unavailableReason == 'unknown_type'
          ? AppStrings.notificationsUnknownType
          : AppStrings.notificationsDestinationUnavailable;
      SgSnack.warning(context, message: message);
      return;
    }
    context.push(destination.location!);
  }
}

class _InboxErrorBanner extends StatelessWidget {
  const _InboxErrorBanner({
    required this.message,
    required this.onRetry,
    this.pagination = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool pagination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          key: pagination
              ? const Key('notifications-pagination-error')
              : const Key('notifications-error'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: pagination
              ? const Key('notifications-pagination-retry')
              : const Key('notifications-retry'),
          onPressed: onRetry,
          child: Text(AppStrings.retry),
        ),
      ],
    );
  }
}

class _EmptyLinkTile extends StatelessWidget {
  const _EmptyLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onOpen,
    this.busy = false,
  });

  final NotificationItem item;
  final VoidCallback onOpen;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final unread = !item.read;
    final icon = _iconForType(item.type);
    final copy = resolveSystemNotificationCopy(
      type: item.type,
      storedTitle: item.title,
      storedBody: item.body,
    );
    return Material(
      key: Key('notification-tile-${item.id}'),
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: unread
              ? AppColors.primaryContainer.withValues(alpha: 0.45)
              : AppColors.outlineVariant.withValues(alpha: 0.6),
          width: unread ? 1.5 : 1,
        ),
      ),
      shadowColor: const Color(0x0A000000),
      child: InkWell(
        onTap: busy ? null : onOpen,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [_kNotifCardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: unread
                        ? _kPrimaryFixed
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: unread ? AppColors.primary : AppColors.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppStrings.notificationsBrand,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              key: Key('notification-unread-${item.id}'),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            formatNotificationTimestamp(item.createdAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      NotificationCopyText(
                        copy: copy,
                        isTitle: true,
                        maxLines: 3,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      NotificationCopyText(
                        copy: copy,
                        maxLines: 8,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight:
                              unread ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'ORDER_ACCEPTED':
    case 'ORDER_PREPARING':
    case 'ORDER_READY':
      return Icons.restaurant;
    case 'ORDER_OUT_FOR_DELIVERY':
    case 'DRIVER_ASSIGNED':
    case 'DRIVER_NEARBY':
      return Icons.pedal_bike;
    case 'ORDER_DELIVERED':
    case 'ORDER_COMPLETED':
      return Icons.check_circle_outline;
    case 'ORDER_CANCELLED':
      return Icons.cancel_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

String formatNotificationTimestamp(String iso, {DateTime? now}) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) {
    return '';
  }
  final diff = (now ?? DateTime.now()).difference(parsed);
  if (diff.inMinutes < 1) {
    return AppStrings.notificationsJustNow;
  }
  if (diff.inHours < 1) {
    return AppStrings.notificationsMinutesAgo(diff.inMinutes);
  }
  if (diff.inDays < 1) {
    return AppStrings.notificationsHoursAgo(diff.inHours);
  }
  if (diff.inDays < 7) {
    return AppStrings.notificationsDaysAgo(diff.inDays);
  }
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}
