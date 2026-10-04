import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_api.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';

final notificationsApiProvider = Provider<NotificationsClient>((ref) {
  return NotificationsApi(ref.watch(authInfrastructureProvider).dio);
});

class NotificationInboxState {
  const NotificationInboxState({
    this.items = const [],
    this.total = 0,
    this.unreadCount = 0,
    this.loading = true,
    this.loadingMore = false,
    this.mutating = false,
    this.errorMessage,
  });

  final List<NotificationItem> items;
  final int total;
  final int unreadCount;
  final bool loading;
  final bool loadingMore;
  final bool mutating;
  final String? errorMessage;

  bool get hasMore => items.length < total;

  NotificationInboxState copyWith({
    List<NotificationItem>? items,
    int? total,
    int? unreadCount,
    bool? loading,
    bool? loadingMore,
    bool? mutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      mutating: mutating ?? this.mutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationInboxController extends Notifier<NotificationInboxState> {
  static const pageSize = 20;
  var _generation = 0;
  var _markInFlight = false;

  @override
  NotificationInboxState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _markInFlight = false;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return const NotificationInboxState();
  }

  Future<void> refresh({bool quiet = false}) async {
    final generation = _generation;
    if (!quiet || state.items.isEmpty) {
      state = state.copyWith(loading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }
    try {
      final page = await ref.read(notificationsApiProvider).list(
            limit: pageSize,
            offset: 0,
          );
      if (generation != _generation) {
        return;
      }
      state = NotificationInboxState(
        items: page.items,
        total: page.total,
        unreadCount: page.unreadCount,
        loading: false,
      );
      if (ref.mounted) {
        ref
            .read(notificationUnreadCountProvider.notifier)
            .apply(page.unreadCount);
      }
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message,
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: AppStrings.notificationsLoadError,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await ref.read(notificationsApiProvider).list(
            limit: pageSize,
            offset: state.items.length,
          );
      if (generation != _generation) {
        return;
      }
      state = NotificationInboxState(
        items: [...state.items, ...page.items],
        total: page.total,
        unreadCount: page.unreadCount,
        loading: false,
        loadingMore: false,
      );
      if (ref.mounted) {
        ref
            .read(notificationUnreadCountProvider.notifier)
            .apply(page.unreadCount);
      }
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        errorMessage: error.message,
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        errorMessage: AppStrings.notificationsLoadError,
      );
    }
  }

  Future<void> markRead(String notificationId) async {
    if (_markInFlight) {
      return;
    }
    final index = state.items.indexWhere((item) => item.id == notificationId);
    if (index < 0) {
      return;
    }
    if (state.items[index].read) {
      return;
    }

    _markInFlight = true;
    final generation = _generation;
    final optimistic = [...state.items];
    optimistic[index] = optimistic[index].copyWith(read: true);
    final optimisticUnread =
        state.unreadCount > 0 ? state.unreadCount - 1 : 0;
    state = state.copyWith(
      items: optimistic,
      unreadCount: optimisticUnread,
      mutating: true,
      clearError: true,
    );
    if (ref.mounted) {
      ref.read(notificationUnreadCountProvider.notifier).apply(optimisticUnread);
    }

    try {
      final updated =
          await ref.read(notificationsApiProvider).markRead(notificationId);
      if (generation != _generation) {
        return;
      }
      final next = [...state.items];
      final i = next.indexWhere((item) => item.id == notificationId);
      if (i >= 0) {
        next[i] = updated;
      }
      state = state.copyWith(items: next, mutating: false);
      await _reconcileUnread(generation);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      if (isNotificationMutationUncertain(error)) {
        await _reconcileAfterUncertain(generation);
        return;
      }
      state = state.copyWith(
        mutating: false,
        errorMessage: error.message,
      );
      await refresh(quiet: true);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        mutating: false,
        errorMessage: AppStrings.notificationsMarkReadError,
      );
      await refresh(quiet: true);
    } finally {
      if (generation == _generation) {
        _markInFlight = false;
      }
    }
  }

  Future<void> markAllRead() async {
    if (_markInFlight || state.unreadCount <= 0) {
      return;
    }
    _markInFlight = true;
    final generation = _generation;
    final previous = state.items;
    state = state.copyWith(
      items: [
        for (final item in previous) item.copyWith(read: true),
      ],
      unreadCount: 0,
      mutating: true,
      clearError: true,
    );
    if (ref.mounted) {
      ref.read(notificationUnreadCountProvider.notifier).apply(0);
    }
    try {
      await ref.read(notificationsApiProvider).markAllRead();
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(mutating: false);
      await _reconcileUnread(generation);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      if (isNotificationMutationUncertain(error)) {
        await _reconcileAfterUncertain(generation);
        return;
      }
      state = state.copyWith(
        mutating: false,
        errorMessage: error.message,
      );
      await refresh(quiet: true);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        mutating: false,
        errorMessage: AppStrings.notificationsMarkReadError,
      );
      await refresh(quiet: true);
    } finally {
      if (generation == _generation) {
        _markInFlight = false;
      }
    }
  }

  Future<void> _reconcileAfterUncertain(int generation) async {
    await refresh(quiet: true);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(mutating: false, clearError: true);
  }

  Future<void> _reconcileUnread(int generation) async {
    try {
      final count =
          await ref.read(notificationsApiProvider).unreadCount();
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(unreadCount: count.unreadCount);
      if (ref.mounted) {
        ref
            .read(notificationUnreadCountProvider.notifier)
            .apply(count.unreadCount);
      }
    } catch (_) {
      // Keep list unreadCount; dedicated count is best-effort.
    }
  }
}

final notificationInboxControllerProvider =
    NotifierProvider<NotificationInboxController, NotificationInboxState>(
      NotificationInboxController.new,
    );

/// Account-wide unread count from `GET /notifications/unread-count`
/// (not derived from the first inbox page alone).
class NotificationUnreadCountController extends Notifier<int?> {
  var _generation = 0;

  @override
  int? build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return null;
  }

  void apply(int count) {
    state = count < 0 ? 0 : count;
  }

  Future<void> refresh() async {
    final generation = _generation;
    try {
      final response =
          await ref.read(notificationsApiProvider).unreadCount();
      if (generation != _generation) {
        return;
      }
      state = response.unreadCount;
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      // Leave prior value; do not invent a page-derived count.
    }
  }
}

final notificationUnreadCountProvider =
    NotifierProvider<NotificationUnreadCountController, int?>(
      NotificationUnreadCountController.new,
    );
