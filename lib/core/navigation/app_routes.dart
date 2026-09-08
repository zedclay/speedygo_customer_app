/// Customer route paths and navigation-only fixture ids.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const restore = '/restore';
  static const language = '/language';
  static const welcome = '/welcome';
  static const phone = '/phone';
  static const otp = '/otp';
  static const profileSetup = '/profile';
  static const home = '/home';
  static const search = '/search';
  static const searchResults = '/search/results';
  static const orders = '/orders';
  static const alerts = '/alerts';
  static const alertsPermission = '/alerts/permission';
  static const account = '/account';
  static const accountLanguage = '/account/language';
  static const accountLegal = '/account/legal';
  static const accountSecurity = '/account/security';
  static const accountNotifications = '/account/notifications';
  static const accountAddresses = '/account/addresses';
  static const accountDelete = '/account/delete';
  static const addressForm = '/addresses/form';
  static const addressConfirm = '/addresses/confirm-location';
  static const locationPermission = '/location-permission';
  static const restaurants = '/restaurants';
  static const categories = '/categories';
  static const favorites = '/favorites';
  static const promotions = '/promotions';
  static const cart = '/cart';
  static const checkoutReview = '/checkout/review';
  static const checkoutAddress = '/checkout/address';
  static const checkoutAddressPicker = '/checkout/address-picker';
  static const checkoutMethod = '/checkout/method';
  static const checkoutPayment = '/checkout/payment';
  static const checkoutRedirect = '/checkout/redirect';
  static const checkoutSubmit = '/checkout/submit';
  static const checkoutNotes = '/checkout/notes';
  static const legalTerms = '/legal/terms';
  static const legalPrivacy = '/legal/privacy';
  static const supportNew = '/support/new';
  static const directory = '/directory';

  static const navBranch = 'nav-branch';
  static const navProduct = 'nav-product';
  static const navOrder = 'nav-order';
  static const navTicket = 'nav-ticket';
  static const navAddress = 'nav-address';
  static const navSession = 'nav-session';

  static String merchant(String branchId) => '/merchants/$branchId';
  static String merchantInfo(String branchId) => '/merchants/$branchId/info';
  static String merchantMenu(String branchId) => '/merchants/$branchId/menu';
  static String merchantReviews(String branchId) =>
      '/merchants/$branchId/reviews';
  static String product(String productId) => '/products/$productId';
  static String productConfigure(String productId) =>
      '/products/$productId/configure';
  static String order(String orderId) => '/orders/$orderId';
  static String orderStatus(String orderId) => '/orders/$orderId/status';
  static String orderCancel(String orderId) => '/orders/$orderId/cancel';
  static String orderTracking(String orderId) => '/orders/$orderId/tracking';
  static String orderSearching(String orderId) =>
      '/orders/$orderId/searching-driver';
  static String orderMap(String orderId) => '/orders/$orderId/map';
  static String orderNearby(String orderId) => '/orders/$orderId/nearby';
  static String orderWaiting(String orderId) => '/orders/$orderId/waiting';
  static String orderConfirmation(String orderId) =>
      '/orders/$orderId/confirmation';
  static String orderCompleted(String orderId) => '/orders/$orderId/completed';
  static String orderReceipt(String orderId) => '/orders/$orderId/receipt';
  static String orderRate(String orderId) => '/orders/$orderId/rate';
  static String orderReview(String orderId) => '/orders/$orderId/write-review';
  static String orderDeliveryCode(String orderId) =>
      '/orders/$orderId/delivery-code';
  static String orderDeliveryNotes(String orderId) =>
      '/orders/$orderId/delivery-notes';
  static String supportTicket(String ticketId) => '/support/$ticketId';

  static String searchResultsQuery(String q) =>
      '$searchResults?q=${Uri.encodeQueryComponent(q)}';
}
