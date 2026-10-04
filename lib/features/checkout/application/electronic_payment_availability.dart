import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/config/electronic_payment_config.dart';

/// Deployment availability for ELECTRONIC checkout (not a server discovery API).
final electronicPaymentAvailabilityProvider =
    Provider<ElectronicPaymentAvailability>((ref) {
      return const ElectronicPaymentAvailability(
        enabledForCheckout: ElectronicPaymentConfig.enabled,
        allowTestCheckoutUrls: ElectronicPaymentConfig.allowTestCheckout,
      );
    });
