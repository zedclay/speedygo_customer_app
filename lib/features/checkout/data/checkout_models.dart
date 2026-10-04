import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';

class CheckoutParseException implements Exception {
  const CheckoutParseException([this.message = 'Invalid checkout payload']);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _asMap(Object? value, String label) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw CheckoutParseException('$label must be an object');
}

String _reqString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw CheckoutParseException('$key is required');
  }
  return value;
}

String _money(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || !MoneyFormat.isMinorString(value)) {
    throw CheckoutParseException(
      '$key must be an exact non-negative decimal string',
    );
  }
  return value;
}

String _moneyOrZero(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '0';
  }
  if (value is! String || !MoneyFormat.isMinorString(value)) {
    throw CheckoutParseException(
      '$key must be an exact non-negative decimal string',
    );
  }
  return value;
}

int _reqInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.parse(value);
  }
  throw CheckoutParseException('$key must be an integer');
}

double _reqCoord(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  throw CheckoutParseException('$key must be a coordinate');
}

class CheckoutPreviewRequest {
  const CheckoutPreviewRequest({required this.addressId, this.promoCode});

  final String addressId;
  final String? promoCode;

  Map<String, dynamic> toJson() {
    if (!CatalogIds.isLiveUuid(addressId)) {
      throw const CheckoutParseException('addressId must be a live UUID');
    }
    final code = promoCode?.trim();
    return {
      'addressId': addressId,
      if (code != null && code.isNotEmpty) 'promoCode': code,
    };
  }
}

class CheckoutCartSummary {
  const CheckoutCartSummary({
    required this.id,
    required this.branchId,
    required this.merchantId,
    required this.itemCount,
    required this.merchandiseSubtotalMinor,
    required this.items,
  });

  final String id;
  final String branchId;
  final String merchantId;
  final int itemCount;
  final String merchandiseSubtotalMinor;
  final List<CartItem> items;

  factory CheckoutCartSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const CheckoutParseException('items must be a list');
    }
    return CheckoutCartSummary(
      id: _reqString(json, 'id'),
      branchId: _reqString(json, 'branchId'),
      merchantId: _reqString(json, 'merchantId'),
      itemCount: _reqInt(json, 'itemCount'),
      merchandiseSubtotalMinor: _money(json, 'merchandiseSubtotalMinor'),
      items: [
        for (final item in rawItems) CartItem.fromJson(_asMap(item, 'item')),
      ],
    );
  }
}

class CheckoutAddressSnapshot {
  const CheckoutAddressSnapshot({
    required this.id,
    required this.label,
    required this.addressText,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String label;
  final String addressText;
  final double latitude;
  final double longitude;

  factory CheckoutAddressSnapshot.fromJson(Map<String, dynamic> json) {
    return CheckoutAddressSnapshot(
      id: _reqString(json, 'id'),
      label: json['label']?.toString() ?? '',
      addressText: _reqString(json, 'addressText'),
      latitude: _reqCoord(json, 'latitude'),
      longitude: _reqCoord(json, 'longitude'),
    );
  }

  String get displayLabel {
    final trimmed = label.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return addressText.trim();
  }
}

class CheckoutDeliveryZoneSummary {
  const CheckoutDeliveryZoneSummary({required this.id, required this.name});

  final String id;
  final String name;

  factory CheckoutDeliveryZoneSummary.fromJson(Map<String, dynamic> json) {
    return CheckoutDeliveryZoneSummary(
      id: _reqString(json, 'id'),
      name: _reqString(json, 'name'),
    );
  }
}

class CheckoutPricingSummary {
  const CheckoutPricingSummary({
    required this.ruleId,
    required this.ruleName,
    required this.timeBand,
    required this.timezone,
  });

  final String ruleId;
  final String ruleName;
  final String timeBand;
  final String timezone;

  factory CheckoutPricingSummary.fromJson(Map<String, dynamic> json) {
    return CheckoutPricingSummary(
      ruleId: _reqString(json, 'ruleId'),
      ruleName: _reqString(json, 'ruleName'),
      timeBand: _reqString(json, 'timeBand'),
      timezone: _reqString(json, 'timezone'),
    );
  }
}

class CheckoutPreview {
  const CheckoutPreview({
    required this.checkoutReady,
    required this.warnings,
    required this.cart,
    required this.address,
    required this.deliveryZone,
    required this.pricing,
    required this.merchandiseSubtotalMinor,
    required this.deliveryFeeMinor,
    required this.discountMinor,
    required this.promoCode,
    required this.customerTotalMinor,
  });

  final bool checkoutReady;
  final List<String> warnings;
  final CheckoutCartSummary cart;
  final CheckoutAddressSnapshot address;
  final CheckoutDeliveryZoneSummary deliveryZone;
  final CheckoutPricingSummary pricing;
  final String merchandiseSubtotalMinor;
  final String deliveryFeeMinor;
  final String discountMinor;
  final String? promoCode;
  final String customerTotalMinor;

  bool get promoApplied => promoCode != null && promoCode!.isNotEmpty;

  bool get priceChanged => warnings.contains('PRICE_CHANGED');

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) {
    if (json['checkoutReady'] != true) {
      throw const CheckoutParseException('checkoutReady must be true');
    }
    final rawWarnings = json['warnings'];
    if (rawWarnings is! List) {
      throw const CheckoutParseException('warnings must be a list');
    }
    final rawPromo = json['promoCode']?.toString();
    return CheckoutPreview(
      checkoutReady: true,
      warnings: rawWarnings.map((item) => item.toString()).toList(),
      cart: CheckoutCartSummary.fromJson(_asMap(json['cart'], 'cart')),
      address: CheckoutAddressSnapshot.fromJson(
        _asMap(json['address'], 'address'),
      ),
      deliveryZone: CheckoutDeliveryZoneSummary.fromJson(
        _asMap(json['deliveryZone'], 'deliveryZone'),
      ),
      pricing: CheckoutPricingSummary.fromJson(
        _asMap(json['pricing'], 'pricing'),
      ),
      merchandiseSubtotalMinor: _money(json, 'merchandiseSubtotalMinor'),
      deliveryFeeMinor: _money(json, 'deliveryFeeMinor'),
      discountMinor: _moneyOrZero(json, 'discountMinor'),
      promoCode: rawPromo == null || rawPromo.isEmpty ? null : rawPromo,
      customerTotalMinor: _money(json, 'customerTotalMinor'),
    );
  }
}

bool isPromotionCheckoutError(String? code) {
  return code != null && code.startsWith('PROMOTION_');
}
