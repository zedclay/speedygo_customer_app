import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hours_badge.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_identity.dart';

class StorefrontInfoScreen extends ConsumerWidget {
  const StorefrontInfoScreen({super.key, required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(storefrontDetailProvider(branchId));
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          AppStrings.storefrontInfoScreenTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => CatalogStatusView(
          message: error is AppException
              ? error.message
              : AppStrings.storefrontUnavailable,
          onRetry: () => ref.invalidate(storefrontDetailProvider(branchId)),
        ),
        data: (storefront) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AuthenticatedCatalogImage(
                          imageUrl: storefront.coverImageUrl,
                          fallbackLabel: storefront.branchName,
                          height: 64,
                          width: 64,
                          radius: 8,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storefront.branchName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!isRedundantMerchantName(
                                storefront.branchName,
                                storefront.merchantName,
                              )) ...[
                                const SizedBox(height: 2),
                                Text(
                                  storefront.merchantName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    HoursBadge(hours: storefront.hours),
                  ],
                ),
              ),
              if (storefront.addressText.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.storefrontAddressSection,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storefront.addressText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _HoursSection(storefront: storefront),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _HoursSection extends StatelessWidget {
  const _HoursSection({required this.storefront});

  final StorefrontDetail storefront;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday;
    final statusLabel = !storefront.hours.hoursConfigured
        ? null
        : (storefront.hours.isOpenNow
              ? AppStrings.hoursOpen
              : AppStrings.hoursClosed);
    final statusColor = !storefront.hours.hoursConfigured
        ? AppColors.onSurfaceVariant
        : storefront.hours.isOpenNow
        ? AppColors.tertiary
        : AppColors.error;

    return Material(
      color: AppColors.surfaceContainerLowest,
      elevation: 1,
      shadowColor: const Color(0x0A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.schedule, color: AppColors.primary),
          title: Text(
            AppStrings.openingHoursSection,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: statusLabel == null
              ? null
              : Text(
                  statusLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          children: [
            if (!storefront.hours.hoursConfigured || storefront.days.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.hoursUnconfigured,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < storefront.days.length; i++)
                _DayRow(
                  day: storefront.days[i],
                  isToday: storefront.days[i].dayOfWeek == today,
                  showDivider: i < storefront.days.length - 1,
                ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.isToday,
    required this.showDivider,
  });

  final OpeningDay day;
  final bool isToday;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isToday ? AppColors.primary : AppColors.onSurfaceVariant,
      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
    );
    final hoursStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isToday ? AppColors.primary : AppColors.onSurface,
      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
    );
    final label = isToday
        ? '${weekdayLabel(day.dayOfWeek)} ${AppStrings.hoursTodaySuffix}'
        : weekdayLabel(day.dayOfWeek);
    final hoursText = day.intervals.isEmpty
        ? AppStrings.closedAllDay
        : day.intervals
              .map(
                (interval) =>
                    '${interval.opens} – ${interval.closes}${interval.closesNextDay ? ' +1' : ''}',
              )
              .join('\n');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: dayStyle)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  hoursText,
                  textAlign: TextAlign.end,
                  style: hoursStyle,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
