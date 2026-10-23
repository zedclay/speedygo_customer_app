import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';

/// Maps API `iconKey` aliases (and optional slug) onto Stitch tile tokens.
String resolvedCommerceIconKey(String iconKey, {String? slug}) {
  switch (iconKey) {
    case 'bakery_dining':
    case 'local_mall':
    case 'medical_services':
    case 'icecream':
    case 'restaurant':
      return iconKey;
    case 'grocery':
    case 'local_grocery_store':
    case 'shopping_basket':
      return 'local_mall';
    case 'pharmacy':
    case 'local_pharmacy':
      return 'medical_services';
    case 'cake':
      return 'icecream';
    case 'store':
      return 'local_mall';
  }
  switch (slug) {
    case 'bakeries':
    case 'boulangeries':
      return 'bakery_dining';
    case 'groceries':
    case 'epiceries':
    case 'supermarkets':
      return 'local_mall';
    case 'pharmacies':
      return 'medical_services';
    case 'desserts':
      return 'icecream';
    case 'restaurants':
      return 'restaurant';
    default:
      return 'restaurant';
  }
}

/// Home/category labels keyed by stable API slug. Unknown kinds keep the API name.
String commerceVerticalDisplayName(CommerceVertical vertical) {
  final slug = vertical.slug.trim().toLowerCase();
  if (slug == 'restaurants' || slug.endsWith('-restaurants')) {
    return AppStrings.categoryRestaurants;
  }
  if (slug == 'desserts' || slug.endsWith('-desserts')) {
    return AppStrings.categoryDesserts;
  }
  if (slug == 'bakeries' ||
      slug == 'boulangeries' ||
      slug.endsWith('-bakeries') ||
      slug.endsWith('-boulangeries')) {
    return AppStrings.categoryBakeries;
  }
  if (slug == 'groceries' ||
      slug == 'epiceries' ||
      slug.endsWith('-groceries') ||
      slug.endsWith('-epiceries')) {
    return AppStrings.categoryGroceries;
  }
  if (slug == 'pharmacies' || slug.endsWith('-pharmacies')) {
    return AppStrings.categoryPharmacies;
  }
  return vertical.name;
}

({IconData icon, Color background, Color foreground}) commerceVerticalStyle(
  String iconKey, {
  String? slug,
}) {
  switch (resolvedCommerceIconKey(iconKey, slug: slug)) {
    case 'bakery_dining':
      return (
        icon: Icons.bakery_dining,
        background: const Color(0xFFE8F5E9),
        foreground: const Color(0xFF2E7D32),
      );
    case 'local_mall':
      return (
        icon: Icons.local_mall,
        background: const Color(0xFFFFF3E0),
        foreground: const Color(0xFFEF6C00),
      );
    case 'medical_services':
      return (
        icon: Icons.medical_services,
        background: const Color(0xFFF3E5F5),
        foreground: const Color(0xFF7B1FA2),
      );
    case 'icecream':
      return (
        icon: Icons.icecream,
        background: const Color(0xFFE1F5FE),
        foreground: const Color(0xFF0288D1),
      );
    case 'restaurant':
    default:
      return (
        icon: Icons.restaurant,
        background: const Color(0x1A0A4096),
        foreground: AppColors.primary,
      );
  }
}

class HomeCategoryStrip extends StatelessWidget {
  const HomeCategoryStrip({
    super.key,
    required this.verticals,
    required this.selectedId,
    required this.onSelected,
    required this.onSeeAll,
  });

  final List<CommerceVertical> verticals;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (verticals.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          title: AppStrings.categories,
          trailing: TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              AppStrings.seeAll,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
            itemCount: verticals.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final vertical = verticals[index];
              final selected = vertical.id == selectedId;
              final style = commerceVerticalStyle(
                vertical.iconKey,
                slug: vertical.slug,
              );
              return SizedBox(
                width: 72,
                child: InkWell(
                  onTap: () => onSelected(selected ? null : vertical.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Container(
                        width: HomeLayout.categorySize,
                        height: HomeLayout.categorySize,
                        decoration: BoxDecoration(
                          color: style.background,
                          borderRadius: BorderRadius.circular(16),
                          border: selected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          style.icon,
                          color: style.foreground,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: Text(
                            commerceVerticalDisplayName(vertical),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: selected
                                      ? AppColors.onSurface
                                      : AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
