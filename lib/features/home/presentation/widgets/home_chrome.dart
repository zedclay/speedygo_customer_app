import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';

/// Logical-pixel tokens from `accueil_speedygo/code.html` (390×844 artboard).
class HomeLayout {
  HomeLayout._();

  static const margin = 16.0;
  static const headerHeight = 64.0;
  static const logoSize = 32.0;
  static const searchHeight = 48.0;
  static const searchRadius = 12.0;
  static const cardRadius = 16.0;
  static const liveMediaHeight = 176.0;
  static const previewMediaHeight = 176.0;
  static const navHeight = 80.0;
  static const categorySize = 64.0;
  static const promoHeight = 160.0;
  static const listBottomGap = 48.0;
  static const listBottomGapWithOrder = 120.0;

  static const searchShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const cardShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 12,
    offset: Offset(0, 2),
  );

  /// Active-order overlay — Stitch `shadow-xl` approximation.
  static const activeOrderShadow = BoxShadow(
    color: Color(0x29000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  static const navShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, -2),
  );
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.addressLabel,
    required this.onAddressTap,
    required this.onAlertsTap,
    this.onLogoLongPress,
    this.unreadCount,
  });

  final String addressLabel;
  final VoidCallback onAddressTap;
  final VoidCallback onAlertsTap;
  final VoidCallback? onLogoLongPress;
  final int? unreadCount;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HomeLayout.headerHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
        child: Row(
          children: [
            GestureDetector(
              onLongPress: onLogoLongPress,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/branding/speedygo_logo.png',
                  key: const Key('home-logo'),
                  width: HomeLayout.logoSize,
                  height: HomeLayout.logoSize,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                key: const Key('home-address-chip'),
                onTap: onAddressTap,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.deliverTo.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 16 / 11,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            addressLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 24 / 16,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                key: const Key('home-alerts-bell'),
                tooltip: AppStrings.tabAlerts,
                padding: EdgeInsets.zero,
                onPressed: onAlertsTap,
                icon: Badge(
                  isLabelVisible: (unreadCount ?? 0) > 0,
                  label: Text(
                    (unreadCount ?? 0) > 99 ? '99+' : '${unreadCount ?? 0}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Stitch `accueil_speedygo`: section pt-4, headline mb-4.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeLayout.margin,
        16,
        HomeLayout.margin,
        16,
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          height: 32 / 24,
          color: AppColors.onSurface,
          // Platform color emoji in production. Tests load Noto Color Emoji;
          // do not fall back to monochrome Noto Emoji (wrong hand glyph).
          fontFamilyFallback: const [
            'Apple Color Emoji',
            'Noto Color Emoji',
          ],
        ),
      ),
    );
  }
}

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Stitch: h-12, rounded-xl, border-none, shadow, search icon at left-4 + pl-12.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeLayout.margin,
        0,
        HomeLayout.margin,
        8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(HomeLayout.searchRadius),
          boxShadow: const [HomeLayout.searchShadow],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(HomeLayout.searchRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('home-search-field'),
            onTap: onTap,
            child: SizedBox(
              height: HomeLayout.searchHeight,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeLayout.margin),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 28 / 20,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
