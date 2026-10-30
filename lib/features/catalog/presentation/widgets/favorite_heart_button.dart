import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';

class FavoriteHeartButton extends StatelessWidget {
  const FavoriteHeartButton({
    super.key,
    required this.saved,
    required this.onPressed,
    this.light = true,
  });

  final bool saved;
  final VoidCallback? onPressed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light ? Colors.white.withValues(alpha: 0.92) : AppColors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: saved ? const Color(0xFFE11D48) : AppColors.primary,
            size: 22,
            semanticLabel: AppStrings.favoritesTitle,
          ),
        ),
      ),
    );
  }
}
