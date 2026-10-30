import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_copy.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';

/// API-backed Home banner. Omitting this widget leaves no empty gap.
class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({
    super.key,
    required this.promotion,
    this.onCopied,
    this.onOpen,
  });

  final DiscoverablePromotion promotion;
  final ValueChanged<String>? onCopied;
  final VoidCallback? onOpen;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: promotion.code));
    onCopied?.call(promotion.code);
    if (!context.mounted) {
      return;
    }
    // Copy-only — information, never success (does not imply promo applied).
    SgSnack.info(context, message: AppStrings.promoCodeCopied);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        child: SizedBox(
          height: HomeLayout.promoHeight,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('home-promo-open'),
                onTap: onOpen,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 16,
                      bottom: 16,
                      child: Icon(
                        Icons.local_shipping_outlined,
                        size: 80,
                        color: Color(0x66FFFFFF),
                        semanticLabel: null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiaryFixed,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    PromotionCopy.label(promotion).toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.tertiary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  PromotionCopy.headline(promotion),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 24,
                                        height: 32 / 24,
                                      ),
                                ),
                                Text(
                                  AppStrings.promoMerchandiseCondition,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 14,
                                        height: 20 / 14,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          promotion.code,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontFamily: AppTheme.fontFamily,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                height: 24 / 16,
                                                letterSpacing: -0.4,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        key: const Key('home-promo-copy'),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: AppStrings.copyPromoCode,
                                        onPressed: () => _copy(context),
                                        icon: Icon(
                                          Icons.content_copy,
                                          size: 20,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
