import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_payment_method.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';

class CheckoutPaymentMethodScreen extends ConsumerWidget {
  const CheckoutPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(checkoutPaymentMethodProvider);
    final availability = ref.watch(electronicPaymentAvailabilityProvider);
    final electronicSelectable =
        CheckoutPaymentMethod.electronic.isSelectable(availability);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          AppStrings.checkoutPaymentTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            AppStrings.checkoutPaymentChoose,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.checkoutPaymentHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _MethodTile(
            key: const Key('checkout-method-cod'),
            icon: Icons.payments_outlined,
            title: AppStrings.checkoutPaymentCod,
            subtitle: AppStrings.checkoutPaymentCodBody,
            selected: selected == CheckoutPaymentMethod.cod,
            prominent: true,
            onTap: () {
              ref
                  .read(checkoutPaymentMethodProvider.notifier)
                  .select(CheckoutPaymentMethod.cod);
              popOrParent(context);
            },
          ),
          const SizedBox(height: 16),
          _MethodTile(
            key: const Key('checkout-method-electronic'),
            icon: Icons.credit_card,
            title: AppStrings.checkoutPaymentElectronic,
            subtitle: electronicSelectable
                ? (selected == CheckoutPaymentMethod.electronic
                      ? AppStrings.checkoutPaymentSelected
                      : AppStrings.checkoutPaymentElectronicHint)
                : AppStrings.checkoutPaymentElectronicSoon,
            selected: selected == CheckoutPaymentMethod.electronic &&
                electronicSelectable,
            enabled: electronicSelectable,
            onTap: electronicSelectable
                ? () {
                    ref
                        .read(checkoutPaymentMethodProvider.notifier)
                        .select(CheckoutPaymentMethod.electronic);
                    popOrParent(context);
                  }
                : null,
          ),
          const SizedBox(height: 32),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.tertiaryFixed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock,
                    size: 16,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.checkoutPaymentSecurityNote,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.tertiary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: FilledButton.icon(
              key: const Key('checkout-method-back'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => popOrParent(context),
              icon: const Icon(Icons.arrow_forward),
              label: const Text(AppStrings.checkoutContinue),
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.onTap,
    this.enabled = true,
    this.prominent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : AppColors.outlineVariant.withValues(alpha: 0.5);
    final iconBg = selected || prominent
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.surfaceContainer;
    final iconColor =
        selected || prominent ? AppColors.primary : AppColors.onSurfaceVariant;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceContainerLow
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 28, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _RadioDot(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
