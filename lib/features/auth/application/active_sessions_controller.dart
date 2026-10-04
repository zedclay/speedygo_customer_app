import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/data/auth_api.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';

class ActiveSessionsState {
  const ActiveSessionsState({
    this.items = const [],
    this.loading = true,
    this.mutating = false,
    this.errorMessage,
    this.infoMessage,
  });

  final List<AuthSession> items;
  final bool loading;
  final bool mutating;
  final String? errorMessage;
  final String? infoMessage;

  List<AuthSession> get activeItems =>
      items.where((session) => !session.revoked).toList(growable: false);

  ActiveSessionsState copyWith({
    List<AuthSession>? items,
    bool? loading,
    bool? mutating,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return ActiveSessionsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      mutating: mutating ?? this.mutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

class ActiveSessionsController extends Notifier<ActiveSessionsState> {
  var _generation = 0;
  var _inFlight = false;

  @override
  ActiveSessionsState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _inFlight = false;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return const ActiveSessionsState();
  }

  Future<void> refresh({bool quiet = false}) async {
    final generation = _generation;
    if (!quiet || state.items.isEmpty) {
      state = state.copyWith(loading: true, clearError: true, clearInfo: true);
    } else {
      state = state.copyWith(clearError: true);
    }
    try {
      final rows = await ref.read(authApiProvider).listSessions();
      if (generation != _generation) {
        return;
      }
      state = ActiveSessionsState(
        items: rows,
        loading: false,
        infoMessage: quiet ? state.infoMessage : null,
      );
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
        errorMessage: AppStrings.securityLoadError,
      );
    }
  }

  /// Returns true when the current device must transition to signed-out.
  Future<bool> revokeSession(String sessionId) async {
    if (_inFlight) {
      return false;
    }
    AuthSession? target;
    for (final item in state.items) {
      if (item.id == sessionId) {
        target = item;
        break;
      }
    }
    if (target == null || target.revoked) {
      return false;
    }

    _inFlight = true;
    final generation = _generation;
    final wasCurrent = target.currentSession;
    state = state.copyWith(mutating: true, clearError: true, clearInfo: true);
    try {
      await ref.read(authApiProvider).revokeSession(sessionId);
      if (generation != _generation) {
        return false;
      }
      if (wasCurrent) {
        // Never reuse the revoked token — clear local session immediately.
        await ref
            .read(sessionControllerProvider.notifier)
            .invalidateLocalSession();
        return true;
      }
      await refresh(quiet: true);
      if (generation != _generation) {
        return false;
      }
      state = state.copyWith(
        mutating: false,
        infoMessage: AppStrings.securityRevokedOk,
      );
      return false;
    } on AppException catch (error) {
      if (generation != _generation) {
        return false;
      }
      if (isSessionMutationUncertain(error)) {
        await refresh(quiet: true);
        if (generation != _generation) {
          return false;
        }
        state = state.copyWith(
          mutating: false,
          errorMessage: AppStrings.securityRevokeUncertain,
        );
        return false;
      }
      state = state.copyWith(mutating: false, errorMessage: error.message);
      await refresh(quiet: true);
      return false;
    } catch (_) {
      if (generation != _generation) {
        return false;
      }
      state = state.copyWith(
        mutating: false,
        errorMessage: AppStrings.securityRevokeUncertain,
      );
      await refresh(quiet: true);
      return false;
    } finally {
      if (generation == _generation) {
        _inFlight = false;
        if (state.mutating) {
          state = state.copyWith(mutating: false);
        }
      }
    }
  }

  /// Revokes every session including the current one.
  Future<bool> logoutAll() async {
    if (_inFlight) {
      return false;
    }
    _inFlight = true;
    final generation = _generation;
    state = state.copyWith(mutating: true, clearError: true, clearInfo: true);
    try {
      await ref.read(authApiProvider).logoutAll();
      if (generation != _generation) {
        return false;
      }
      await ref
          .read(sessionControllerProvider.notifier)
          .invalidateLocalSession();
      return true;
    } on AppException catch (error) {
      if (generation != _generation) {
        return false;
      }
      if (isSessionMutationUncertain(error)) {
        state = state.copyWith(
          mutating: false,
          errorMessage: AppStrings.securityRevokeUncertain,
        );
        await refresh(quiet: true);
        // If list shows current revoked, still sign out locally.
        final currentGone = state.items.any(
          (s) => s.currentSession && s.revoked,
        );
        if (currentGone || state.activeItems.isEmpty) {
          await ref
              .read(sessionControllerProvider.notifier)
              .invalidateLocalSession();
          return true;
        }
        return false;
      }
      state = state.copyWith(mutating: false, errorMessage: error.message);
      return false;
    } catch (_) {
      if (generation != _generation) {
        return false;
      }
      state = state.copyWith(
        mutating: false,
        errorMessage: AppStrings.securityRevokeUncertain,
      );
      await refresh(quiet: true);
      return false;
    } finally {
      if (generation == _generation) {
        _inFlight = false;
        if (state.mutating) {
          state = state.copyWith(mutating: false);
        }
      }
    }
  }
}

final activeSessionsControllerProvider =
    NotifierProvider<ActiveSessionsController, ActiveSessionsState>(
      ActiveSessionsController.new,
    );
