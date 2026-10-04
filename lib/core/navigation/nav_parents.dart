import 'package:speedygo_customer_app/core/navigation/app_routes.dart';

/// Safe parent when there is no navigator history.
/// Prefer the originating stack via [pop]; use this only as a fallback.
class NavParents {
  NavParents._();

  static String forPath(String path) {
    final normalized = path.split('?').first;
    if (normalized == AppRoutes.searchResults) {
      return AppRoutes.search;
    }
    if (normalized == AppRoutes.directory) {
      return AppRoutes.home;
    }
    if (normalized == AppRoutes.homeCategories ||
        normalized.startsWith('${AppRoutes.homeCategories}/results')) {
      return AppRoutes.home;
    }
    if (normalized == AppRoutes.homeDesignPreview) {
      return AppRoutes.directory;
    }
    if (normalized == AppRoutes.otp) {
      return AppRoutes.phone;
    }
    if (normalized == AppRoutes.alertsPermission) {
      return AppRoutes.alerts;
    }
    if (normalized == AppRoutes.accountLanguage ||
        normalized == AppRoutes.accountLegal ||
        normalized == AppRoutes.accountSecurity ||
        normalized == AppRoutes.accountNotifications ||
        normalized == AppRoutes.accountPaymentMethods ||
        normalized == AppRoutes.accountAddresses ||
        normalized == AppRoutes.accountDelete) {
      return AppRoutes.account;
    }
    if (normalized == AppRoutes.addressForm ||
        normalized == AppRoutes.addressConfirm ||
        normalized == AppRoutes.locationPermission) {
      return AppRoutes.accountAddresses;
    }
    if (normalized == AppRoutes.checkoutAddress) {
      return AppRoutes.checkoutReview;
    }
    if (normalized == AppRoutes.checkoutAddressPicker) {
      return AppRoutes.home;
    }
    if (normalized == AppRoutes.checkoutNotes) {
      return AppRoutes.cart;
    }
    if (normalized == AppRoutes.checkoutReview) {
      return AppRoutes.cart;
    }
    if (normalized == AppRoutes.checkoutMethod) {
      return AppRoutes.checkoutReview;
    }
    if (normalized == AppRoutes.checkoutPayment) {
      return AppRoutes.checkoutMethod;
    }
    if (normalized == AppRoutes.checkoutRedirect) {
      return AppRoutes.checkoutPayment;
    }
    if (normalized == AppRoutes.checkoutSubmit) {
      return AppRoutes.checkoutRedirect;
    }
    if (normalized == AppRoutes.legalTerms ||
        normalized == AppRoutes.legalPrivacy) {
      return AppRoutes.accountLegal;
    }
    if (normalized == AppRoutes.supportNew) {
      return AppRoutes.supportList;
    }
    if (normalized == AppRoutes.supportList) {
      return AppRoutes.account;
    }
    if (normalized.startsWith('/support/')) {
      return AppRoutes.supportList;
    }
    if (normalized.startsWith('/merchants/')) {
      final parts = normalized.split('/');
      if (parts.length > 3) {
        return AppRoutes.merchant(parts[2]);
      }
      return AppRoutes.homeCategories;
    }
    if (normalized.startsWith('/products/')) {
      final parts = normalized.split('/');
      if (parts.length > 3) {
        return AppRoutes.product(parts[2]);
      }
      return AppRoutes.restaurants;
    }
    if (normalized.startsWith('/orders/')) {
      final parts = normalized.split('/');
      if (parts.length > 3) {
        return AppRoutes.order(parts[2]);
      }
      return AppRoutes.orders;
    }
    if (normalized == AppRoutes.categories ||
        normalized == AppRoutes.favorites ||
        normalized == AppRoutes.promotions ||
        normalized == AppRoutes.cart) {
      return AppRoutes.home;
    }
    if (normalized == AppRoutes.restaurants) {
      return AppRoutes.homeCategories;
    }
    return AppRoutes.home;
  }
}
