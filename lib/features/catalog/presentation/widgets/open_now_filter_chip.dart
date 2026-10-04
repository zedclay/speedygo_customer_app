import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';

/// Compact “Ouverts maintenant” chip shared by Home and category results.
class OpenNowFilterChip extends ConsumerWidget {
  const OpenNowFilterChip({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(openNowFilterProvider);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilterChip(
          key: const Key('open-now-filter'),
          label: const Text(AppStrings.storefrontsOpenNow),
          selected: selected,
          showCheckmark: true,
          checkmarkColor: AppColors.primary,
          selectedColor: AppColors.primaryContainer,
          backgroundColor: AppColors.surfaceContainerLowest,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
          labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          onSelected: (value) {
            ref.read(openNowFilterProvider.notifier).setEnabled(value);
          },
        ),
      ),
    );
  }
}
