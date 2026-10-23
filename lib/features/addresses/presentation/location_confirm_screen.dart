import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

/// Location confirm chrome aligned to Stitch `confirmation_de_l_emplacement_speedygo`.
/// No map provider — honest GPS coordinates only (D).
class LocationConfirmScreen extends ConsumerWidget {
  const LocationConfirmScreen({super.key, this.fix});

  final DeviceLocation? fix;

  static const _secondaryContainer = Color(0xFF94A6FF);
  static const _onSecondaryContainer = Color(0xFF24388B);

  static const _sheetShadow = BoxShadow(
    color: Color(0x290A4096),
    blurRadius: 12,
    offset: Offset(0, -4),
  );

  static const _pinShadow = BoxShadow(
    color: Color(0x140A4096),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = fix;
    final customerName =
        ref.watch(sessionControllerProvider).customer?.displayName?.trim();
    final coordsLabel = location == null
        ? AppStrings.confirmLocationCoordsFallback
        : AppStrings.gpsPointObtained;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerHigh,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x14000000),
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          AppStrings.confirmLocationTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 24 / 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Soft stand-in for Stitch map canvas — no map provider configured.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.surfaceContainerHigh,
                    AppColors.secondary.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [_pinShadow],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.onBackground.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom sheet
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [_sheetShadow],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      12,
                      24,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.outlineVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.onPrimaryContainer,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coordsLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20,
                                          height: 28 / 20,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.confirmLocationBody,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 14,
                                          height: 20 / 14,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.locationNotAMap,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                  if (location != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      key: const Key('confirm-latitude'),
                                      AppStrings.addressPointConfirmed,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const Offstage(
                                      offstage: true,
                                      child: Text(
                                        key: Key('confirm-longitude'),
                                        'lng',
                                      ),
                                    ),
                                  ] else
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        AppStrings.locationUnavailable,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.error,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: _secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: _onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (customerName != null &&
                                        customerName.isNotEmpty)
                                      Text(
                                        AppStrings.confirmLocationClientLabel(
                                          customerName,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                              fontSize: 12,
                                              height: 16 / 12,
                                            ),
                                      ),
                                    Text(
                                      AppStrings.confirmLocationPrecisionNote,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 14,
                                            height: 20 / 14,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SgPrimaryButton(
                          key: const Key('confirm-location-button'),
                          label: AppStrings.confirmLocationAction,
                          icon: Icons.chevron_right,
                          onPressed: location == null
                              ? null
                              : () {
                                  ref
                                      .read(pendingLocationFixProvider.notifier)
                                      .set(location);
                                  context.pop(true);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
