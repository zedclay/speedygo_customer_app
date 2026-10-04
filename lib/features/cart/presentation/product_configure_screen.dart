import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/cart/domain/cart_selection.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/cart_badge_button.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/quantity_stepper.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/sticky_qty_action_bar.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';

class ProductConfigureScreen extends ConsumerStatefulWidget {
  const ProductConfigureScreen({
    super.key,
    required this.branchId,
    required this.productId,
    this.initialQuantity = cartQuantityMin,
  });

  final String branchId;
  final String productId;
  final int initialQuantity;

  @override
  ConsumerState<ProductConfigureScreen> createState() =>
      _ProductConfigureScreenState();
}

class _ProductConfigureScreenState
    extends ConsumerState<ProductConfigureScreen> {
  late ProductConfigDraft _draft = emptyProductConfig(
    quantity: widget.initialQuantity,
  );

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
        body: const CatalogStatusView(message: AppStrings.productUnavailable),
      );
    }

    final args = ProductDetailArgs(
      branchId: widget.branchId,
      productId: widget.productId,
    );
    final detail = ref.watch(productDetailProvider(args));
    final storefront = ref.watch(storefrontDetailProvider(widget.branchId));
    final cart = ref.watch(cartControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(AppStrings.customizeTitle),
        actions: const [CartBadgeButton()],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => CatalogStatusView(
          message: error is AppException
              ? error.message
              : AppStrings.productUnavailable,
          onRetry: () => ref.invalidate(productDetailProvider(args)),
        ),
        data: (product) {
          final valid = isProductConfigValid(product, _draft);
          final estimate = estimateLineMinor(product, _draft);
          final merchantName = storefront.asData?.value.branchName;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _summaryCard(
                      context,
                      product,
                      merchantName,
                      mutating: cart.mutating,
                    ),
                    for (final group in product.optionGroups) ...[
                      const SizedBox(height: 24),
                      _groupHeader(context, group),
                      const SizedBox(height: 8),
                      for (final option in group.options)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _optionTile(context, product, group, option),
                        ),
                    ],
                  ],
                ),
              ),
              if (cart.actionError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    cart.actionError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
              StickyQtyActionBar(
                quantity: _draft.quantity,
                onQuantityChanged: (value) {
                  setState(() {
                    _draft = changeQuantity(_draft, value);
                  });
                },
                showQuantity: false,
                actionLabel: cart.mutating
                    ? (cart.reconciling
                          ? AppStrings.cartReconciling
                          : AppStrings.addingToCart)
                    : AppStrings.addToCart,
                priceLabel: MoneyFormat.dzd(estimate),
                actionKey: const Key('add-to-cart-button'),
                enabled: valid,
                mutating: cart.mutating,
                onAction: valid && !cart.mutating
                    ? () => _submit(product)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    CatalogProductDetail product,
    String? merchantName, {
    required bool mutating,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A001946),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AuthenticatedCatalogImage(
              imageUrl: product.imageUrl,
              fallbackLabel: product.name,
              height: 80,
              width: 80,
              radius: 8,
              icon: Icons.lunch_dining_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (merchantName != null && merchantName.isNotEmpty)
                    Text(
                      merchantName,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          MoneyFormat.dzd(product.priceMinor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      QuantityStepper(
                        key: const Key('configure-quantity'),
                        quantity: _draft.quantity,
                        compact: true,
                        style: QuantityStepperStyle.bordered,
                        enabled: !mutating,
                        onChanged: (value) {
                          setState(() {
                            _draft = changeQuantity(_draft, value);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(BuildContext context, CatalogOptionGroup group) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                AppStrings.optionSelectCount(
                  group.minSelections,
                  group.maxSelections,
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: group.required
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            group.required
                ? AppStrings.optionRequired.toUpperCase()
                : AppStrings.optionOptional.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _optionTile(
    BuildContext context,
    CatalogProductDetail product,
    CatalogOptionGroup group,
    CatalogProductOption option,
  ) {
    final selected =
        _draft.selectedByGroup[group.optionGroupId]?.contains(
          option.optionId,
        ) ??
        false;
    final extra = option.additionalPriceMinor == '0'
        ? MoneyFormat.dzd(option.additionalPriceMinor)
        : '+${MoneyFormat.dzd(option.additionalPriceMinor)}';
    return Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.16)
          : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: Key('option-${option.optionId}'),
        onTap: option.available
            ? () {
                setState(() {
                  _draft = toggleOption(product, _draft, option.optionId);
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                group.maxSelections <= 1
                    ? (selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off)
                    : (selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
                color: option.available ? AppColors.primary : AppColors.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.name),
                    if (!option.available)
                      const Text(AppStrings.optionUnavailable),
                  ],
                ),
              ),
              Text(
                extra,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(CatalogProductDetail product) async {
    if (!isProductConfigValid(product, _draft)) {
      return;
    }
    final added = await ref
        .read(cartControllerProvider.notifier)
        .addItem(
          AddCartItemRequest(
            productId: product.productId,
            quantity: _draft.quantity,
            optionIds: _draft.optionIds,
          ),
        );
    if (!mounted) {
      return;
    }
    if (!added) {
      final code = ref.read(cartControllerProvider).actionError;
      if (code == AppStrings.cartBranchConflict) {
        await _showBranchConflict();
      }
      // Persistent actionError remains inline above the sticky CTA.
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

  Future<void> _showBranchConflict() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.cartTitle),
          content: const Text(AppStrings.cartBranchConflict),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cartKeepExisting),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.cartGoToExisting),
            ),
          ],
        );
      },
    );
    if (go == true && mounted) {
      await context.push(AppRoutes.cart);
    }
  }
}
