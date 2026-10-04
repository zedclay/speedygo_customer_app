import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';

import '../../helpers/catalog_fixtures.dart';

void main() {
  test('parses cart bootstrap and money strings', () {
    final json = {
      'cartExists': true,
      'cart': {
        'id': cafeBranchId,
        'status': 'ACTIVE',
        'branchId': cafeBranchId,
        'merchantId': merchantId,
        'itemCount': 1,
        'cartSubtotalMinor': '1400',
        'cartReady': true,
        'warnings': <String>[],
        'createdAt': '2026-09-09T00:00:00.000Z',
        'updatedAt': '2026-09-09T00:00:00.000Z',
        'items': [
          {
            'id': espressoProductId,
            'productId': espressoProductId,
            'productName': 'Espresso',
            'quantity': 1,
            'baseUnitPriceMinor': '1200',
            'optionUnitAdditionalMinor': '200',
            'unitPriceMinor': '1400',
            'lineSubtotalMinor': '1400',
            'storedUnitPriceMinor': '1400',
            'itemAvailable': true,
            'warnings': <String>[],
            'selectedOptions': [
              {
                'optionId': sizeDoubleId,
                'name': 'Double',
                'additionalPriceMinor': '200',
                'available': true,
              },
            ],
          },
        ],
      },
    };
    final bootstrap = CartBootstrap.fromJson(json);
    expect(bootstrap.cartExists, isTrue);
    expect(bootstrap.cart!.cartSubtotalMinor, '1400');
    expect(bootstrap.cart!.items.single.unitPriceMinor, '1400');
    expect(bootstrap.badgeCount, 1);
  });

  test('rejects nav fixture ids on add payload', () {
    expect(
      () => const AddCartItemRequest(
        productId: 'nav-product',
        quantity: 1,
      ).toJson(),
      throwsA(isA<CartParseException>()),
    );
  });

  test('empty bootstrap is cartExists false', () {
    final bootstrap = CartBootstrap.fromJson({
      'cartExists': false,
      'cart': null,
    });
    expect(bootstrap.cart, isNull);
    expect(bootstrap.badgeCount, 0);
  });
}
