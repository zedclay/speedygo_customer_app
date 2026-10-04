import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/support/data/support_api.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

final supportApiProvider = Provider<SupportClient>((ref) {
  return SupportApi(ref.watch(authInfrastructureProvider).dio);
});

class SupportListState {
  const SupportListState({
    this.items = const [],
    this.total = 0,
    this.loading = true,
    this.loadingMore = false,
    this.errorMessage,
  });

  final List<SupportTicketSummary> items;
  final int total;
  final bool loading;
  final bool loadingMore;
  final String? errorMessage;

  bool get hasMore => items.length < total;

  SupportListState copyWith({
    List<SupportTicketSummary>? items,
    int? total,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SupportListState(
      items: items ?? this.items,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SupportListController extends Notifier<SupportListState> {
  static const _pageSize = 50;
  var _generation = 0;

  @override
  SupportListState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return const SupportListState();
  }

  Future<void> refresh() async {
    final generation = _generation;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await ref.read(supportApiProvider).listTickets(
            limit: _pageSize,
            offset: 0,
          );
      if (generation != _generation) {
        return;
      }
      state = SupportListState(
        items: page.items,
        total: page.total,
        loading: false,
      );
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = SupportListState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = const SupportListState(
        loading: false,
        errorMessage: AppStrings.supportListLoadError,
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
      final page = await ref.read(supportApiProvider).listTickets(
            limit: _pageSize,
            offset: state.items.length,
          );
      if (generation != _generation) {
        return;
      }
      state = SupportListState(
        items: [...state.items, ...page.items],
        total: page.total,
        loading: false,
        loadingMore: false,
      );
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
        errorMessage: AppStrings.supportListLoadError,
      );
    }
  }
}

final supportListControllerProvider =
    NotifierProvider<SupportListController, SupportListState>(
      SupportListController.new,
    );
