import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_outlined, Icons.home, AppStrings.tabHome),
    (Icons.search_outlined, Icons.search, AppStrings.tabSearch),
    (Icons.receipt_long_outlined, Icons.receipt_long, AppStrings.tabOrders),
    (Icons.notifications_outlined, Icons.notifications, AppStrings.tabAlerts),
    (Icons.person_outline, Icons.person, AppStrings.tabProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: HomeLayout.navHeight + bottom,
      child: Material(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [HomeLayout.navShadow],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottom),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _HomeNavItem(
                      selected: selectedIndex == i,
                      outlined: _items[i].$1,
                      filled: _items[i].$2,
                      label: _items[i].$3,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.selected,
    required this.outlined,
    required this.filled,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData outlined;
  final IconData filled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : AppColors.onSurfaceVariant.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? filled : outlined, color: color, size: 24),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
