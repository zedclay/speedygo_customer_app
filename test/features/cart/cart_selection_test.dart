import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/cart/domain/cart_selection.dart';

import '../../helpers/catalog_fixtures.dart';

void main() {
  final product = espressoDetail();

  test('required group blocks add until selected', () {
    final empty = emptyProductConfig();
    expect(isProductConfigValid(product, empty), isFalse);
    final selected = toggleOption(product, empty, sizeNormalId);
    expect(isProductConfigValid(product, selected), isTrue);
    expect(estimateUnitMinor(product, selected), '1200');
    expect(estimateLineMinor(product, selected), '1200');
  });

  test('optional extras add exact surcharges and respect max', () {
    var draft = toggleOption(product, emptyProductConfig(), sizeDoubleId);
    draft = toggleOption(product, draft, extraSyrupId);
    expect(isProductConfigValid(product, draft), isTrue);
    expect(estimateUnitMinor(product, draft), '1500');
    expect(
      MoneyFormat.dzd(estimateLineMinor(product, changeQuantity(draft, 2))),
      '30,00 DZD',
    );
    expect(draft.optionIds, [extraSyrupId, sizeDoubleId]..sort());
  });

  test('quantity is clamped to 1..99', () {
    expect(clampCartQuantity(0), 1);
    expect(clampCartQuantity(100), 99);
    expect(isCartQuantity(99), isTrue);
    expect(isCartQuantity(100), isFalse);
  });

  test('radio required option cannot be cleared', () {
    final selected = toggleOption(product, emptyProductConfig(), sizeNormalId);
    final again = toggleOption(product, selected, sizeNormalId);
    expect(again.optionIds, [sizeNormalId]);
  });
}
