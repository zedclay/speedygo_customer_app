import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';

/// Star chrome aligned to Stitch `noter_la_commande_speedygo`.
class StarRatingBar extends StatelessWidget {
  const StarRatingBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.size = 40,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var score = 1; score <= 5; score++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: IconButton(
              key: Key('rating-star-$score'),
              onPressed: enabled ? () => onChanged(score) : null,
              iconSize: size,
              padding: const EdgeInsets.all(4),
              constraints: BoxConstraints(
                minWidth: size + 8,
                minHeight: size + 8,
              ),
              splashRadius: size * 0.7,
              icon: Icon(
                (value ?? 0) >= score ? Icons.star_rounded : Icons.star_outline_rounded,
                color: (value ?? 0) >= score
                    ? AppColors.tertiaryFixedDim
                    : AppColors.outlineVariant,
              ),
            ),
          ),
      ],
    );
  }
}
