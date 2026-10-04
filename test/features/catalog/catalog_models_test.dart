import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_api.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

import '../../helpers/catalog_fixtures.dart';

void main() {
  test('parses storefront page pagination without claiming extra pages', () {
    final page = parseStorefrontPage({
      'items': [storefrontJson()],
      'limit': 1,
      'offset': 0,
      'total': 2,
    });
    expect(page.items.single.branchId, cafeBranchId);
    expect(page.limit, 1);
    expect(page.offset, 0);
    expect(page.total, 2);
    expect(page.hasMore, isTrue);
    expect(page.items.single.hours.hoursConfigured, isTrue);
    expect(page.items.single.hours.isOpenNow, isTrue);
    expect(page.items.single.coverImageUrl, isNull);
  });

  test('keeps relative cover and product image paths and drops blanks', () {
    const cover =
        '/customer/branches/$cafeBranchId/cover';
    const image =
        '/customer/branches/$cafeBranchId/products/$espressoProductId/image';
    expect(
      StorefrontSummary.fromJson(
        storefrontJson(coverImageUrl: cover),
      ).coverImageUrl,
      cover,
    );
    expect(
      StorefrontSummary.fromJson(storefrontJson(coverImageUrl: '   ')).coverImageUrl,
      isNull,
    );
    expect(
      StorefrontDetail.fromJson(
        storefrontJson(coverImageUrl: cover)..['days'] = <Object>[],
      ).coverImageUrl,
      cover,
    );
    expect(
      CatalogProduct.fromJson(productJson(imageUrl: image)).imageUrl,
      image,
    );
    expect(CatalogProduct.fromJson(productJson(imageUrl: '')).imageUrl, isNull);
  });

  test('parses product money as exact strings and rejects numeric majors', () {
    final page = parseProductPage({
      'items': [productJson(priceMinor: '1200')],
      'limit': 50,
      'offset': 0,
      'total': 1,
    });
    expect(page.items.single.priceMinor, '1200');
    expect(page.items.single.imageUrl, isNull);
    expect(
      CatalogProduct.fromJson(
        productJson(
          imageUrl:
              '/customer/branches/$cafeBranchId/products/$espressoProductId/image',
        ),
      ).imageUrl,
      '/customer/branches/$cafeBranchId/products/$espressoProductId/image',
    );
    expect(page.hasMore, isFalse);
    expect(
      () => CatalogProduct.fromJson(productJson()..['priceMinor'] = 1200),
      throwsA(isA<CatalogParseException>()),
    );
  });

  test('preserves search hit_type order from the payload', () {
    final page = parseSearchPage({
      'items': [
        {
          'type': 'PRODUCT',
          'product': productJson(),
          'storefront': storefrontJson(),
        },
        {
          'type': 'STOREFRONT',
          'storefront': storefrontJson(branchName: 'Zidane Grill'),
        },
      ],
      'limit': 50,
      'offset': 0,
      'total': 2,
    });
    expect(page.items.map((hit) => hit.type), [
      CatalogHitType.product,
      CatalogHitType.storefront,
    ]);
    expect(page.items.first.product!.name, 'Espresso');
    expect(page.items.last.storefront!.branchName, 'Zidane Grill');
  });

  test('parses product option groups with additionalPriceMinor strings', () {
    final detail = CatalogProductDetail.fromJson({
      ...productJson(),
      'optionGroups': [
        {
          'optionGroupId': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
          'name': 'Taille',
          'required': true,
          'minSelections': 1,
          'maxSelections': 1,
          'options': [
            {
              'optionId': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
              'name': 'Double',
              'additionalPriceMinor': '200',
              'available': true,
            },
          ],
        },
      ],
    });
    expect(
      detail.optionGroups.single.options.single.additionalPriceMinor,
      '200',
    );
  });

  test('fixture ids are never treated as live catalog ids', () {
    expect(CatalogIds.isFixture('nav-branch'), isTrue);
    expect(CatalogIds.isFixture('nav-product'), isTrue);
    expect(CatalogIds.isLiveUuid('nav-branch'), isFalse);
    expect(CatalogIds.isLiveUuid(cafeBranchId), isTrue);
  });

  test('search Policy B strips wildcards then enforces 2..100', () {
    expect(normalizeCatalogSearchQuery('  %co_us\\cous%  '), 'couscous');
    expect(normalizeCatalogSearchQuery('% %').length, lessThan(2));
    expect(normalizeCatalogSearchQuery('a' * 100).length, 100);
    expect(normalizeCatalogSearchQuery('a' * 101).length, 101);
  });

  test('catalog query params stay inside backend pagination bounds', () {
    expect(const CatalogQuery(limit: 500, offset: 20000).toParams(), {
      'limit': 100,
      'offset': 10000,
      'sort': 'name',
    });
    expect(const CatalogQuery(limit: 0, offset: -4).toParams(), {
      'limit': 1,
      'offset': 0,
      'sort': 'name',
    });
    expect(const CatalogQuery(openNow: true).toParams(), {
      'limit': 50,
      'offset': 0,
      'sort': 'name',
      'openNow': true,
    });
    expect(const CatalogQuery(openNow: false).toParams().containsKey('openNow'), isFalse);
  });
}
