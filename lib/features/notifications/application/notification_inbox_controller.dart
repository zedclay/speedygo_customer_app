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
    this.loadMoreError,
  });

  final List<NotificationItem> items;
  final int total;
  final int unreadCount;
  final bool loading;
  final bool loadingMore;
  final bool mutating;
  final String? errorMessage;
  final String? loadMoreError;

  bool get hasMore => items.length < total;

  NotificationInboxState copyWith({
    List<NotificationItem>? items,
    int? total,
    int? unreadCount,
    bool? loading,
    bool? loadingMore,
    bool? mutating,
    String? errorMessage,
    String? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      mutating: mutating ?? this.mutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
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
      state = state.copyWith(
        loading: true,
        clearError: true,
        clearLoadMoreError: true,
      );
    } else {
      state = state.copyWith(clearError: true, clearLoadMoreError: true);
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
        items: _uniqueById(page.items),
        total: page.total,
        unreadCount: page.unreadCount,
        loading: false,
      );
      _applyUnread(page.unreadCount);
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
    state = state.copyWith(
      loadingMore: true,
      clearLoadMoreError: true,
    );
    try {
      final page = await ref.read(notificationsApiProvider).list(
            limit: pageSize,
            offset: state.items.length,
          );
      if (generation != _generation) {
        return;
      }
      state = NotificationInboxState(
        items: _mergeUnique(state.items, page.items),
        total: page.total,
        unreadCount: page.unreadCount,
        loading: false,
        loadingMore: false,
      );
      _applyUnread(page.unreadCount);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: error.message,
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: AppStrings.notificationsLoadError,
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
    final previousItems = state.items;
    final previousUnread = state.unreadCount;
    final optimistic = [...previousItems];
    optimistic[index] = optimistic[index].copyWith(read: true);
    final optimisticUnread =
        previousUnread > 0 ? previousUnread - 1 : 0;
    state = state.copyWith(
      items: optimistic,
      unreadCount: optimisticUnread,
      mutating: true,
      clearError: true,
    );
    _applyUnread(optimisticUnread);

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
        await _reconcileAfterUncertain(
          generation,
          previousItems,
          previousUnread,
        );
        return;
      }
      _restoreSnapshot(
        previousItems,
        previousUnread,
        error.message,
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      _restoreSnapshot(
        previousItems,
        previousUnread,
        AppStrings.notificationsMarkReadError,
      );
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
    final previousItems = state.items;
    final previousUnread = state.unreadCount;
    state = state.copyWith(
      items: [
        for (final item in previousItems) item.copyWith(read: true),
      ],
      unreadCount: 0,
      mutating: true,
      clearError: true,
    );
    _applyUnread(0);
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
        await _reconcileAfterUncertain(
          generation,
          previousItems,
          previousUnread,
        );
        return;
      }
      _restoreSnapshot(
        previousItems,
        previousUnread,
        error.message,
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      _restoreSnapshot(
        previousItems,
        previousUnread,
        AppStrings.notificationsMarkReadError,
      );
    } finally {
      if (generation == _generation) {
        _markInFlight = false;
      }
    }
  }

  void _restoreSnapshot(
    List<NotificationItem> items,
    int unreadCount,
    String message,
  ) {
    state = state.copyWith(
      items: items,
      unreadCount: unreadCount,
      mutating: false,
      errorMessage: message,
    );
    _applyUnread(unreadCount);
  }

  Future<void> _reconcileAfterUncertain(
    int generation,
    List<NotificationItem> previousItems,
    int previousUnread,
  ) async {
    await refresh(quiet: true);
    if (generation != _generation) {
      return;
    }
    if (state.errorMessage != null) {
      _restoreSnapshot(
        previousItems,
        previousUnread,
        state.errorMessage!,
      );
      return;
    }
    state = state.copyWith(mutating: false);
  }

  Future<void> _reconcileUnread(int generation) async {
    try {
      final count =
          await ref.read(notificationsApiProvider).unreadCount();
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(unreadCount: count.unreadCount);
      _applyUnread(count.unreadCount);
    } catch (_) {
      // Keep list unreadCount; dedicated count is best-effort.
    }
  }

  void _applyUnread(int count) {
    if (!ref.mounted) {
      return;
    }
    ref.read(notificationUnreadCountProvider.notifier).apply(count);
  }
}

List<NotificationItem> _uniqueById(List<NotificationItem> items) {
  return _mergeUnique(const [], items);
}

List<NotificationItem> _mergeUnique(
  List<NotificationItem> current,
  List<NotificationItem> incoming,
) {
  final seen = {for (final item in current) item.id};
  final merged = [...current];
  for (final item in incoming) {
    if (seen.add(item.id)) {
      merged.add(item);
    }
  }
  return merged;
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
      state = response.unreadCount < 0 ? 0 : response.unreadCount;
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
