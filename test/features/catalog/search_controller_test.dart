import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/application/search_controller.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';

ProviderContainer _container(FakeCatalogClient catalog) {
  final container = ProviderContainer(
    overrides: [
      catalogApiProvider.overrideWithValue(catalog),
      catalogScopeProvider.overrideWithValue('1:p'),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

CatalogPage<CatalogSearchHit> _hitsFor(String q) {
  return CatalogPage(
    items: [
      CatalogSearchHit.product(
        product: CatalogProduct(
          productId: espressoProductId,
          branchId: cafeBranchId,
          categoryId: drinksCategoryId,
          name: q,
          priceMinor: '1200',
        ),
        storefront: cafeStorefront(),
      ),
    ],
    limit: 50,
    offset: 0,
    total: 1,
  );
}

void main() {
  testWidgets('debounces search and drops stale responses', (tester) async {
    final catalog = FakeCatalogClient(searchResultFor: _hitsFor);
    final container = _container(catalog);
    final notifier = container.read(catalogSearchControllerProvider.notifier);

    catalog.searchDelay = const Duration(milliseconds: 400);
    notifier.setQuery('old');
    await tester.pump(const Duration(milliseconds: 299));
    expect(catalog.searchCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(catalog.searchCount, 1);

    catalog.searchDelay = Duration.zero;
    notifier.setQuery('new');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    var state = container.read(catalogSearchControllerProvider);
    expect(state.phase, SearchPhase.data);
    expect(state.page!.items.single.product!.name, 'new');

    await tester.pump(const Duration(milliseconds: 400));
    state = container.read(catalogSearchControllerProvider);
    expect(state.page!.items.single.product!.name, 'new');
    expect(catalog.searchCount, 2);
  });

  testWidgets('does not call the API below two characters', (tester) async {
    final catalog = FakeCatalogClient();
    final container = _container(catalog);
    container.read(catalogSearchControllerProvider.notifier).setQuery('c');
    await tester.pump(const Duration(milliseconds: 350));
    expect(catalog.searchCount, 0);
    expect(
      container.read(catalogSearchControllerProvider).phase,
      SearchPhase.idle,
    );
  });

  test('rejects overlong normalized queries without calling the API', () {
    final catalog = FakeCatalogClient();
    final container = _container(catalog);
    container
        .read(catalogSearchControllerProvider.notifier)
        .setQuery('x' * 101);
    expect(catalog.searchCount, 0);
    final state = container.read(catalogSearchControllerProvider);
    expect(state.phase, SearchPhase.error);
    expect(state.error, isA<ApiException>());
    expect(state.error!.message, AppStrings.searchQueryInvalid);
  });
}
