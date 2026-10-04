import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';

import '../../helpers/catalog_fixtures.dart';

void main() {
  test('preview request sends only addressId and optional promoCode', () {
    expect(
      const CheckoutPreviewRequest(addressId: checkoutHomeAddressId).toJson(),
      {'addressId': checkoutHomeAddressId},
    );
    expect(
      const CheckoutPreviewRequest(
        addressId: checkoutHomeAddressId,
        promoCode: ' SAVE10 ',
      ).toJson(),
      {'addressId': checkoutHomeAddressId, 'promoCode': 'SAVE10'},
    );
    expect(
      const CheckoutPreviewRequest(
        addressId: checkoutHomeAddressId,
        promoCode: '',
      ).toJson(),
      {'addressId': checkoutHomeAddressId},
    );
    expect(
      const CheckoutPreviewRequest(
        addressId: checkoutHomeAddressId,
        promoCode: 'SAVE10',
      ).toJson().containsKey('paymentMethod'),
      isFalse,
    );
  });

  test('preview response keeps exact server money strings', () {
    final preview = CheckoutPreview.fromJson(
      espressoCheckoutPreviewJson(
        merchandiseSubtotalMinor: '1400',
        deliveryFeeMinor: '500',
        discountMinor: '150',
        promoCode: 'SAVE10',
        customerTotalMinor: '1750',
      ),
    );
    expect(preview.checkoutReady, isTrue);
    expect(preview.merchandiseSubtotalMinor, '1400');
    expect(preview.deliveryFeeMinor, '500');
    expect(preview.discountMinor, '150');
    expect(preview.promoCode, 'SAVE10');
    expect(preview.promoApplied, isTrue);
    expect(preview.customerTotalMinor, '1750');
  });

  test(
    'omitted promo is not treated as applied and discount defaults to 0',
    () {
      final json = espressoCheckoutPreviewJson()..remove('promoCode');
      json.remove('discountMinor');
      final preview = CheckoutPreview.fromJson(json);
      expect(preview.promoCode, isNull);
      expect(preview.promoApplied, isFalse);
      expect(preview.discountMinor, '0');
    },
  );

  test('checkoutReady false and invalid money are rejected', () {
    expect(
      () => CheckoutPreview.fromJson(
        espressoCheckoutPreviewJson()..['checkoutReady'] = false,
      ),
      throwsA(isA<CheckoutParseException>()),
    );
    expect(
      () => CheckoutPreview.fromJson(
        espressoCheckoutPreviewJson()..['customerTotalMinor'] = '19.00',
      ),
      throwsA(isA<CheckoutParseException>()),
    );
  });

  test('French copy covers checkout and promotion errors', () {
    expect(
      AppStrings.errorForCode('CHECKOUT_ADDRESS_OUTSIDE_ZONE'),
      contains('zone de livraison'),
    );
    expect(
      AppStrings.errorForCode('CHECKOUT_BRANCH_CLOSED'),
      contains('fermé'),
    );
    expect(AppStrings.errorForCode('PROMOTION_EXPIRED'), contains('expiré'));
    expect(
      AppStrings.errorForCode('CHECKOUT_CART_REQUIRED'),
      isNot(contains('CHECKOUT_')),
    );
  });
}
