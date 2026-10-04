import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/features/cart/domain/cart_selection.dart';

enum QuantityStepperStyle {
  /// Soft pill used in dense list rows.
  pill,

  /// Bordered rectangular control matching sticky CTA bars (Stitch).
  bordered,
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
    this.style = QuantityStepperStyle.pill,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool compact;
  final QuantityStepperStyle style;

  @override
  Widget build(BuildContext context) {
    final bordered = style == QuantityStepperStyle.bordered;
    final size = bordered ? 40.0 : (compact ? 28.0 : 40.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bordered
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(bordered ? 12 : 999),
        border: Border.all(
          color: bordered ? AppColors.outline : AppColors.outlineVariant,
        ),
      ),
      child: SizedBox(
        height: bordered ? 56 : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove,
              size: size,
              enabled: enabled && quantity > cartQuantityMin,
              onPressed: () => onChanged(quantity - 1),
              semanticLabel: 'Diminuer la quantité',
            ),
            SizedBox(
              width: compact && !bordered ? 22 : 32,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              size: size,
              enabled: enabled && quantity < cartQuantityMax,
              onPressed: () => onChanged(quantity + 1),
              semanticLabel: 'Augmenter la quantité',
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
      tooltip: semanticLabel,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: size <= 28 ? 16 : 20, color: AppColors.primary),
    );
  }
}
