import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';

/// Customer-facing copy from existing backend units. No invented min-spend.
class PromotionCopy {
  PromotionCopy._();

  static String label(DiscoverablePromotion promotion) {
    final custom = promotion.customerLabel?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return AppStrings.specialOffer;
  }

  static String headline(DiscoverablePromotion promotion) {
    switch (promotion.discountKind) {
      case PromotionDiscountKind.fixedMinor:
        return AppStrings.promoFixedHeadline(
          MoneyFormat.dzd(promotion.value.toString()),
        );
      case PromotionDiscountKind.rateBps:
        return AppStrings.promoRateHeadline(percentFromBps(promotion.value));
    }
  }

  static bool isExpired(DiscoverablePromotion promotion, [DateTime? now]) {
    final end = DateTime.tryParse(promotion.endsAt);
    if (end == null) {
      return false;
    }
    return !end.toUtc().isAfter((now ?? DateTime.now()).toUtc());
  }

  /// Africa/Algiers wall date (UTC+1, no DST). Empty when the timestamp is unusable.
  static String expiryDate(DiscoverablePromotion promotion) {
    final end = DateTime.tryParse(promotion.endsAt);
    if (end == null) {
      return '';
    }
    final zoned = end.toUtc().add(const Duration(hours: 1));
    if (AppStrings.isArabic) {
      return '${zoned.day}/${zoned.month}/${zoned.year}';
    }
    const months = <String>[
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${zoned.day} ${months[zoned.month - 1]} ${zoned.year}';
  }

  /// Basis points → display percent without float money math.
  /// 1000 → `10 %`; 1250 → `12,50 %`.
  static String percentFromBps(int bps) {
    final whole = bps ~/ 100;
    final fraction = bps.remainder(100);
    if (fraction == 0) {
      return '$whole %';
    }
    final padded = fraction.toString().padLeft(2, '0');
    return '$whole,$padded %';
  }
}
