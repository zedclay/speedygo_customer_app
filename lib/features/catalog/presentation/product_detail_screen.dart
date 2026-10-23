import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/money/money_calc.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/cart/domain/cart_selection.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/sticky_qty_action_bar.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hero_overlay_button.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.branchId,
    required this.productId,
  });

  final String branchId;
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  var _quantity = cartQuantityMin;

  @override
  Widget build(BuildContext context) {
    if (!CatalogIds.isLiveUuid(widget.branchId) ||
        !CatalogIds.isLiveUuid(widget.productId)) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: AppStrings.back,
            onPressed: () => popOrParent(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: CatalogStatusView(message: AppStrings.productUnavailable),
      );
    }

    final args = ProductDetailArgs(
      branchId: widget.branchId,
      productId: widget.productId,
    );
    final detail = ref.watch(productDetailProvider(args));
    final cart = ref.watch(cartControllerProvider);
    final storefront = ref.watch(storefrontDetailProvider(widget.branchId));
    final branchName = storefront.asData?.value.branchName;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: AppStrings.back,
              onPressed: () => popOrParent(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: CatalogStatusView(
            message: error is AppException
                ? error.message
                : AppStrings.productUnavailable,
            onRetry: () => ref.invalidate(productDetailProvider(args)),
          ),
        ),
        data: (product) {
          final theme = Theme.of(context);
          final size = MediaQuery.sizeOf(context);
          final stackedCta = StickyQtyActionBar.shouldStack(context);
          final reservedCta = stackedCta ? 168.0 : 96.0;
          final maxHero = size.height - reservedCta - 318;
          var heroHeight = size.height * 0.45;
          if (maxHero < heroHeight) {
            heroHeight = maxHero;
          }
          if (heroHeight < 160) {
            heroHeight = 160;
          }
          final needsConfig = product.optionGroups.isNotEmpty;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: heroHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AuthenticatedCatalogImage(
                              imageUrl: product.imageUrl,
                              fallbackLabel: product.name,
                              height: heroHeight,
                              radius: 0,
                              icon: Icons.lunch_dining_outlined,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x66000000),
                                    Color(0x00000000),
                                    Color(0x00000000),
                                    Color(0x80000000),
                                  ],
                                  stops: [0, 0.25, 0.7, 1],
                                ),
                              ),
                            ),
                            HeroOverlayBar(
                              leading: HeroOverlayButton(
                                tooltip: AppStrings.back,
                                icon: Icons.arrow_back,
                                onPressed: () => popOrParent(context),
                              ),
                              actions: [
                                Badge(
                                  isLabelVisible: cart.badgeCount > 0,
                                  label: Text('${cart.badgeCount}'),
                                  backgroundColor: AppColors.primary,
                                  child: HeroOverlayButton(
                                    tooltip: AppStrings.cartTitle,
                                    icon: Icons.shopping_basket_outlined,
                                    onPressed: () =>
                                        context.push(AppRoutes.cart),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(32),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProductIdentity(
                              name: product.name,
                              branchName: branchName,
                              priceLabel: MoneyFormat.dzd(product.priceMinor),
                              stacked: stackedCta,
                            ),
                            if (product.description != null &&
                                product.description!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                AppStrings.productDescriptionHeading,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            if (needsConfig) ...[
                              const SizedBox(height: 24),
                              Material(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  key: const Key('product-customize-card'),
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    context.push(
                                      AppRoutes.productConfigureInBranch(
                                        widget.branchId,
                                        widget.productId,
                                        quantity: _quantity,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.tune,
                                            color:
                                                AppColors.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppStrings
                                                    .customizeProductCardTitle,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              Text(
                                                AppStrings.customizeProductHint,
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: AppColors.outline,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StickyQtyActionBar(
                quantity: _quantity,
                onQuantityChanged: (value) {
                  setState(() => _quantity = value);
                },
                quantityKey: const Key('detail-quantity'),
                actionLabel: needsConfig
                    ? AppStrings.customizeProduct
                    : (cart.mutating
                          ? AppStrings.addingToCart
                          : AppStrings.addToCart),
                priceLabel: needsConfig
                    ? MoneyFormat.dzd(product.priceMinor)
                    : MoneyFormat.dzd(
                        MoneyCalc.times(product.priceMinor, _quantity),
                      ),
                actionKey: Key(
                  needsConfig
                      ? 'customize-product-button'
                      : 'add-to-cart-button',
                ),
                enabled: !cart.mutating,
                mutating: cart.mutating,
                onAction: needsConfig
                    ? () {
                        context.push(
                          AppRoutes.productConfigureInBranch(
                            widget.branchId,
                            widget.productId,
                            quantity: _quantity,
                          ),
                        );
                      }
                    : (cart.mutating ? null : () => _addPlain(product)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addPlain(CatalogProductDetail product) async {
    final added = await ref
        .read(cartControllerProvider.notifier)
        .addItem(
          AddCartItemRequest(productId: product.productId, quantity: _quantity),
        );
    if (!mounted) {
      return;
    }
    if (!added) {
      final error = ref.read(cartControllerProvider).actionError;
      if (error == AppStrings.cartBranchConflict) {
        final go = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppStrings.cartTitle),
              content: Text(AppStrings.cartBranchConflict),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppStrings.cartKeepExisting),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppStrings.cartGoToExisting),
                ),
              ],
            );
          },
        );
        if (go == true && mounted) {
          await context.push(AppRoutes.cart);
        }
      } else if (error != null && mounted) {
        // Recoverable / uncertain — never success. No inline banner on detail.
        SgSnack.warning(context, message: error);
      }
      return;
    }
    SgSnack.success(
      context,
      message: AppStrings.cartAdded,
      actionLabel: AppStrings.viewCart,
      onAction: () {
        if (!context.mounted) {
          return;
        }
        context.push(AppRoutes.cart);
      },
    );
  }
}

class _ProductIdentity extends StatelessWidget {
  const _ProductIdentity({
    required this.name,
    required this.priceLabel,
    required this.stacked,
    this.branchName,
  });

  final String name;
  final String priceLabel;
  final bool stacked;
  final String? branchName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameText = Text(
      name,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      ),
    );
    final merchant = branchName != null && branchName!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    branchName!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
    final priceCol = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        BidiLtr(
          child: Text(
            priceLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              height: 32 / 24,
            ),
          ),
        ),
        Text(
          AppStrings.perPortion.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nameText,
          merchant,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: priceCol),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [nameText, merchant],
          ),
        ),
        const SizedBox(width: 12),
        priceCol,
      ],
    );
  }
}
