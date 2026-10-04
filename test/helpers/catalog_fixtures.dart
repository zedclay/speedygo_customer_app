import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';

import 'fakes.dart';

const cafeBranchId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const espressoProductId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const drinksCategoryId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const merchantId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

const openHours = StorefrontHours(
  hoursConfigured: true,
  isOpenNow: true,
  timezone: 'Africa/Algiers',
);

StorefrontSummary cafeStorefront({
  String branchId = cafeBranchId,
  String branchName = 'Café Central',
  StorefrontHours hours = openHours,
  String? coverImageUrl,
}) {
  return StorefrontSummary(
    branchId: branchId,
    branchName: branchName,
    addressText: '12 rue Didouche, Alger',
    latitude: 36.75,
    longitude: 3.05,
    merchantId: merchantId,
    merchantName: 'Café Central SARL',
    merchantPublicReference: 'SG-M-1001',
    hours: hours,
    coverImageUrl: coverImageUrl,
  );
}

StorefrontDetail cafeStorefrontDetail({
  String branchId = cafeBranchId,
  StorefrontHours hours = openHours,
}) {
  final summary = cafeStorefront(branchId: branchId, hours: hours);
  return StorefrontDetail(
    branchId: summary.branchId,
    branchName: summary.branchName,
    addressText: summary.addressText,
    latitude: summary.latitude,
    longitude: summary.longitude,
    merchantId: summary.merchantId,
    merchantName: summary.merchantName,
    merchantPublicReference: summary.merchantPublicReference,
    hours: summary.hours,
    days: const [
      OpeningDay(
        dayOfWeek: 1,
        intervals: [
          OpeningInterval(
            opens: '08:00',
            closes: '18:00',
            opensMinute: 480,
            closesMinute: 1080,
            closesNextDay: false,
          ),
        ],
      ),
    ],
  );
}

CatalogProduct espresso({
  String productId = espressoProductId,
  String branchId = cafeBranchId,
  String priceMinor = '1200',
  String? imageUrl,
}) {
  return CatalogProduct(
    productId: productId,
    branchId: branchId,
    categoryId: drinksCategoryId,
    name: 'Espresso',
    description: 'Café serré',
    priceMinor: priceMinor,
    imageUrl: imageUrl,
  );
}

CatalogProductDetail espressoDetail({
  String productId = espressoProductId,
  String branchId = cafeBranchId,
  String priceMinor = '1200',
}) {
  final product = espresso(
    productId: productId,
    branchId: branchId,
    priceMinor: priceMinor,
  );
  return CatalogProductDetail(
    productId: product.productId,
    branchId: product.branchId,
    categoryId: product.categoryId,
    name: product.name,
    description: product.description,
    priceMinor: product.priceMinor,
    imageUrl: product.imageUrl,
    optionGroups: const [
      CatalogOptionGroup(
        optionGroupId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        name: 'Taille',
        required: true,
        minSelections: 1,
        maxSelections: 1,
        options: [
          CatalogProductOption(
            optionId: sizeNormalId,
            name: 'Simple',
            additionalPriceMinor: '0',
            available: true,
          ),
          CatalogProductOption(
            optionId: sizeDoubleId,
            name: 'Double',
            additionalPriceMinor: '200',
            available: true,
          ),
        ],
      ),
      CatalogOptionGroup(
        optionGroupId: extraGroupId,
        name: 'Suppléments',
        required: false,
        minSelections: 0,
        maxSelections: 2,
        options: [
          CatalogProductOption(
            optionId: extraSyrupId,
            name: 'Sirop',
            additionalPriceMinor: '100',
            available: true,
          ),
        ],
      ),
    ],
  );
}

const sizeNormalId = 'ffffffff-ffff-4fff-8fff-fffffffffff1';
const sizeDoubleId = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
const extraGroupId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1';
const extraSyrupId = 'ffffffff-ffff-4fff-8fff-fffffffffff2';
const otherBranchId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const otherProductId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const checkoutHomeAddressId = '12121212-1212-4121-8121-121212121212';
const checkoutWorkAddressId = '34343434-3434-4343-8343-343434343434';
const checkoutCartId = '11111111-1111-4111-8111-111111111111';
const checkoutZoneId = '56565656-5656-4565-8565-565656565656';
const checkoutRuleId = '78787878-7878-4787-8787-787878787878';
const checkoutItemId = '00000000-0000-4000-8000-000000000001';

FakeCartProduct espressoCartOffer() {
  return const FakeCartProduct(
    productId: espressoProductId,
    branchId: cafeBranchId,
    merchantId: merchantId,
    name: 'Espresso',
    priceMinor: '1200',
    options: {
      sizeNormalId: FakeCartOption(
        optionId: sizeNormalId,
        name: 'Simple',
        additionalPriceMinor: '0',
      ),
      sizeDoubleId: FakeCartOption(
        optionId: sizeDoubleId,
        name: 'Double',
        additionalPriceMinor: '200',
      ),
      extraSyrupId: FakeCartOption(
        optionId: extraSyrupId,
        name: 'Sirop',
        additionalPriceMinor: '100',
      ),
    },
  );
}

Map<String, dynamic> storefrontJson({
  String branchId = cafeBranchId,
  String branchName = 'Café Central',
  bool hoursConfigured = true,
  bool isOpenNow = true,
  String? coverImageUrl,
}) {
  return {
    'branchId': branchId,
    'branchName': branchName,
    'addressText': '12 rue Didouche, Alger',
    'latitude': 36.75,
    'longitude': 3.05,
    'merchantId': merchantId,
    'merchantName': 'Café Central SARL',
    'merchantPublicReference': 'SG-M-1001',
    'hoursConfigured': hoursConfigured,
    'isOpenNow': isOpenNow,
    'timezone': 'Africa/Algiers',
    'currentClosesAt': isOpenNow ? '2026-09-08T18:00:00.000Z' : null,
    'nextOpenAt': isOpenNow ? null : '2026-09-09T08:00:00.000Z',
    'coverImageUrl': coverImageUrl,
  };
}

Map<String, dynamic> productJson({
  String productId = espressoProductId,
  String branchId = cafeBranchId,
  String name = 'Espresso',
  String priceMinor = '1200',
  String? imageUrl,
}) {
  return {
    'productId': productId,
    'branchId': branchId,
    'categoryId': drinksCategoryId,
    'name': name,
    'description': 'Café serré',
    'priceMinor': priceMinor,
    'imageUrl': imageUrl,
  };
}

const checkoutHomeAddress = CustomerAddress(
  id: checkoutHomeAddressId,
  label: 'Domicile',
  addressText: 'Cité 120 logements',
  isDefault: true,
  latitude: 36.75,
  longitude: 3.05,
);

const checkoutWorkAddress = CustomerAddress(
  id: checkoutWorkAddressId,
  label: 'Bureau',
  addressText: 'Rue du Travail',
  isDefault: false,
  latitude: 36.76,
  longitude: 3.06,
);

CartItem espressoCheckoutItem({
  String lineSubtotalMinor = '1400',
  int quantity = 1,
}) {
  return CartItem(
    id: checkoutItemId,
    productId: espressoProductId,
    productName: 'Espresso',
    quantity: quantity,
    baseUnitPriceMinor: '1200',
    optionUnitAdditionalMinor: '200',
    unitPriceMinor: '1400',
    lineSubtotalMinor: lineSubtotalMinor,
    storedUnitPriceMinor: '1400',
    itemAvailable: true,
    selectedOptions: const [
      CartSelectedOption(
        optionId: sizeDoubleId,
        name: 'Double',
        additionalPriceMinor: '200',
        available: true,
      ),
    ],
    warnings: const [],
  );
}

CustomerCart espressoCheckoutCart({
  String subtotalMinor = '1400',
  bool cartReady = true,
}) {
  final item = espressoCheckoutItem(lineSubtotalMinor: subtotalMinor);
  return CustomerCart(
    id: checkoutCartId,
    status: 'ACTIVE',
    branchId: cafeBranchId,
    merchantId: merchantId,
    itemCount: 1,
    cartSubtotalMinor: subtotalMinor,
    cartReady: cartReady,
    warnings: const [],
    items: [item],
    createdAt: '2026-09-09T00:00:00.000Z',
    updatedAt: '2026-09-09T00:00:00.000Z',
  );
}

CheckoutPreview espressoCheckoutPreview({
  String addressId = checkoutHomeAddressId,
  String label = 'Domicile',
  String addressText = 'Cité 120 logements',
  String merchandiseSubtotalMinor = '1400',
  String deliveryFeeMinor = '500',
  String discountMinor = '0',
  String? promoCode,
  String? customerTotalMinor,
  List<String> warnings = const [],
}) {
  final total =
      customerTotalMinor ??
      (BigInt.parse(merchandiseSubtotalMinor) -
              BigInt.parse(discountMinor) +
              BigInt.parse(deliveryFeeMinor))
          .toString();
  return CheckoutPreview(
    checkoutReady: true,
    warnings: warnings,
    cart: CheckoutCartSummary(
      id: checkoutCartId,
      branchId: cafeBranchId,
      merchantId: merchantId,
      itemCount: 1,
      merchandiseSubtotalMinor: merchandiseSubtotalMinor,
      items: [
        espressoCheckoutItem(lineSubtotalMinor: merchandiseSubtotalMinor),
      ],
    ),
    address: CheckoutAddressSnapshot(
      id: addressId,
      label: label,
      addressText: addressText,
      latitude: 36.75,
      longitude: 3.05,
    ),
    deliveryZone: const CheckoutDeliveryZoneSummary(
      id: checkoutZoneId,
      name: 'Alger Centre',
    ),
    pricing: const CheckoutPricingSummary(
      ruleId: checkoutRuleId,
      ruleName: 'Journée',
      timeBand: 'DAY',
      timezone: 'Africa/Algiers',
    ),
    merchandiseSubtotalMinor: merchandiseSubtotalMinor,
    deliveryFeeMinor: deliveryFeeMinor,
    discountMinor: discountMinor,
    promoCode: promoCode,
    customerTotalMinor: total,
  );
}

Map<String, dynamic> espressoCheckoutPreviewJson({
  String addressId = checkoutHomeAddressId,
  String merchandiseSubtotalMinor = '1400',
  String deliveryFeeMinor = '500',
  String discountMinor = '0',
  String? promoCode,
  String customerTotalMinor = '1900',
}) {
  return {
    'checkoutReady': true,
    'warnings': <String>[],
    'cart': {
      'id': checkoutCartId,
      'branchId': cafeBranchId,
      'merchantId': merchantId,
      'itemCount': 1,
      'merchandiseSubtotalMinor': merchandiseSubtotalMinor,
      'items': [
        {
          'id': checkoutItemId,
          'productId': espressoProductId,
          'productName': 'Espresso',
          'quantity': 1,
          'baseUnitPriceMinor': '1200',
          'optionUnitAdditionalMinor': '200',
          'unitPriceMinor': '1400',
          'lineSubtotalMinor': merchandiseSubtotalMinor,
          'storedUnitPriceMinor': '1400',
          'itemAvailable': true,
          'selectedOptions': [
            {
              'optionId': sizeDoubleId,
              'name': 'Double',
              'additionalPriceMinor': '200',
              'available': true,
            },
          ],
          'warnings': <String>[],
        },
      ],
    },
    'address': {
      'id': addressId,
      'label': 'Domicile',
      'addressText': 'Cité 120 logements',
      'latitude': 36.75,
      'longitude': 3.05,
    },
    'deliveryZone': {'id': checkoutZoneId, 'name': 'Alger Centre'},
    'pricing': {
      'ruleId': checkoutRuleId,
      'ruleName': 'Journée',
      'timeBand': 'DAY',
      'timezone': 'Africa/Algiers',
    },
    'merchandiseSubtotalMinor': merchandiseSubtotalMinor,
    'deliveryFeeMinor': deliveryFeeMinor,
    'discountMinor': discountMinor,
    'promoCode': promoCode,
    'customerTotalMinor': customerTotalMinor,
  };
}
