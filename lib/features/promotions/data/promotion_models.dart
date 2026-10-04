class PromotionParseException implements Exception {
  const PromotionParseException([this.message = 'Invalid promotion payload']);

  final String message;

  @override
  String toString() => message;
}

enum PromotionDiscountKind { fixedMinor, rateBps }

class DiscoverablePromotion {
  const DiscoverablePromotion({
    required this.id,
    required this.code,
    required this.discountKind,
    required this.value,
    required this.startsAt,
    required this.endsAt,
    this.customerLabel,
  });

  final String id;
  final String code;
  final PromotionDiscountKind discountKind;
  final int value;
  final String startsAt;
  final String endsAt;
  final String? customerLabel;

  factory DiscoverablePromotion.fromJson(Map<String, dynamic> json) {
    final kind = json['discountKind']?.toString();
    final discountKind = switch (kind) {
      'FIXED_MINOR' => PromotionDiscountKind.fixedMinor,
      'RATE_BPS' => PromotionDiscountKind.rateBps,
      _ => throw const PromotionParseException('discountKind is invalid'),
    };
    final value = json['value'];
    if (value is! int || value <= 0) {
      throw const PromotionParseException('value must be a positive integer');
    }
    final id = json['id']?.toString();
    final code = json['code']?.toString();
    final startsAt = json['startsAt']?.toString();
    final endsAt = json['endsAt']?.toString();
    if (id == null || id.isEmpty || code == null || code.isEmpty) {
      throw const PromotionParseException('id and code are required');
    }
    if (startsAt == null ||
        startsAt.isEmpty ||
        endsAt == null ||
        endsAt.isEmpty) {
      throw const PromotionParseException('window timestamps are required');
    }
    final rawLabel = json['customerLabel']?.toString().trim();
    return DiscoverablePromotion(
      id: id,
      code: code,
      discountKind: discountKind,
      value: value,
      startsAt: startsAt,
      endsAt: endsAt,
      customerLabel: rawLabel == null || rawLabel.isEmpty ? null : rawLabel,
    );
  }
}

List<DiscoverablePromotion> parseDiscoverablePromotionList(
  Map<String, dynamic> json,
) {
  final raw = json['items'];
  if (raw is! List) {
    throw const PromotionParseException('items must be a list');
  }
  return raw.map((item) {
    if (item is Map<String, dynamic>) {
      return DiscoverablePromotion.fromJson(item);
    }
    if (item is Map) {
      return DiscoverablePromotion.fromJson(Map<String, dynamic>.from(item));
    }
    throw const PromotionParseException('promotion must be an object');
  }).toList();
}
