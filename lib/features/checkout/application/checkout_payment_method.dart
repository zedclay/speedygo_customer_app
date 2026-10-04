import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/config/electronic_payment_config.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';

enum CheckoutPaymentMethod { cod, electronic }

extension CheckoutPaymentMethodApi on CheckoutPaymentMethod {
  String get apiValue {
    switch (this) {
      case CheckoutPaymentMethod.cod:
        return 'COD';
      case CheckoutPaymentMethod.electronic:
        return 'ELECTRONIC';
    }
  }

  bool isSelectable(ElectronicPaymentAvailability availability) {
    switch (this) {
      case CheckoutPaymentMethod.cod:
        return true;
      case CheckoutPaymentMethod.electronic:
        return availability.enabledForCheckout;
    }
  }

  /// COD is always available; ELECTRONIC follows deployment flag (default off).
  bool get selectableInCurrentSlice {
    return isSelectable(
      const ElectronicPaymentAvailability(
        enabledForCheckout: ElectronicPaymentConfig.enabled,
        allowTestCheckoutUrls: ElectronicPaymentConfig.allowTestCheckout,
      ),
    );
  }
}

class CheckoutPaymentMethodController extends Notifier<CheckoutPaymentMethod> {
  @override
  CheckoutPaymentMethod build() => CheckoutPaymentMethod.cod;

  void select(CheckoutPaymentMethod method) {
    final availability = ref.read(electronicPaymentAvailabilityProvider);
    if (!method.isSelectable(availability)) {
      return;
    }
    state = method;
  }

  /// Test helper for a stale ELECTRONIC selection. Does not change availability.
  @visibleForTesting
  void debugSetSelection(CheckoutPaymentMethod method) {
    state = method;
  }
}

final checkoutPaymentMethodProvider =
    NotifierProvider<CheckoutPaymentMethodController, CheckoutPaymentMethod>(
      CheckoutPaymentMethodController.new,
    );
