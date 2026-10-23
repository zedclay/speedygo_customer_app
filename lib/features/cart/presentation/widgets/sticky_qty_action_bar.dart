import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/quantity_stepper.dart';

/// Sticky quantity + primary action used on product detail and configure.
/// Stacks on narrow / large-text layouts so action copy is not mid-word wrapped.
class StickyQtyActionBar extends StatelessWidget {
  const StickyQtyActionBar({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
    required this.actionLabel,
    required this.priceLabel,
    required this.onAction,
    required this.actionKey,
    this.quantityKey,
    this.enabled = true,
    this.mutating = false,
    this.showQuantity = true,
  });

  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final String actionLabel;
  final String priceLabel;
  final VoidCallback? onAction;
  final Key actionKey;
  final Key? quantityKey;
  final bool enabled;
  final bool mutating;
  final bool showQuantity;

  static bool shouldStack(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16);
    return MediaQuery.sizeOf(context).width < 390 || scale > 18;
  }

  @override
  Widget build(BuildContext context) {
    // Report measured bottom chrome so [SgSnack] clears body-embedded stickies
    // (configure / product detail) that are not in [Scaffold.bottomNavigationBar].
    return _SgSnackBodyChromeReporter(
      child: Material(
        color: AppColors.surfaceContainerLowest,
        elevation: 8,
        shadowColor: AppColors.primaryContainer.withValues(alpha: 0.12),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Builder(
              builder: (context) {
                final stacked = shouldStack(context);
                final stepper = QuantityStepper(
                  key: quantityKey,
                  quantity: quantity,
                  style: QuantityStepperStyle.bordered,
                  enabled: enabled && !mutating,
                  onChanged: onQuantityChanged,
                );
                final cta = _ActionButton(
                  actionKey: actionKey,
                  label: actionLabel,
                  priceLabel: priceLabel,
                  stacked: stacked && showQuantity,
                  onPressed: onAction,
                );
                if (!showQuantity) {
                  return cta;
                }
                if (stacked) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: stepper),
                      const SizedBox(height: 10),
                      cta,
                    ],
                  );
                }
                return Row(
                  children: [
                    stepper,
                    const SizedBox(width: 12),
                    Expanded(child: cta),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Publishes this bar's on-screen bottom extent to [SgSnack] after layout.
class _SgSnackBodyChromeReporter extends StatefulWidget {
  const _SgSnackBodyChromeReporter({required this.child});

  final Widget child;

  @override
  State<_SgSnackBodyChromeReporter> createState() =>
      _SgSnackBodyChromeReporterState();
}

class _SgSnackBodyChromeReporterState extends State<_SgSnackBodyChromeReporter> {
  final Object _owner = Object();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  @override
  void didUpdateWidget(covariant _SgSnackBodyChromeReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  @override
  void dispose() {
    SgSnack.clearBodyChrome(_owner);
    super.dispose();
  }

  void _publish() {
    if (!mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final top = box.localToGlobal(Offset.zero).dy;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final chrome = (screenHeight - top).clamp(0.0, screenHeight);
    SgSnack.reportBodyChrome(_owner, chrome);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.actionKey,
    required this.label,
    required this.priceLabel,
    required this.stacked,
    required this.onPressed,
  });

  final Key actionKey;
  final String label;
  final String priceLabel;
  final bool stacked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: AppColors.primaryContainer,
      foregroundColor: AppColors.onPrimaryContainer,
      disabledBackgroundColor: AppColors.primaryContainer.withValues(
        alpha: 0.4,
      ),
      disabledForegroundColor: AppColors.onPrimaryContainer.withValues(
        alpha: 0.7,
      ),
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(horizontal: stacked ? 16 : 12),
    );
    return FilledButton(
      key: actionKey,
      style: style,
      onPressed: onPressed,
      child: stacked
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    softWrap: true,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                BidiLtr(
                  child: Text(
                    priceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 1,
                    height: 16,
                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.3),
                  ),
                ),
                BidiLtr(
                  child: Text(
                    priceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
    );
  }
}
