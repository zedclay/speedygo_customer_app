import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_api.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';

final promotionsApiProvider = Provider<PromotionsClient>((ref) {
  return PromotionsApi(ref.watch(authInfrastructureProvider).dio);
});

final discoverablePromotionsProvider =
    FutureProvider<List<DiscoverablePromotion>>((ref) async {
      ref.watch(catalogScopeProvider);
      return ref.read(promotionsApiProvider).listDiscoverable();
    });
