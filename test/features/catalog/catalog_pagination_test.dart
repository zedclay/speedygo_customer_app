import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_feed.dart';
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

List<StorefrontSummary> _namedStorefronts(int count) {
  return [
    for (var i = 0; i < count; i++)
      cafeStorefront(
        branchId: 'aaaaaaaa-aaaa-4aaa-8aaa-${i.toString().padLeft(12, '0')}',
        branchName: 'Cafe ${i.toString().padLeft(2, '0')}',
      ),
  ];
}

List<CatalogProduct> _namedProducts(int count, {String? categoryId}) {
  return [
    for (var i = 0; i < count; i++)
      espresso(
        productId: 'bbbbbbbb-bbbb-4bbb-8bbb-${i.toString().padLeft(12, '0')}',
      ).copyWith(
        name: 'Produit ${i.toString().padLeft(2, '0')}',
        categoryId: categoryId ?? drinksCategoryId,
      ),
  ];
}

extension on CatalogProduct {
  CatalogProduct copyWith({String? name, String? categoryId}) {
    return CatalogProduct(
      productId: productId,
      branchId: branchId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description,
      priceMinor: priceMinor,
      imageUrl: imageUrl,
    );
  }
}

void main() {
  test('appendUniqueById keeps first-seen order', () {
    final first = _namedStorefronts(2);
    final incoming = [
      first.first,
      cafeStorefront(
        branchId: 'aaaaaaaa-aaaa-4aaa-8aaa-000000000099',
        branchName: 'Cafe 99',
      ),
    ];
    final merged = appendUniqueById(first, incoming, (item) => item.branchId);
    expect(merged.map((item) => item.branchName).toList(), [
      'Cafe 00',
      'Cafe 01',
      'Cafe 99',
    ]);
  });

  testWidgets(
    'storefront list paginates uniquely and ignores a second in-flight',
    (tester) async {
      final items = _namedStorefronts(3);
      final catalog = FakeCatalogClient(
        storefronts: CatalogPage(items: items, limit: 2, offset: 0, total: 3),
        testPageCap: 2,
        listDelay: const Duration(milliseconds: 40),
      );
      final container = _container(catalog);
      final notifier = container.read(
        storefrontListControllerProvider.notifier,
      );
      await tester.pump();
      expect(container.read(storefrontListControllerProvider).items.length, 2);
      expect(catalog.listCount, 1);

      unawaited(notifier.loadMore());
      unawaited(notifier.loadMore());
      await tester.pump(const Duration(milliseconds: 50));
      final state = container.read(storefrontListControllerProvider);
      expect(catalog.listCount, 2);
      expect(state.items.map((item) => item.branchName).toList(), [
        'Cafe 00',
        'Cafe 01',
        'Cafe 02',
      ]);
      expect(state.hasMore, isFalse);
    },
  );

  testWidgets('storefront load-more duplicates are dropped', (tester) async {
    final items = _namedStorefronts(3);
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(items: items, limit: 2, offset: 0, total: 3),
      testPageCap: 2,
      duplicateFirstOnLoadMore: true,
    );
    final container = _container(catalog);
    container.read(storefrontListControllerProvider);
    await tester.pump();
    await container.read(storefrontListControllerProvider.notifier).loadMore();
    final state = container.read(storefrontListControllerProvider);
    expect(state.items.map((item) => item.branchId).toSet().length, 3);
    expect(state.items.first.branchName, 'Cafe 00');
  });

  testWidgets('storefront load-more failure keeps items and retries', (
    tester,
  ) async {
    final items = _namedStorefronts(3);
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(items: items, limit: 2, offset: 0, total: 3),
      testPageCap: 2,
      loadMoreError: NetworkException(
        AppStrings.offline,
        code: 'NETWORK',
      ),
    );
    final container = _container(catalog);
    final notifier = container.read(storefrontListControllerProvider.notifier);
    await tester.pump();
    expect(container.read(storefrontListControllerProvider).items.length, 2);

    await notifier.loadMore();
    var state = container.read(storefrontListControllerProvider);
    expect(state.items.length, 2);
    expect(state.loadMoreError, isA<NetworkException>());

    catalog.loadMoreError = null;
    await notifier.loadMore();
    state = container.read(storefrontListControllerProvider);
    expect(state.items.length, 3);
    expect(state.loadMoreError, isNull);
  });

  testWidgets('product pagination resets when category changes', (
    tester,
  ) async {
    const otherCategory = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2';
    final catalog = FakeCatalogClient(
      products: CatalogPage(
        items: [
          ..._namedProducts(2),
          ..._namedProducts(1, categoryId: otherCategory),
        ],
        limit: 1,
        offset: 0,
        total: 3,
      ),
      testPageCap: 1,
    );
    final container = _container(catalog);
    const allArgs = StorefrontProductsArgs(branchId: cafeBranchId);
    container.read(storefrontProductsControllerProvider(allArgs));
    await tester.pump();
    expect(
      container
          .read(storefrontProductsControllerProvider(allArgs))
          .items
          .length,
      1,
    );
    await container
        .read(storefrontProductsControllerProvider(allArgs).notifier)
        .loadMore();
    expect(
      container
          .read(storefrontProductsControllerProvider(allArgs))
          .items
          .length,
      2,
    );

    const drinksArgs = StorefrontProductsArgs(
      branchId: cafeBranchId,
      categoryId: drinksCategoryId,
    );
    container.read(storefrontProductsControllerProvider(drinksArgs));
    await tester.pump();
    final drinks = container.read(
      storefrontProductsControllerProvider(drinksArgs),
    );
    expect(drinks.items.length, 1);
    expect(
      drinks.items.every((item) => item.categoryId == drinksCategoryId),
      isTrue,
    );
    expect(catalog.productListCount, greaterThanOrEqualTo(3));
  });

  testWidgets('search load-more resets when the query changes', (tester) async {
    CatalogPage<CatalogSearchHit> pageFor(String q, int total) {
      return CatalogPage(
        items: [
          for (var i = 0; i < total; i++)
            CatalogSearchHit.product(
              product: espresso(
                productId:
                    'bbbbbbbb-bbbb-4bbb-8bbb-${(q.codeUnitAt(0) * 10 + i).toString().padLeft(12, '0')}',
              ).copyWith(name: '$q $i'),
              storefront: cafeStorefront(),
            ),
        ],
        limit: 1,
        offset: 0,
        total: total,
      );
    }

    final catalog = FakeCatalogClient(
      testPageCap: 1,
      searchResultFor: (q) => pageFor(q, 3),
    );
    final container = _container(catalog);
    final notifier = container.read(catalogSearchControllerProvider.notifier);
    notifier.setQuery('ab');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(
      container.read(catalogSearchControllerProvider).page!.items.length,
      1,
    );

    await notifier.loadMore();
    expect(
      container.read(catalogSearchControllerProvider).page!.items.length,
      2,
    );

    notifier.setQuery('cd');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    final state = container.read(catalogSearchControllerProvider);
    expect(state.page!.items.length, 1);
    expect(state.page!.items.single.product!.name, 'cd 0');
    expect(state.hasMore, isTrue);
  });

  testWidgets('storefront pagination resets when commerce vertical changes', (
    tester,
  ) async {
    final items = _namedStorefronts(3);
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(items: items, limit: 2, offset: 0, total: 3),
      testPageCap: 2,
    );
    final container = _container(catalog);
    final notifier = container.read(storefrontListControllerProvider.notifier);
    await tester.pump();
    await notifier.loadMore();
    expect(container.read(storefrontListControllerProvider).items.length, 3);

    const verticalId = '11111111-1111-4111-8111-111111111111';
    container
        .read(selectedCommerceVerticalIdProvider.notifier)
        .select(verticalId);
    await tester.pump();
    await tester.pump();
    final state = container.read(storefrontListControllerProvider);
    expect(catalog.lastStorefrontQuery?.verticalId, verticalId);
    expect(state.items.length, 2);
    expect(state.loadingMore, isFalse);
  });
}
