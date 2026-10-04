import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_api.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

final ratingsApiProvider = Provider<RatingsClient>((ref) {
  return RatingsApi(ref.watch(authInfrastructureProvider).dio);
});

class MerchantRatingsController extends Notifier<Map<String, RatingSummary>> {
  final _inflight = <String>{};

  @override
  Map<String, RatingSummary> build() {
    ref.watch(catalogScopeProvider);
    _inflight.clear();
    ref.listen(storefrontListControllerProvider, (previous, next) {
      if (!ref.mounted) {
        return;
      }
      unawaited(ensure(next.items.map((item) => item.merchantId)));
    });
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      final items = ref.read(storefrontListControllerProvider).items;
      unawaited(ensure(items.map((item) => item.merchantId)));
    });
    return {};
  }

  Future<void> refresh() async {
    _inflight.clear();
    state = {};
    final items = ref.read(storefrontListControllerProvider).items;
    await ensure(items.map((item) => item.merchantId));
  }

  Future<void> invalidateMerchant(String merchantId) async {
    if (merchantId.isEmpty || !ref.mounted) {
      return;
    }
    final next = Map<String, RatingSummary>.from(state)..remove(merchantId);
    state = next;
    _inflight.remove(merchantId);
    await ensure([merchantId]);
  }

  void putSummary(RatingSummary summary) {
    if (!ref.mounted || summary.targetId.isEmpty) {
      return;
    }
    state = {...state, summary.targetId: summary};
  }

  Future<void> ensure(Iterable<String> merchantIds) async {
    final missing = <String>{};
    for (final id in merchantIds) {
      if (id.isEmpty || state.containsKey(id) || _inflight.contains(id)) {
        continue;
      }
      missing.add(id);
    }
    if (missing.isEmpty) {
      return;
    }
    _inflight.addAll(missing);
    final api = ref.read(ratingsApiProvider);
    final fetched = <String, RatingSummary>{};
    try {
      for (final summary in await api.merchantSummaries(missing.toList())) {
        fetched[summary.targetId] = summary;
      }
    } catch (_) {
      // Fall back to per-merchant reads only when the batch contract fails.
      await Future.wait(
        missing.map((id) async {
          try {
            fetched[id] = await api.merchantSummary(id);
          } catch (_) {
            fetched[id] = RatingSummary(
              targetType: 'MERCHANT',
              targetId: id,
              count: 0,
            );
          }
        }),
      );
    }
    for (final id in missing) {
      fetched.putIfAbsent(
        id,
        () => RatingSummary(targetType: 'MERCHANT', targetId: id, count: 0),
      );
    }
    if (!ref.mounted) {
      return;
    }
    _inflight.removeAll(missing);
    state = {...state, ...fetched};
  }
}

final merchantRatingsControllerProvider =
    NotifierProvider<MerchantRatingsController, Map<String, RatingSummary>>(
      MerchantRatingsController.new,
    );

final merchantSummaryProvider =
    FutureProvider.autoDispose.family<RatingSummary, String>((
      ref,
      merchantId,
    ) async {
      ref.watch(catalogScopeProvider);
      return ref.read(ratingsApiProvider).merchantSummary(merchantId);
    });
