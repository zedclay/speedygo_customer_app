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
