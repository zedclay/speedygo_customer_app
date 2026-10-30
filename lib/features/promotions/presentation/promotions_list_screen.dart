import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/discovery_overlay.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_copy.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_providers.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';

enum _PromoChip { all, fixed, percent }

/// Discoverable offers from GET /customer/promotions.
/// Does not apply codes — checkout remains discount authority.
///
/// Stitch chips "Livraison / Restaurants / Codes promo" are not mapped:
/// Promotion is GLOBAL (no merchant/branch/category/free-delivery scope).
/// Filters here are the engine's real discount kinds: Tout / Montant / Pourcentage.
class PromotionsListScreen extends ConsumerStatefulWidget {
  const PromotionsListScreen({super.key});

  @override
  ConsumerState<PromotionsListScreen> createState() =>
      _PromotionsListScreenState();
}

class _PromotionsListScreenState extends ConsumerState<PromotionsListScreen> {
  _PromoChip _chip = _PromoChip.all;

  String _locationLabel() {
    return homeAddressLabel(
      book: ref.watch(addressBookProvider),
      selection: ref.watch(addressSelectionProvider),
      sessionFallback: ref.watch(sessionControllerProvider).customer?.deliverToLabel,
    );
  }

  List<DiscoverablePromotion> _filtered(List<DiscoverablePromotion> items) {
    switch (_chip) {
      case _PromoChip.all:
        return items;
      case _PromoChip.fixed:
        return [
          for (final item in items)
            if (item.discountKind == PromotionDiscountKind.fixedMinor) item,
        ];
      case _PromoChip.percent:
        return [
          for (final item in items)
            if (item.discountKind == PromotionDiscountKind.rateBps) item,
        ];
    }
  }

  Future<void> _copy(DiscoverablePromotion offer) async {
    await Clipboard.setData(ClipboardData(text: offer.code));
    if (!mounted) {
      return;
    }
    SgSnack.info(context, message: AppStrings.promoCodeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(discoverablePromotionsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppStrings.promotionsTitle),
      ),
      body: DiscoveryOverlay(
        child: offers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is AppException
                        ? error.message
                        : AppStrings.catalogLoadError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(discoverablePromotionsProvider),
                    child: Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Text(AppStrings.promotionsEmpty));
            }
            final filtered = _filtered(items);
            final active = [
              for (final item in filtered)
                if (!PromotionCopy.isExpired(item)) item,
            ];
            final expired = [
              for (final item in filtered)
                if (PromotionCopy.isExpired(item)) item,
            ];
            final featured = active.isNotEmpty ? active.first : null;
            final compact = [
              if (featured != null) ...active.skip(1) else ...active,
            ];
            return ListView(
              padding: EdgeInsets.fromLTRB(
                HomeLayout.margin,
                8,
                HomeLayout.margin,
                discoveryListBottomPadding(ref),
              ),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _locationLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      label: AppStrings.promotionsAll,
                      selected: _chip == _PromoChip.all,
                      onTap: () => setState(() => _chip = _PromoChip.all),
                    ),
                    _Chip(
                      label: AppStrings.promotionsFixedChip,
                      selected: _chip == _PromoChip.fixed,
                      onTap: () => setState(() => _chip = _PromoChip.fixed),
                    ),
                    _Chip(
                      label: AppStrings.promotionsPercentChip,
                      selected: _chip == _PromoChip.percent,
                      onTap: () => setState(() => _chip = _PromoChip.percent),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.promotionsCheckoutHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (filtered.isEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    AppStrings.promotionsEmpty,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (featured != null) ...[
                  const SizedBox(height: 16),
                  _FeaturedCard(
                    offer: featured,
                    onCopy: () => _copy(featured),
                    onSeeCommerces: () => context.go(AppRoutes.home),
                  ),
                ],
                for (final offer in compact) ...[
                  const SizedBox(height: 12),
                  if (offer.hasMerchantAssociation)
                    _MerchantCard(
                      offer: offer,
                      onOpenMenu: () =>
                          context.push(AppRoutes.merchant(offer.branchId!)),
                    )
                  else
                    _CompactCard(
                      offer: offer,
                      onCopy: () => _copy(offer),
                      onSeeCommerces: () => context.go(AppRoutes.home),
                    ),
                ],
                for (final offer in expired) ...[
                  const SizedBox(height: 12),
                  _CompactCard(
                    offer: offer,
                    expired: true,
                    onCopy: () => _copy(offer),
                    onSeeCommerces: () => context.go(AppRoutes.home),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: Key('promo-chip-$label'),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surfaceContainerLowest,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.outlineVariant,
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.offer,
    required this.onCopy,
    required this.onSeeCommerces,
  });

  final DiscoverablePromotion offer;
  final VoidCallback onCopy;
  final VoidCallback onSeeCommerces;

  @override
  Widget build(BuildContext context) {
    final expiry = PromotionCopy.expiryDate(offer);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        boxShadow: const [HomeLayout.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(HomeLayout.cardRadius),
            ),
            child: SizedBox(
              height: HomeLayout.liveMediaHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (offer.coverImageUrl != null)
                    AuthenticatedCoverImage(
                      coverImageUrl: offer.coverImageUrl,
                      fallbackLabel: offer.code,
                      height: HomeLayout.liveMediaHeight,
                    )
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            size: 72,
                            color: Color(0x66FFFFFF),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        PromotionCopy.label(offer).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PromotionCopy.headline(offer),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _promoCondition(offer),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (expiry.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.promotionsExpiresOn(expiry),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  AppStrings.promoCodeHeading,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Text(
                    offer.code,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: Key('promo-copy-${offer.id}'),
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: Text(AppStrings.copyAction),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onSeeCommerces,
                    child: Text(AppStrings.promotionsSeeCommerces),
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

class _CompactCard extends StatelessWidget {
  const _CompactCard({
    required this.offer,
    required this.onCopy,
    required this.onSeeCommerces,
    this.expired = false,
  });

  final DiscoverablePromotion offer;
  final VoidCallback onCopy;
  final VoidCallback onSeeCommerces;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [HomeLayout.searchShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PromotionCopy.headline(offer),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        offer.code,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.copyPromoCode,
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy_outlined),
                ),
              ],
            ),
            if (expired) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.promotionsExpired,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.error),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onSeeCommerces,
                child: Text(AppStrings.promotionsSeeCommerces),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.offer, required this.onOpenMenu});

  final DiscoverablePromotion offer;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [HomeLayout.searchShadow],
      ),
      child: InkWell(
        onTap: onOpenMenu,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 112,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: AuthenticatedCoverImage(
                    coverImageUrl: offer.coverImageUrl,
                    fallbackLabel: offer.merchantName ?? offer.code,
                    height: 140,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.merchantName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        PromotionCopy.headline(offer),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _promoCondition(offer),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onOpenMenu,
                          child: Text(AppStrings.promotionsSeeMenu),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _promoCondition(DiscoverablePromotion offer) {
  final min = offer.minSpendMinor;
  if (min != null && min.isNotEmpty) {
    return AppStrings.promotionsMinSpend(MoneyFormat.dzd(min));
  }
  return AppStrings.promoMerchandiseCondition;
}
