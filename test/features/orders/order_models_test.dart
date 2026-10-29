import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';

import '../../helpers/catalog_fixtures.dart';

void main() {
  test('CreateOrderRequest omits empty promo', () {
    final preview = espressoCheckoutPreview();
    final request = CreateOrderRequest.fromPreview(
      preview: preview,
      addressId: checkoutHomeAddressId,
      paymentMethod: 'COD',
    );
    expect(request.toJson().containsKey('promoCode'), isFalse);
    expect(request.expectedMerchandiseSubtotalMinor, 1400);
    expect(request.expectedDeliveryFeeMinor, 500);
    expect(request.expectedCustomerTotalMinor, 1900);
    expect(request.toJson()['expectedMerchandiseSubtotal'], '14.00');
    expect(request.toJson()['expectedDeliveryFee'], '5.00');
    expect(request.toJson()['expectedCustomerTotal'], '19.00');
  });

  test('order financial parses snapshot discountMinor', () {
    final financial = OrderFinancial.fromJson({
      'currency': 'DZD',
      'merchandiseSubtotalMinor': '1400',
      'deliveryFeeMinor': '500',
      'discountMinor': '400',
      'customerTotalMinor': '1500',
    });
    expect(financial.discountMinor, '400');
    expect(financial.hasDiscount, isTrue);
    expect(financial.showBreakdown, isTrue);
    expect(financial.showDiscountRow, isTrue);
    expect(
      int.parse(financial.merchandiseSubtotalMinor) -
          int.parse(financial.discountMinor) +
          int.parse(financial.deliveryFeeMinor),
      int.parse(financial.customerTotalMinor),
    );
  });

  test('v2 major-unit discount alias is ignored; *Minor stays centimes', () {
    final financial = OrderFinancial.fromJson({
      'currency': 'DZD',
      'merchandiseSubtotalMinor': '1400',
      'merchandiseSubtotal': '14.00',
      'deliveryFeeMinor': '500',
      'discountMinor': '400',
      'discount': '4.00',
      'customerTotalMinor': '1500',
      'customerTotal': '15.00',
    });
    expect(financial.discountMinor, '400');
    expect(financial.customerTotalMinor, '1500');
  });

  test('order financial defaults missing discount to zero', () {
    final financial = OrderFinancial.fromJson({
      'currency': 'DZD',
      'merchandiseSubtotalMinor': '1400',
      'deliveryFeeMinor': '500',
      'customerTotalMinor': '1900',
    });
    expect(financial.discountMinor, '0');
    expect(financial.hasDiscount, isFalse);
    expect(financial.discountFieldPresent, isFalse);
    expect(financial.showBreakdown, isTrue);
    expect(financial.showDiscountRow, isFalse);
  });

  test('missing discount that cannot reconcile omits breakdown', () {
    final financial = OrderFinancial.fromJson({
      'currency': 'DZD',
      'merchandiseSubtotalMinor': '1400',
      'deliveryFeeMinor': '500',
      'customerTotalMinor': '1500',
    });
    expect(financial.discountFieldPresent, isFalse);
    expect(financial.hasDiscount, isFalse);
    expect(financial.showBreakdown, isFalse);
    expect(financial.showDiscountRow, isFalse);
  });

  test('reconfirmation applyTo uses live discount and promo, not stale', () {
    final preview = espressoCheckoutPreview(
      promoCode: 'OLDCODE',
      discountMinor: '1400',
      customerTotalMinor: '500',
    );
    final updated = const OrderReconfirmationCurrent(
      merchandiseSubtotalMinor: '1400',
      deliveryFeeMinor: '500',
      discountMinor: '0',
      customerTotalMinor: '1900',
    ).applyTo(preview);
    expect(updated.discountMinor, '0');
    expect(updated.promoCode, isNull);
    expect(updated.customerTotalMinor, '1900');
    expect(
      const OrderReconfirmationCurrent(
        merchandiseSubtotalMinor: '1400',
        deliveryFeeMinor: '500',
        discountMinor: '0',
        customerTotalMinor: '1900',
      ).totalsReconcile,
      isTrue,
    );
  });

  test('CreateOrderRequest includes promo when set', () {
    final preview = espressoCheckoutPreview(
      promoCode: 'DEMOHOME150',
      discountMinor: '1400',
      customerTotalMinor: '500',
    );
    final request = CreateOrderRequest.fromPreview(
      preview: preview,
      addressId: checkoutHomeAddressId,
      paymentMethod: 'COD',
      promoCode: 'DEMOHOME150',
    );
    expect(request.toJson()['promoCode'], 'DEMOHOME150');
    expect(request.expectedCustomerTotalMinor, 500);
  });
}
