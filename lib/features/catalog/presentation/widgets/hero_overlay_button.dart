import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';

/// Circular frosted control for image heroes (Stitch overlay chrome).
class HeroOverlayButton extends StatelessWidget {
  const HeroOverlayButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.foreground = Colors.white,
    this.background = const Color(0x33FFFFFF),
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: foreground),
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: Colors.transparent,
          fixedSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Top-of-hero overlay matching Stitch `fixed top-0 h-16`.
/// Must be [Positioned] — a loose [SafeArea] inside an expanding [Stack]
/// vertically centers the controls in the image.
class HeroOverlayBar extends StatelessWidget {
  const HeroOverlayBar({
    super.key,
    required this.leading,
    this.actions = const [],
  });

  final Widget leading;
  final List<Widget> actions;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leading,
                const Spacer(),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Solid surface variant used after the hero scrolls away / on light bars.
class SurfaceCircleIconButton extends StatelessWidget {
  const SurfaceCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return HeroOverlayButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      foreground: AppColors.onSurface,
      background: AppColors.surfaceContainerLow,
    );
  }
}
