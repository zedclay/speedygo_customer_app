import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

class HoursBadge extends StatelessWidget {
  const HoursBadge({super.key, required this.hours});

  final StorefrontHours hours;

  @override
  Widget build(BuildContext context) {
    final label = hoursLabel(hours);
    final color = !hours.hoursConfigured
        ? AppColors.onSurfaceVariant
        : hours.isOpenNow
        ? AppColors.primary
        : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: hours.isOpenNow ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 16 / 12,
        ),
      ),
    );
  }
}

String hoursLabel(StorefrontHours hours) {
  if (!hours.hoursConfigured) {
    return AppStrings.hoursUnconfigured;
  }
  if (hours.isOpenNow) {
    final closes = hours.currentClosesAt;
    if (closes != null) {
      return '${AppStrings.hoursOpen} · ${AppStrings.hoursClosesAt} ${_hm(closes)}';
    }
    return AppStrings.hoursOpen;
  }
  final next = hours.nextOpenAt;
  if (next != null) {
    return '${AppStrings.hoursClosed} · ${AppStrings.hoursOpensAt} ${_hm(next)}';
  }
  return AppStrings.hoursClosed;
}

String weekdayLabel(int isoDay) {
  switch (isoDay) {
    case 1:
      return AppStrings.weekdayMonday;
    case 2:
      return AppStrings.weekdayTuesday;
    case 3:
      return AppStrings.weekdayWednesday;
    case 4:
      return AppStrings.weekdayThursday;
    case 5:
      return AppStrings.weekdayFriday;
    case 6:
      return AppStrings.weekdaySaturday;
    case 7:
      return AppStrings.weekdaySunday;
    default:
      return '';
  }
}

String _hm(DateTime value) {
  final local = value.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
