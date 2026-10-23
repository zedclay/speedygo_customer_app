import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_category_strip.dart';

/// Canonical kind inferred only from stable API slugs (never display names).
String? commerceVerticalKind(String slug) {
  final s = slug.trim().toLowerCase();
  if (s == 'restaurants' || s.endsWith('-restaurants')) {
    return 'restaurants';
  }
  if (s == 'desserts' || s.endsWith('-desserts')) {
    return 'desserts';
  }
  if (s == 'bakeries' ||
      s == 'boulangeries' ||
      s.endsWith('-bakeries') ||
      s.endsWith('-boulangeries')) {
    return 'bakeries';
  }
  if (s == 'groceries' ||
      s == 'epiceries' ||
      s.endsWith('-groceries') ||
      s.endsWith('-epiceries')) {
    return 'groceries';
  }
  if (s == 'pharmacies' || s.endsWith('-pharmacies')) {
    return 'pharmacies';
  }
  if (s == 'supermarkets' || s.endsWith('-supermarkets')) {
    return 'supermarkets';
  }
  return null;
}

const restaurantsHeroAsset = 'assets/categories/restaurants_hero.jpg';

/// Stitch-aligned presentation tokens for Toutes les catégories.
class CategoriesLayout {
  CategoriesLayout._();

  static const margin = 16.0;
  static const sectionGap = 24.0;
  static const gridGap = 16.0;
  static const headerButton = 40.0;
  static const searchRadius = 16.0;
  static const cardRadius = 24.0;
  static const tileRadius = 24.0;
  static const heroHeight = 160.0;
  static const iconBadge = 56.0;
  static const badgeFill = Color(0xFFD1DAF4);
  static const surfaceContainer = Color(0xFFF1F3FF);
  static const surfaceContainerHigh = Color(0xFFDCDBE8);
}

/// Optional subtitle keyed only by stable API slug kind. Omit when unknown.
String? commerceVerticalSubtitle(String slug) {
  switch (commerceVerticalKind(slug)) {
    case 'restaurants':
      return AppStrings.categoryRestaurantsSubtitle;
    case 'desserts':
      return AppStrings.categoryDessertsSubtitle;
    case 'bakeries':
      return AppStrings.categoryBakeriesSubtitle;
    case 'groceries':
      return AppStrings.categoryGroceriesSubtitle;
    case 'pharmacies':
      return AppStrings.categoryPharmaciesSubtitle;
    default:
      return null;
  }
}

bool commerceVerticalUsesAccentBadge(String slug) {
  final kind = commerceVerticalKind(slug);
  return kind == 'groceries' || kind == 'supermarkets';
}

({IconData icon, Color background, Color foreground})
commerceVerticalBadgeStyle(CommerceVertical vertical) {
  final base = commerceVerticalStyle(vertical.iconKey, slug: vertical.slug);
  if (commerceVerticalUsesAccentBadge(vertical.slug)) {
    return (
      icon: base.icon,
      background: AppColors.brandGreen,
      foreground: const Color(0xFF111A2F),
    );
  }
  return (
    icon: base.icon,
    background: CategoriesLayout.badgeFill,
    foreground: AppColors.primaryContainer,
  );
}

CommerceVertical? featuredRestaurantsVertical(List<CommerceVertical> items) {
  for (final item in items) {
    if (commerceVerticalKind(item.slug) == 'restaurants') {
      return item;
    }
  }
  return null;
}

List<CommerceVertical> explorerVerticals(List<CommerceVertical> items) {
  final featured = featuredRestaurantsVertical(items);
  if (featured == null) {
    return List<CommerceVertical>.from(items);
  }
  return items.where((item) => item.id != featured.id).toList(growable: false);
}

List<CommerceVertical> filterVerticalsByQuery(
  List<CommerceVertical> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return List<CommerceVertical>.from(items);
  }
  return items
        .where((item) {
          final localized = commerceVerticalDisplayName(item).toLowerCase();
          return localized.contains(q) || item.name.toLowerCase().contains(q);
        })
      .toList(growable: false);
}
