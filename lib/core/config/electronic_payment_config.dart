/// Deployment configuration for Customer electronic payment.
///
/// There is **no** Customer backend contract that exposes provider readiness.
/// Availability is therefore an explicit app compile-time flag (not discovered).
///
/// Enable a verified Chargily sandbox later with:
/// ```
/// flutter run \
///   --dart-define=API_BASE_URL=... \
///   --dart-define=ELECTRONIC_PAYMENT_ENABLED=true
/// ```
/// Backend must use `PAYMENT_PROVIDER=chargily`, `CHARGILY_MODE=test`,
/// `CHARGILY_SECRET_KEY`, and return/cancel/webhook URLs. Do **not** set the
/// flag merely to make ELECTRONIC selectable against the in-process `test`
/// adapter (`test://checkout/...`).
///
/// Optional review-only (never for production Customer builds):
/// `--dart-define=ELECTRONIC_PAYMENT_ALLOW_TEST_CHECKOUT=true` acknowledges
/// `test://` URLs without opening them or forging webhooks.
class ElectronicPaymentConfig {
  ElectronicPaymentConfig._();

  /// Default **false** — normal checkout keeps COD only.
  static const bool enabled = bool.fromEnvironment(
    'ELECTRONIC_PAYMENT_ENABLED',
    defaultValue: false,
  );

  /// When true (with [enabled]), `test://` checkout URLs are recognized for
  /// review messaging only — they are never launched externally.
  static const bool allowTestCheckout = bool.fromEnvironment(
    'ELECTRONIC_PAYMENT_ALLOW_TEST_CHECKOUT',
    defaultValue: false,
  );

  /// Chargily Pay V2 hosted checkout host (test + live).
  static const approvedCheckoutHosts = <String>['pay.chargily.net'];
}

class ElectronicPaymentAvailability {
  const ElectronicPaymentAvailability({
    required this.enabledForCheckout,
    this.allowTestCheckoutUrls = false,
    this.approvedHosts = ElectronicPaymentConfig.approvedCheckoutHosts,
  });

  /// When false, ELECTRONIC must not be selectable or submitted.
  final bool enabledForCheckout;

  /// Review/test only: acknowledge `test://` without opening it.
  final bool allowTestCheckoutUrls;

  final List<String> approvedHosts;

  static const disabled = ElectronicPaymentAvailability(
    enabledForCheckout: false,
  );
}

enum CheckoutUrlDecision {
  /// HTTPS URL on an approved provider host — safe to launch externally.
  openHttps,

  /// `test://` allowed only when [ElectronicPaymentAvailability.allowTestCheckoutUrls].
  acknowledgeTestScheme,

  rejectMissing,
  rejectInvalid,
  rejectHttp,
  rejectUnapprovedHost,
  rejectTestScheme,
}

/// Provider checkout URL policy. Never attaches SpeedyGo credentials.
CheckoutUrlDecision evaluateCheckoutUrl(
  String? rawUrl,
  ElectronicPaymentAvailability availability,
) {
  final url = rawUrl?.trim();
  if (url == null || url.isEmpty) {
    return CheckoutUrlDecision.rejectMissing;
  }
  if (url.startsWith('test://')) {
    return availability.allowTestCheckoutUrls
        ? CheckoutUrlDecision.acknowledgeTestScheme
        : CheckoutUrlDecision.rejectTestScheme;
  }
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) {
    return CheckoutUrlDecision.rejectInvalid;
  }
  if (uri.scheme == 'http') {
    return CheckoutUrlDecision.rejectHttp;
  }
  if (uri.scheme != 'https') {
    return CheckoutUrlDecision.rejectInvalid;
  }
  final host = uri.host.toLowerCase();
  final approved = availability.approvedHosts.any(
    (allowed) => host == allowed.toLowerCase() || host.endsWith('.$allowed'),
  );
  if (!approved) {
    return CheckoutUrlDecision.rejectUnapprovedHost;
  }
  return CheckoutUrlDecision.openHttps;
}

bool checkoutUrlIsLaunchable(CheckoutUrlDecision decision) {
  return decision == CheckoutUrlDecision.openHttps;
}
