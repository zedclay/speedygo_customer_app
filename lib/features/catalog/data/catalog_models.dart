import 'package:speedygo_customer_app/core/money/money_format.dart';

class CatalogParseException implements Exception {
  const CatalogParseException([this.message = 'Invalid catalog payload']);

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
  throw CatalogParseException('$label must be an object');
}

String _reqString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw CatalogParseException('$key is required');
  }
  return value;
}

String _money(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || !MoneyFormat.isMinorString(value)) {
    throw CatalogParseException(
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
  throw CatalogParseException('$key must be an integer');
}

double _reqDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  throw CatalogParseException('$key must be a number');
}

bool _reqBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  throw CatalogParseException('$key must be a boolean');
}

class DeliveryCoverage {
  const DeliveryCoverage({
    required this.inCoverage,
    required this.zoneCount,
    required this.reason,
  });

  final bool inCoverage;
  final int zoneCount;
  final String reason;

  bool get isOutside => reason == 'OUTSIDE' || reason == 'AMBIGUOUS';

  bool get isInside => reason == 'INSIDE';

  /// Favorites presentation: UNFILTERED/AMBIGUOUS cannot be claimed inside or out.
  bool get isUnknown => !isInside && reason != 'OUTSIDE';

  factory DeliveryCoverage.fromJson(Map<String, dynamic> json) {
    return DeliveryCoverage(
      inCoverage: json['inCoverage'] == true,
      zoneCount: json['zoneCount'] is int
          ? json['zoneCount'] as int
          : int.tryParse(json['zoneCount']?.toString() ?? '') ?? 0,
      reason: json['reason']?.toString() ?? 'UNFILTERED',
    );
  }
}

class CatalogPage<T> {
  const CatalogPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    this.coverage,
  });

  final List<T> items;
  final int limit;
  final int offset;
  final int total;
  final DeliveryCoverage? coverage;

  bool get hasMore => offset + items.length < total;
}

class StorefrontHours {
  const StorefrontHours({
    required this.hoursConfigured,
    required this.isOpenNow,
    required this.timezone,
    this.currentClosesAt,
    this.nextOpenAt,
  });

  final bool hoursConfigured;
  final bool isOpenNow;
  final String timezone;
  final DateTime? currentClosesAt;
  final DateTime? nextOpenAt;

  factory StorefrontHours.fromJson(Map<String, dynamic> json) {
    return StorefrontHours(
      hoursConfigured: _reqBool(json, 'hoursConfigured'),
      isOpenNow: _reqBool(json, 'isOpenNow'),
      timezone: json['timezone']?.toString() ?? 'Africa/Algiers',
      currentClosesAt: _parseTime(json['currentClosesAt']),
      nextOpenAt: _parseTime(json['nextOpenAt']),
    );
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString());
  }
}

class OpeningInterval {
  const OpeningInterval({
    required this.opens,
    required this.closes,
    required this.opensMinute,
    required this.closesMinute,
    required this.closesNextDay,
  });

  final String opens;
  final String closes;
  final int opensMinute;
  final int closesMinute;
  final bool closesNextDay;

  factory OpeningInterval.fromJson(Map<String, dynamic> json) {
    return OpeningInterval(
      opens: _reqString(json, 'opens'),
      closes: _reqString(json, 'closes'),
      opensMinute: _reqInt(json, 'opensMinute'),
      closesMinute: _reqInt(json, 'closesMinute'),
      closesNextDay: _reqBool(json, 'closesNextDay'),
    );
  }
}

class OpeningDay {
  const OpeningDay({required this.dayOfWeek, required this.intervals});

  /// ISO weekday: 1 = Monday … 7 = Sunday.
  final int dayOfWeek;
  final List<OpeningInterval> intervals;

  factory OpeningDay.fromJson(Map<String, dynamic> json) {
    final raw = json['intervals'];
    if (raw is! List) {
      throw const CatalogParseException('intervals must be a list');
    }
    return OpeningDay(
      dayOfWeek: _reqInt(json, 'dayOfWeek'),
      intervals: raw
          .map((item) => OpeningInterval.fromJson(_asMap(item, 'interval')))
          .toList(),
    );
  }
}

class StorefrontSummary {
  const StorefrontSummary({
    required this.branchId,
    required this.branchName,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.merchantId,
    required this.merchantName,
    required this.merchantPublicReference,
    required this.hours,
    this.coverImageUrl,
    this.coverage,
  });

  final String branchId;
  final String branchName;
  final String addressText;
  final double latitude;
  final double longitude;
  final String merchantId;
  final String merchantName;
  final String merchantPublicReference;
  final StorefrontHours hours;
  final String? coverImageUrl;
  final DeliveryCoverage? coverage;

  factory StorefrontSummary.fromJson(Map<String, dynamic> json) {
    final rawCover = json['coverImageUrl']?.toString().trim();
    final rawCoverage = json['coverage'];
    return StorefrontSummary(
      branchId: _reqString(json, 'branchId'),
      branchName: _reqString(json, 'branchName'),
      addressText: json['addressText']?.toString() ?? '',
      latitude: _reqDouble(json, 'latitude'),
      longitude: _reqDouble(json, 'longitude'),
      merchantId: _reqString(json, 'merchantId'),
      merchantName: _reqString(json, 'merchantName'),
      merchantPublicReference:
          json['merchantPublicReference']?.toString() ?? '',
      hours: StorefrontHours.fromJson(json),
      coverImageUrl: rawCover == null || rawCover.isEmpty ? null : rawCover,
      coverage: rawCoverage is Map
          ? DeliveryCoverage.fromJson(Map<String, dynamic>.from(rawCoverage))
          : null,
    );
  }
}

class StorefrontDetail extends StorefrontSummary {
  const StorefrontDetail({
    required super.branchId,
    required super.branchName,
    required super.addressText,
    required super.latitude,
    required super.longitude,
    required super.merchantId,
    required super.merchantName,
    required super.merchantPublicReference,
    required super.hours,
    super.coverImageUrl,
    super.coverage,
    required this.days,
  });

  final List<OpeningDay> days;

  factory StorefrontDetail.fromJson(Map<String, dynamic> json) {
    final summary = StorefrontSummary.fromJson(json);
    final rawDays = json['days'];
    final days = <OpeningDay>[];
    if (rawDays is List) {
      for (final item in rawDays) {
        days.add(OpeningDay.fromJson(_asMap(item, 'day')));
      }
    }
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
      coverImageUrl: summary.coverImageUrl,
      coverage: summary.coverage,
      days: days,
    );
  }
}

class CatalogCategory {
  const CatalogCategory({
    required this.categoryId,
    required this.name,
    required this.sortOrder,
  });

  final String categoryId;
  final String name;
  final int sortOrder;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      categoryId: _reqString(json, 'categoryId'),
      name: _reqString(json, 'name'),
      sortOrder: _reqInt(json, 'sortOrder'),
    );
  }
}

class CatalogProduct {
  const CatalogProduct({
    required this.productId,
    required this.branchId,
    required this.categoryId,
    required this.name,
    required this.priceMinor,
    this.description,
    this.imageUrl,
  });

  final String productId;
  final String branchId;
  final String categoryId;
  final String name;
  final String? description;
  final String priceMinor;
  final String? imageUrl;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final rawImage = json['imageUrl']?.toString().trim();
    return CatalogProduct(
      productId: _reqString(json, 'productId'),
      branchId: _reqString(json, 'branchId'),
      categoryId: _reqString(json, 'categoryId'),
      name: _reqString(json, 'name'),
      description: json['description']?.toString(),
      priceMinor: _money(json, 'priceMinor'),
      imageUrl: rawImage == null || rawImage.isEmpty ? null : rawImage,
    );
  }
}

class CatalogProductOption {
  const CatalogProductOption({
    required this.optionId,
    required this.name,
    required this.additionalPriceMinor,
    required this.available,
  });

  final String optionId;
  final String name;
  final String additionalPriceMinor;
  final bool available;

  factory CatalogProductOption.fromJson(Map<String, dynamic> json) {
    return CatalogProductOption(
      optionId: _reqString(json, 'optionId'),
      name: _reqString(json, 'name'),
      additionalPriceMinor: _money(json, 'additionalPriceMinor'),
      available: _reqBool(json, 'available'),
    );
  }
}

class CatalogOptionGroup {
  const CatalogOptionGroup({
    required this.optionGroupId,
    required this.name,
    required this.required,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
  });

  final String optionGroupId;
  final String name;
  final bool required;
  final int minSelections;
  final int maxSelections;
  final List<CatalogProductOption> options;

  factory CatalogOptionGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    if (raw is! List) {
      throw const CatalogParseException('options must be a list');
    }
    return CatalogOptionGroup(
      optionGroupId: _reqString(json, 'optionGroupId'),
      name: _reqString(json, 'name'),
      required: _reqBool(json, 'required'),
      minSelections: _reqInt(json, 'minSelections'),
      maxSelections: _reqInt(json, 'maxSelections'),
      options: raw
          .map((item) => CatalogProductOption.fromJson(_asMap(item, 'option')))
          .toList(),
    );
  }
}

class CatalogProductDetail extends CatalogProduct {
  const CatalogProductDetail({
    required super.productId,
    required super.branchId,
    required super.categoryId,
    required super.name,
    required super.priceMinor,
    super.description,
    super.imageUrl,
    required this.optionGroups,
  });

  final List<CatalogOptionGroup> optionGroups;

  factory CatalogProductDetail.fromJson(Map<String, dynamic> json) {
    final product = CatalogProduct.fromJson(json);
    final raw = json['optionGroups'];
    if (raw is! List) {
      throw const CatalogParseException('optionGroups must be a list');
    }
    return CatalogProductDetail(
      productId: product.productId,
      branchId: product.branchId,
      categoryId: product.categoryId,
      name: product.name,
      description: product.description,
      priceMinor: product.priceMinor,
      imageUrl: product.imageUrl,
      optionGroups: raw
          .map(
            (item) => CatalogOptionGroup.fromJson(_asMap(item, 'optionGroup')),
          )
          .toList(),
    );
  }
}

enum CatalogHitType { storefront, product }

class CatalogSearchHit {
  const CatalogSearchHit._({required this.type, this.storefront, this.product});

  final CatalogHitType type;
  final StorefrontSummary? storefront;
  final CatalogProduct? product;

  factory CatalogSearchHit.storefront(StorefrontSummary storefront) {
    return CatalogSearchHit._(
      type: CatalogHitType.storefront,
      storefront: storefront,
    );
  }

  factory CatalogSearchHit.product({
    required CatalogProduct product,
    required StorefrontSummary storefront,
  }) {
    return CatalogSearchHit._(
      type: CatalogHitType.product,
      product: product,
      storefront: storefront,
    );
  }

  factory CatalogSearchHit.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString();
    if (type == 'STOREFRONT') {
      return CatalogSearchHit.storefront(
        StorefrontSummary.fromJson(_asMap(json['storefront'], 'storefront')),
      );
    }
    if (type == 'PRODUCT') {
      return CatalogSearchHit.product(
        product: CatalogProduct.fromJson(_asMap(json['product'], 'product')),
        storefront: StorefrontSummary.fromJson(
          _asMap(json['storefront'], 'storefront'),
        ),
      );
    }
    throw CatalogParseException('Unknown search hit type: $type');
  }
}

CatalogPage<StorefrontSummary> parseStorefrontPage(Map<String, dynamic> json) {
  final page = _page(json, (item) => StorefrontSummary.fromJson(item));
  final raw = json['coverage'];
  if (raw is! Map) {
    return page;
  }
  return CatalogPage(
    items: page.items,
    limit: page.limit,
    offset: page.offset,
    total: page.total,
    coverage: DeliveryCoverage.fromJson(Map<String, dynamic>.from(raw)),
  );
}

CatalogPage<CatalogProduct> parseProductPage(Map<String, dynamic> json) {
  return _page(json, (item) => CatalogProduct.fromJson(item));
}

CatalogPage<CatalogSearchHit> parseSearchPage(Map<String, dynamic> json) {
  return _page(json, CatalogSearchHit.fromJson);
}

class CommerceVertical {
  const CommerceVertical({
    required this.id,
    required this.slug,
    required this.name,
    required this.iconKey,
    required this.sortOrder,
  });

  final String id;
  final String slug;
  final String name;
  final String iconKey;
  final int sortOrder;

  factory CommerceVertical.fromJson(Map<String, dynamic> json) {
    return CommerceVertical(
      id: _reqString(json, 'id'),
      slug: _reqString(json, 'slug'),
      name: _reqString(json, 'name'),
      iconKey: _reqString(json, 'iconKey'),
      sortOrder: _reqInt(json, 'sortOrder'),
    );
  }
}

List<CommerceVertical> parseCommerceVerticalList(Map<String, dynamic> json) {
  final raw = json['items'];
  if (raw is! List) {
    throw const CatalogParseException('items must be a list');
  }
  return raw
      .map((item) => CommerceVertical.fromJson(_asMap(item, 'vertical')))
      .toList();
}

List<CatalogCategory> parseCategoryList(Map<String, dynamic> json) {
  final raw = json['items'];
  if (raw is! List) {
    throw const CatalogParseException('items must be a list');
  }
  return raw
      .map((item) => CatalogCategory.fromJson(_asMap(item, 'category')))
      .toList();
}

CatalogPage<T> _page<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic> item) parseItem,
) {
  final raw = json['items'];
  if (raw is! List) {
    throw const CatalogParseException('items must be a list');
  }
  return CatalogPage(
    items: raw.map((item) => parseItem(_asMap(item, 'item'))).toList(),
    limit: _reqInt(json, 'limit'),
    offset: _reqInt(json, 'offset'),
    total: _reqInt(json, 'total'),
  );
}
