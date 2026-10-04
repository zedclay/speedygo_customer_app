import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_controller.dart';
import 'package:speedygo_customer_app/features/checkout/application/checkout_payment_method.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';
import 'package:speedygo_customer_app/features/checkout/application/order_submission_controller.dart';
import 'package:speedygo_customer_app/features/checkout/domain/checkout_address.dart';
import 'package:speedygo_customer_app/features/orders/application/last_created_order.dart';

class CheckoutReviewScreen extends ConsumerStatefulWidget {
  const CheckoutReviewScreen({super.key});

  @override
  ConsumerState<CheckoutReviewScreen> createState() =>
      _CheckoutReviewScreenState();
}

class _CheckoutReviewScreenState extends ConsumerState<CheckoutReviewScreen> {
  final _promo = TextEditingController();

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final order = await ref.read(orderSubmissionControllerProvider.notifier).submit();
    if (!mounted || order == null) {
      return;
    }
    ref.read(lastCreatedOrderProvider.notifier).set(order);
    ref.read(orderSubmissionControllerProvider.notifier).reset();
    // Use go (not pushReplacement): after shell + cart + review pushes,
    // replacing with /orders/:id/... can duplicate StatefulShell page keys.
    if (order.paymentMethod == 'ELECTRONIC') {
      context.go(AppRoutes.orderPayment(order.id));
      return;
    }
    context.go(AppRoutes.orderConfirmation(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final cart = ref.watch(cartControllerProvider);
    final payment = ref.watch(checkoutPaymentMethodProvider);
    final availability = ref.watch(electronicPaymentAvailabilityProvider);
    final submission = ref.watch(orderSubmissionControllerProvider);
    final paymentSelectable = payment.isSelectable(availability);
    final canPlaceOrder =
        checkout.hasCurrentTotals &&
        paymentSelectable &&
        !submission.busy &&
        submission.phase != OrderSubmissionPhase.pendingVerification;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(AppStrings.checkoutReviewTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _items(context, checkout, cart.cart),
            const SizedBox(height: 16),
            _addressCard(context, checkout),
            if (checkout.error != null) ...[
              const SizedBox(height: 12),
              _banner(context, checkout.error!, AppColors.error),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('checkout-recovery'),
                  onPressed: () => _recover(context, checkout),
                  child: Text(checkout.recoveryLabel),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _paymentCard(context),
            if (payment == CheckoutPaymentMethod.electronic &&
                !paymentSelectable) ...[
              const SizedBox(height: 12),
              _banner(
                context,
                AppStrings.checkoutPaymentMethodUnavailable,
                AppColors.error,
              ),
            ],
            const SizedBox(height: 12),
            if (checkout.preview?.priceChanged == true)
              _banner(
                context,
                AppStrings.checkoutPriceChanged,
                AppColors.primary,
              ),
            if (submission.phase ==
                OrderSubmissionPhase.reconfirmationRequired) ...[
              const SizedBox(height: 12),
              _banner(
                context,
                submission.reconfirmationMessage ??
                    AppStrings.checkoutReconfirmRequired,
                AppColors.primary,
              ),
            ],
            if (submission.phase == OrderSubmissionPhase.pendingVerification)
              _pendingVerification(context),
            if (submission.error != null) ...[
              const SizedBox(height: 12),
              _banner(context, submission.error!, AppColors.error),
            ],
            const SizedBox(height: 8),
            _totals(context, checkout),
            const SizedBox(height: 12),
            _promoCard(context, checkout),
            const SizedBox(height: 8),
            Text(
              AppStrings.checkoutReviewHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (checkout.preview != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.checkoutPayable,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        MoneyFormat.dzd(
                          checkout.preview!.customerTotalMinor,
                        ),
                        key: const Key('checkout-sticky-total'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  key: const Key('checkout-place-order'),
                  onPressed: canPlaceOrder ? _placeOrder : null,
                  child: submission.busy
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              submission.phase ==
                                      OrderSubmissionPhase.refreshing
                                  ? AppStrings.checkoutVerifying
                                  : AppStrings.checkoutSubmitting,
                            ),
                          ],
                        )
                      : Text(
                          payment == CheckoutPaymentMethod.electronic
                              ? AppStrings.checkoutPlaceOrderElectronic
                              : AppStrings.checkoutPlaceOrder,
                        ),
                ),
                if (!canPlaceOrder && !submission.busy) ...[
                  const SizedBox(height: 8),
                  Text(
                    checkout.hasCurrentTotals
                        ? AppStrings.checkoutPlaceOrderUnavailable
                        : AppStrings.checkoutReviewHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _items(
    BuildContext context,
    CheckoutUiState checkout,
    CustomerCart? cart,
  ) {
    final previewCart = checkout.preview?.cart;
    final items = previewCart?.items ?? cart?.items ?? const <CartItem>[];
    final branchId = previewCart?.branchId ?? cart?.branchId;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final storefront = branchId == null
        ? null
        : ref.watch(storefrontDetailProvider(branchId));
    final name = storefront?.asData?.value.branchName;
    return Column(
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
        const SizedBox(height: 12),
        for (final item in items) ...[
          _itemRow(context, branchId, item),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _itemRow(BuildContext context, String? branchId, CartItem item) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AuthenticatedCatalogImage(
              imageUrl: branchId == null
                  ? null
                  : cartItemImageUrl(
                      branchId: branchId,
                      productId: item.productId,
                    ),
              fallbackLabel: item.productName,
              height: 56,
              width: 56,
              radius: 8,
              icon: Icons.lunch_dining_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  for (final option in item.selectedOptions)
                    Text(
                      _checkoutOptionLine(option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  Text(
                    '×${item.quantity}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              MoneyFormat.dzd(item.lineSubtotalMinor),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(BuildContext context, CheckoutUiState checkout) {
    final book = ref.watch(addressBookProvider);
    final selection = ref.watch(addressSelectionProvider);
    final addressId =
        checkout.addressId ??
        resolveCheckoutAddressId(book: book, selection: selection);
    final local = book.byId(addressId);
    final snapshot = checkout.preview?.address;
    final title = (snapshot?.displayLabel.isNotEmpty ?? false)
        ? snapshot!.displayLabel
        : (local?.displayLabel ?? '');
    final body = (snapshot?.addressText.isNotEmpty ?? false)
        ? snapshot!.addressText
        : (local?.addressText ?? '');
    return Material(
      key: const Key('checkout-address-card'),
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(AppRoutes.checkoutAddress),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.checkoutDeliveryAddress,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title.isEmpty
                          ? AppStrings.checkoutNeedAddress
                          : title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentCard(BuildContext context) {
    final payment = ref.watch(checkoutPaymentMethodProvider);
    final availability = ref.watch(electronicPaymentAvailabilityProvider);
    final selectable = payment.isSelectable(availability);
    final subtitle = payment == CheckoutPaymentMethod.cod
        ? AppStrings.checkoutPaymentCod
        : (selectable
              ? AppStrings.checkoutPaymentElectronic
              : AppStrings.checkoutPaymentElectronicSoon);
    return Material(
      key: const Key('checkout-payment-card'),
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(AppRoutes.checkoutMethod),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.checkoutPaymentTitle,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      key: const Key('checkout-payment-selected'),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingVerification(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _banner(
          context,
          AppStrings.orderSubmissionPendingVerification,
          AppColors.error,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.orderSubmissionPendingHint,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('checkout-verify-orders'),
                onPressed: () => context.go(AppRoutes.orders),
                child: const Text(AppStrings.orderSubmissionViewOrders),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                key: const Key('checkout-verify-again'),
                onPressed: () async {
                  final order = await ref
                      .read(orderSubmissionControllerProvider.notifier)
                      .retryVerification();
                  if (!context.mounted || order == null) {
                    return;
                  }
                  ref.read(lastCreatedOrderProvider.notifier).set(order);
                  ref.read(orderSubmissionControllerProvider.notifier).reset();
                  context.go(AppRoutes.orderConfirmation(order.id));
                },
                child: const Text(AppStrings.orderSubmissionCheckAgain),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _promoCard(BuildContext context, CheckoutUiState checkout) {
    final applied = checkout.preview?.promoApplied == true;
    final code = checkout.preview?.promoCode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.checkoutPromoLabel,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.checkoutPromoCopiedHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (applied && code != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.checkoutPromoApplied(code),
                      key: const Key('checkout-promo-applied'),
                    ),
                  ),
                  TextButton(
                    key: const Key('checkout-remove-promo'),
                    onPressed: checkout.loading
                        ? null
                        : () => ref
                              .read(checkoutControllerProvider.notifier)
                              .removePromo(),
                    child: const Text(AppStrings.checkoutPromoRemove),
                  ),
                ],
              )
            else ...[
              TextField(
                key: const Key('checkout-promo-field'),
                controller: _promo,
                enabled: !checkout.loading,
                textCapitalization: TextCapitalization.characters,
                scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                decoration: const InputDecoration(
                  hintText: AppStrings.checkoutPromoHint,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('checkout-apply-promo'),
                onPressed: checkout.loading
                    ? null
                    : () => ref
                          .read(checkoutControllerProvider.notifier)
                          .applyPromo(_promo.text),
                child: const Text(AppStrings.checkoutPromoApply),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _totals(BuildContext context, CheckoutUiState checkout) {
    final preview = checkout.preview;
    if (checkout.loading && preview == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(AppStrings.checkoutVerifying, textAlign: TextAlign.center),
      );
    }
    if (preview == null) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      key: const Key('checkout-totals'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _moneyRow(
              context,
              AppStrings.checkoutMerchandise,
              preview.merchandiseSubtotalMinor,
              key: 'checkout-merchandise',
            ),
            const SizedBox(height: 8),
            _moneyRow(
              context,
              AppStrings.checkoutDeliveryFee,
              preview.deliveryFeeMinor,
              key: 'checkout-delivery',
            ),
            if (preview.promoApplied) ...[
              const SizedBox(height: 8),
              _moneyRow(
                context,
                AppStrings.checkoutDiscount,
                preview.discountMinor,
                key: 'checkout-discount',
                negative: true,
              ),
            ],
            // Payable total lives on the sticky CTA (`checkout-sticky-total`).
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(
    BuildContext context,
    String label,
    String minor, {
    required String key,
    bool emphasize = false,
    bool negative = false,
  }) {
    final amount = MoneyFormat.dzd(minor);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)
                : null,
          ),
        ),
        Text(
          negative ? '−$amount' : amount,
          key: Key(key),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: emphasize ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  String _checkoutOptionLine(CartSelectedOption option) {
    final name = option.name ?? option.optionId;
    if (option.additionalPriceMinor == '0') {
      return name;
    }
    return '$name (+${MoneyFormat.dzd(option.additionalPriceMinor)})';
  }

  Widget _banner(BuildContext context, String message, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ),
    );
  }

  void _recover(BuildContext context, CheckoutUiState checkout) {
    switch (checkout.recovery) {
      case CheckoutRecovery.openCart:
        context.go(AppRoutes.cart);
      case CheckoutRecovery.openAddress:
        context.push(AppRoutes.checkoutAddress);
      case CheckoutRecovery.retry:
        ref.read(checkoutControllerProvider.notifier).refresh();
      case CheckoutRecovery.none:
        break;
    }
  }
}
