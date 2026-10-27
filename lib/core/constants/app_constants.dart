class AppConstants {
  AppConstants._();

  static const String appName = 'SpeedyGo';
  static const String appVersion = '1.0.0';

  /// Full API prefix including `/api/v1` exactly once.
  ///
  /// Examples (dart-define):
  /// - Android emulator: `http://10.0.2.2:3000/api/v1`
  /// - iOS simulator: `http://127.0.0.1:3000/api/v1`
  /// - Physical-device LAN HTTP is not supported by the current
  ///   localhost-only ATS / cleartext allowlist. See README.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api/v1',
  );

  static const int otpLength = 6;
  static const int otpResendCooldownSeconds = 60;
  static const int refreshMaxAttempts = 1;
  static const String speedyGoAppHeader = 'X-SpeedyGo-App';
  static const String speedyGoAppAudience = 'CUSTOMER';
}

/// Resolves the server origin used by unprefixed `GET /health`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String healthPath = '/health';
  static const String otpRequestPath = '/auth/otp/request';
  static const String otpVerifyPath = '/auth/otp/verify';
  static const String refreshPath = '/auth/refresh';
  static const String logoutPath = '/auth/logout';
  static const String logoutAllPath = '/auth/logout-all';
  static const String authMePath = '/auth/me';
  static const String authSessionsPath = '/auth/sessions';
  static String authSessionPath(String sessionId) =>
      '/auth/sessions/$sessionId';
  static const String customerMePath = '/customer/me';
  static const String customerProfilePath = '/customer/profile';
  static const String customerCommerceVerticalsPath =
      '/customer/commerce-verticals';
  static const String customerBranchesPath = '/customer/branches';
  static const String customerMerchantRatingSummariesPath =
      '/customer/ratings/merchant-summaries';
  static const String customerCatalogSearchPath = '/customer/catalog/search';
  static const String customerPromotionsPath = '/customer/promotions';
  static const String customerOrdersPath = '/customer/orders';
  static const String customerCartPath = '/customer/cart';
  static const String customerCartItemsPath = '/customer/cart/items';
  static const String customerCheckoutPreviewPath =
      '/customer/checkout/preview';
  static const String customerAddressesPath = '/customer/addresses';
  static const String geoWilayasPath = '/geo/wilayas';
  static const String geoPlacesAutocompletePath = '/geo/places/autocomplete';
  static const String geoPlacesDetailsPath = '/geo/places/details';
  static const String geoReverseGeocodePath = '/geo/geocode/reverse';

  static String customerAddressPath(String addressId) =>
      '/customer/addresses/$addressId';

  static String customerAddressDefaultPath(String addressId) =>
      '/customer/addresses/$addressId/default';

  static String customerCartItemPath(String cartItemId) =>
      '/customer/cart/items/$cartItemId';

  static String customerOrderPath(String orderId) =>
      '/customer/orders/$orderId';

  static String customerOrderCancelPath(String orderId) =>
      '/customer/orders/$orderId/cancel';

  static String customerOrderRefundsPath(String orderId) =>
      '/customer/orders/$orderId/refunds';

  static String customerOrderDeliveryPath(String orderId) =>
      '/customer/orders/$orderId/delivery';

  static String customerOrderTrackingPath(String orderId) =>
      '/customer/orders/$orderId/tracking';

  static String customerOrderPaymentPath(String orderId) =>
      '/customer/orders/$orderId/payment';

  static String customerOrderPaymentInitiatePath(String orderId) =>
      '/customer/orders/$orderId/payment/initiate';

  static const String customerSupportPath = '/customer/support';

  static String customerSupportTicketPath(String ticketId) =>
      '/customer/support/$ticketId';

  static String customerSupportTicketMessagesPath(String ticketId) =>
      '/customer/support/$ticketId/messages';

  static const String notificationsPath = '/notifications';
  static const String notificationsUnreadCountPath =
      '/notifications/unread-count';
  static const String notificationsReadAllPath = '/notifications/read-all';
  static String notificationReadPath(String notificationId) =>
      '/notifications/$notificationId/read';
  static const String deviceTokensPath = '/notifications/device-tokens';

  static String customerMerchantRatingSummaryPath(String merchantId) =>
      '/customer/merchants/$merchantId/ratings/summary';

  static String customerOrderMerchantRatingPath(String orderId) =>
      '/customer/orders/$orderId/ratings/merchant';

  static String customerOrderDriverRatingPath(String orderId) =>
      '/customer/orders/$orderId/ratings/driver';

  /// HTTP origin for Socket.IO `/realtime` (strip `/api/v1`).
  static String realtimeOrigin({String apiBaseUrl = AppConstants.apiBaseUrl}) {
    final uri = Uri.parse(apiBaseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  static const String realtimeNamespace = '/realtime';
  static const String trackingSubscribeEvent = 'tracking:subscribe';
  static const String trackingUnsubscribeEvent = 'tracking:unsubscribe';
  static const String trackingLocationEvent = 'tracking:location';
  static const String trackingStatusEvent = 'tracking:status';
  static const String trackingErrorEvent = 'tracking:error';
}
