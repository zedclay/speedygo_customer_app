import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_api.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';
import 'package:speedygo_customer_app/features/checkout/domain/checkout_address.dart';

enum CheckoutRecovery { none, retry, openCart, openAddress }

class CheckoutUiState {
  const CheckoutUiState({
    this.loading = false,
    this.preview,
    this.error,
    this.errorCode,
    this.addressId,
    this.requestedPromoCode,
    this.missingAddress = false,
    this.cartFingerprint = '',
  });

  final bool loading;
  final CheckoutPreview? preview;
  final String? error;
  final String? errorCode;
  final String? addressId;
  final String? requestedPromoCode;
  final bool missingAddress;
  final String cartFingerprint;

  bool get hasCurrentTotals => preview != null && error == null && !loading;

  CheckoutRecovery get recovery {
    switch (errorCode) {
      case 'CHECKOUT_CART_REQUIRED':
      case 'CHECKOUT_CART_NOT_READY':
      case 'CHECKOUT_MERCHANT_NOT_OPERATIONAL':
      case 'CHECKOUT_BRANCH_NOT_OPERATIONAL':
      case 'CHECKOUT_BRANCH_CLOSED':
      case 'CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED':
        return CheckoutRecovery.openCart;
      case 'CHECKOUT_ADDRESS_NOT_FOUND':
      case 'CHECKOUT_ADDRESS_COORDINATES_REQUIRED':
      case 'CHECKOUT_ADDRESS_OUTSIDE_ZONE':
      case 'CHECKOUT_DELIVERY_ZONE_AMBIGUOUS':
      case 'CHECKOUT_PRICING_RULE_NOT_FOUND':
      case 'CHECKOUT_PRICING_CONFIGURATION_INVALID':
      case 'CHECKOUT_BRANCH_OUTSIDE_ZONE':
        return CheckoutRecovery.openAddress;
      default:
        if (missingAddress) {
          return CheckoutRecovery.openAddress;
        }
        if (error != null) {
          return CheckoutRecovery.retry;
        }
        return CheckoutRecovery.none;
    }
  }

  String get recoveryLabel {
    switch (recovery) {
      case CheckoutRecovery.openCart:
        return AppStrings.checkoutOpenCart;
      case CheckoutRecovery.openAddress:
        return missingAddress
            ? AppStrings.checkoutChooseAddress
            : AppStrings.checkoutChangeAddress;
      case CheckoutRecovery.retry:
        return AppStrings.checkoutRetryPreview;
      case CheckoutRecovery.none:
        return AppStrings.retry;
    }
  }

  CheckoutUiState copyWith({
    bool? loading,
    CheckoutPreview? preview,
    String? error,
    String? errorCode,
    String? addressId,
    String? requestedPromoCode,
    bool? missingAddress,
    String? cartFingerprint,
    bool clearPreview = false,
    bool clearError = false,
  }) {
    return CheckoutUiState(
      loading: loading ?? this.loading,
      preview: clearPreview ? null : (preview ?? this.preview),
      error: clearError ? null : (error ?? this.error),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      addressId: addressId ?? this.addressId,
      requestedPromoCode: requestedPromoCode ?? this.requestedPromoCode,
      missingAddress: missingAddress ?? this.missingAddress,
      cartFingerprint: cartFingerprint ?? this.cartFingerprint,
    );
  }
}

final checkoutApiProvider = Provider<CheckoutClient>((ref) {
  return CheckoutApi(ref.watch(authInfrastructureProvider).dio);
});

class CheckoutController extends Notifier<CheckoutUiState> {
  var _seq = 0;
  String? _requestedPromoCode;

  @override
  CheckoutUiState build() {
    ref.watch(catalogScopeProvider);
    ref.listen(cartControllerProvider, (previous, next) {
      unawaited(refresh());
    });
    ref.listen(addressBookProvider, (previous, next) {
      unawaited(refresh());
    });
    ref.listen(addressSelectionProvider, (previous, next) {
      unawaited(refresh());
    });
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh());
    });
    return CheckoutUiState(
      loading: true,
      requestedPromoCode: _requestedPromoCode,
    );
  }

  Future<void> refresh() {
    final cart = ref.read(cartControllerProvider);
    final book = ref.read(addressBookProvider);
    final selection = ref.read(addressSelectionProvider);
    return _requestPreview(
      addressId: resolveCheckoutAddressId(book: book, selection: selection),
      fingerprint: checkoutCartFingerprint(
        cartId: cart.cart?.id,
        itemCount: cart.cart?.itemCount,
        merchandiseSubtotalMinor: cart.cart?.cartSubtotalMinor,
        updatedAt: cart.cart?.updatedAt,
      ),
      cart: cart.cart,
      cartLoading: cart.loading && !cart.cartExists,
      bookLoading: book.loading && book.addresses.isEmpty,
    );
  }

  Future<void> applyPromo(String raw) {
    final code = raw.trim();
    if (code.isEmpty) {
      state = state.copyWith(
        error: AppStrings.checkoutPromoEmpty,
        errorCode: 'PROMOTION_CODE_INVALID',
        clearPreview: true,
        loading: false,
      );
      return Future<void>.value();
    }
    _requestedPromoCode = code;
    return refresh();
  }

  Future<void> removePromo() {
    _requestedPromoCode = null;
    return refresh();
  }

  void applyPreview(CheckoutPreview preview, {bool syncPromo = false}) {
    if (syncPromo) {
      final code = preview.promoCode?.trim();
      _requestedPromoCode = (code == null || code.isEmpty) ? null : code;
    }
    final cart = ref.read(cartControllerProvider);
    state = CheckoutUiState(
      preview: preview,
      addressId: preview.address.id,
      requestedPromoCode: _requestedPromoCode,
      cartFingerprint: checkoutCartFingerprint(
        cartId: cart.cart?.id,
        itemCount: cart.cart?.itemCount,
        merchandiseSubtotalMinor: cart.cart?.cartSubtotalMinor,
        updatedAt: cart.cart?.updatedAt,
      ),
    );
  }

  Future<void> _requestPreview({
    required String? addressId,
    required String fingerprint,
    required CustomerCart? cart,
    required bool cartLoading,
    required bool bookLoading,
  }) async {
    if (cartLoading || bookLoading) {
      state = CheckoutUiState(
        loading: true,
        addressId: addressId,
        requestedPromoCode: _requestedPromoCode,
        cartFingerprint: fingerprint,
      );
      return;
    }
    final cartReadyForPreview = cart != null && cart.items.isNotEmpty;
    if (!cartReadyForPreview) {
      _seq += 1;
      state = CheckoutUiState(
        error: AppStrings.errorForCode('CHECKOUT_CART_REQUIRED'),
        errorCode: 'CHECKOUT_CART_REQUIRED',
        addressId: addressId,
        requestedPromoCode: _requestedPromoCode,
        cartFingerprint: fingerprint,
      );
      return;
    }
    if (addressId == null) {
      _seq += 1;
      state = CheckoutUiState(
        addressId: null,
        requestedPromoCode: _requestedPromoCode,
        missingAddress: true,
        cartFingerprint: fingerprint,
        error: AppStrings.checkoutNeedAddress,
      );
      return;
    }

    final seq = ++_seq;
    final promo = _requestedPromoCode;
    state = CheckoutUiState(
      loading: true,
      addressId: addressId,
      requestedPromoCode: promo,
      cartFingerprint: fingerprint,
    );
    try {
      final preview = await ref
          .read(checkoutApiProvider)
          .preview(
            CheckoutPreviewRequest(addressId: addressId, promoCode: promo),
          );
      if (!ref.mounted) {
        return;
      }
      // A newer preview superseded this one — leave that in-flight request alone.
      if (seq != _seq) {
        return;
      }
      state = CheckoutUiState(
        preview: preview,
        addressId: addressId,
        requestedPromoCode: promo,
        cartFingerprint: fingerprint,
      );
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      if (seq != _seq) {
        return;
      }
      final parsed = _parse(error);
      if (isPromotionCheckoutError(parsed.code)) {
        _requestedPromoCode = null;
      }
      state = CheckoutUiState(
        error: parsed.message,
        errorCode: parsed.code,
        addressId: addressId,
        requestedPromoCode: _requestedPromoCode,
        cartFingerprint: fingerprint,
      );
    }
  }

  ({String message, String? code}) _parse(Object error) {
    if (error is AppException) {
      return (message: error.message, code: error.code);
    }
    if (error is CheckoutParseException) {
      return (message: AppStrings.unexpected, code: 'CHECKOUT_PARSE');
    }
    return (message: AppStrings.unexpected, code: null);
  }
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutUiState>(
      CheckoutController.new,
    );
