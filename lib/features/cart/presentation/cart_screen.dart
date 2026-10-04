import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/quantity_stepper.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(AppStrings.cartTitle),
        actions: [
          if (cart.cartExists)
            TextButton(
              onPressed: cart.mutating
                  ? null
                  : () => _confirmClear(context, ref),
              child: const Text(AppStrings.clearCart),
            ),
        ],
      ),
      body: _body(context, ref, cart),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CartUiState cart) {
    if (cart.loading && !cart.cartExists) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cart.error != null && !cart.cartExists) {
      return CatalogStatusView(
        message: cart.error!,
        onRetry: () => ref.read(cartControllerProvider.notifier).refresh(),
      );
    }
    final current = cart.cart;
    if (current == null || current.items.isEmpty) {
      return CatalogStatusView(
        message: AppStrings.cartEmpty,
        onRetry: () => ref.read(cartControllerProvider.notifier).refresh(),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _merchantHeader(context, ref, current),
              const SizedBox(height: 16),
              for (final item in current.items) ...[
                _itemCard(context, ref, current, item, cart.mutating),
                const SizedBox(height: 12),
              ],
              TextButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.merchant(current.branchId)),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(AppStrings.addAnotherItem),
              ),
              const SizedBox(height: 8),
              _subtotalCard(context, current),
              if (!current.cartReady) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.cartNotReady,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.error),
                ),
              ],
              if (cart.actionError != null) ...[
                const SizedBox(height: 8),
                Text(
                  cart.actionError!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: const Key('checkout-review-cta'),
                  onPressed: cart.mutating || !current.cartReady
                      ? null
                      : () => context.push(AppRoutes.checkoutReview),
                  child: const Text(AppStrings.checkoutAction),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _merchantHeader(
    BuildContext context,
    WidgetRef ref,
    CustomerCart cart,
  ) {
    final storefront = ref.watch(storefrontDetailProvider(cart.branchId));
    final name = storefront.asData?.value.branchName;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.restaurant,
            color: AppColors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.orderFrom,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              Text(
                name == null || name.isEmpty ? AppStrings.cartTitle : name,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemCard(
    BuildContext context,
    WidgetRef ref,
    CustomerCart cart,
    CartItem item,
    bool mutating,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthenticatedCatalogImage(
              imageUrl: cartItemImageUrl(
                branchId: cart.branchId,
                productId: item.productId,
              ),
              fallbackLabel: item.productName,
              height: 72,
              width: 72,
              radius: 8,
              icon: Icons.lunch_dining_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        MoneyFormat.dzd(item.lineSubtotalMinor),
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  for (final option in item.selectedOptions)
                    Text(
                      _optionLine(option),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  if (!item.itemAvailable)
                    const Text(
                      AppStrings.cartItemUnavailable,
                      style: TextStyle(color: AppColors.error),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        key: Key('remove-cart-item-${item.id}'),
                        onPressed: mutating
                            ? null
                            : () => ref
                                  .read(cartControllerProvider.notifier)
                                  .removeItem(item.id),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(AppStrings.removeFromCart),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                      QuantityStepper(
                        key: Key('cart-qty-${item.id}'),
                        quantity: item.quantity,
                        compact: true,
                        enabled: !mutating,
                        onChanged: (value) {
                          ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(
                                cartItemId: item.id,
                                quantity: value,
                              );
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

  Widget _subtotalCard(BuildContext context, CustomerCart cart) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.cartOrderSummary,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text(AppStrings.cartMerchandiseSubtotal)),
                Text(
                  MoneyFormat.dzd(cart.cartSubtotalMinor),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.cartSubtotalHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _optionLine(CartSelectedOption option) {
    final name = option.name ?? option.optionId;
    if (option.additionalPriceMinor == '0') {
      return name;
    }
    return '$name (+${MoneyFormat.dzd(option.additionalPriceMinor)})';
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.clearCartConfirmTitle),
          content: const Text(AppStrings.clearCartConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.clearCart),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(cartControllerProvider.notifier).clearCart();
    }
  }
}
