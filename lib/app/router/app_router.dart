import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_catalog.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/features/account/presentation/account_hub_screen.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/auth/presentation/language_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/otp_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/phone_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/profile_setup_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/restore_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/splash_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/welcome_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_shell.dart';
import 'package:speedygo_customer_app/features/nav/presentation/nav_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.listen(navPreviewEnabledProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final preview = NavPreview.isEnabled(ref.read(navPreviewEnabledProvider));
      final path = state.uri.path;
      if (NavPreview.isPreviewPath(path) && !preview) {
        if (session.phase == SessionPhase.ready) {
          return AppRoutes.home;
        }
        if (session.phase == SessionPhase.needsProfile) {
          return AppRoutes.profileSetup;
        }
        return _signedOutTarget(session);
      }
      return _redirect(session, state.matchedLocation, path);
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.restore,
        builder: (_, _) => const RestoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (_, _) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(path: AppRoutes.otp, builder: (_, _) => const OtpScreen()),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.legalTerms,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('legal-terms')!),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('legal-privacy')!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, _) => const SearchTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, _) => const OrdersTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.alerts,
                builder: (_, _) => const AlertsTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (_, _) => const AccountHubScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('search-results')!,
          params: {'q': state.uri.queryParameters['q'] ?? ''},
        ),
      ),
      GoRoute(
        path: AppRoutes.directory,
        builder: (_, _) => const NavDirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.restaurants,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('restaurants')!),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('categories')!),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('favorites')!),
      ),
      GoRoute(
        path: AppRoutes.promotions,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('promotions')!),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('cart')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutNotes,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-notes')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutReview,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-review')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutAddress,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-address')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutAddressPicker,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-address-picker')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutMethod,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-method')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutPayment,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-payment')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutRedirect,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-redirect')!),
      ),
      GoRoute(
        path: AppRoutes.checkoutSubmit,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-submit')!),
      ),
      GoRoute(
        path: AppRoutes.accountAddresses,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('addresses')!),
      ),
      GoRoute(
        path: AppRoutes.addressForm,
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('address-form')!,
          params: {
            'addressId': state.uri.queryParameters['addressId'] ?? 'new',
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.addressConfirm,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('address-confirm')!),
      ),
      GoRoute(
        path: AppRoutes.locationPermission,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('location-permission')!),
      ),
      GoRoute(
        path: AppRoutes.accountLanguage,
        builder: (_, _) => const LanguageScreen(settings: true),
      ),
      GoRoute(
        path: AppRoutes.accountNotifications,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('account-notifications')!),
      ),
      GoRoute(
        path: AppRoutes.accountSecurity,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('account-security')!),
      ),
      GoRoute(
        path: AppRoutes.accountLegal,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('account-legal')!),
      ),
      GoRoute(
        path: AppRoutes.accountDelete,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('account-delete')!),
      ),
      GoRoute(
        path: AppRoutes.alertsPermission,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('alerts-permission')!),
      ),
      GoRoute(
        path: AppRoutes.supportNew,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('support-new')!),
      ),
      GoRoute(
        path: '/merchants/:branchId',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('merchant')!,
          params: {'branchId': state.pathParameters['branchId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/merchants/:branchId/info',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('merchant-info')!,
          params: {'branchId': state.pathParameters['branchId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/merchants/:branchId/menu',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('menu')!,
          params: {'branchId': state.pathParameters['branchId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/merchants/:branchId/reviews',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('merchant-reviews')!,
          params: {'branchId': state.pathParameters['branchId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/products/:productId',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('product')!,
          params: {
            'productId': state.pathParameters['productId'] ?? '',
            'branchId':
                state.uri.queryParameters['branchId'] ?? AppRoutes.navBranch,
          },
        ),
      ),
      GoRoute(
        path: '/products/:productId/configure',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('product-config')!,
          params: {'productId': state.pathParameters['productId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-detail')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/status',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-status')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/cancel',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-cancel')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/tracking',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-tracking')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/searching-driver',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-searching')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/map',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-map')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/nearby',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-nearby')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/waiting',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-waiting')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/confirmation',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-confirmation')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/completed',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-completed')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/receipt',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-receipt')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/rate',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-rate')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/write-review',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-write-review')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/delivery-code',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-delivery-code')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/delivery-notes',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-delivery-notes')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
        ),
      ),
      GoRoute(
        path: '/support/:ticketId',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('support-ticket')!,
          params: {'ticketId': state.pathParameters['ticketId'] ?? ''},
        ),
      ),
    ],
  );
});

String? _redirect(SessionState session, String matched, String path) {
  final location = matched.isNotEmpty ? matched : path;
  switch (session.phase) {
    case SessionPhase.bootstrapping:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SessionPhase.restoring:
    case SessionPhase.restoreRetryable:
      return location == AppRoutes.restore ? null : AppRoutes.restore;
    case SessionPhase.signedOut:
      return _signedOutRedirect(session, location);
    case SessionPhase.needsProfile:
      if (location == AppRoutes.profileSetup) {
        return null;
      }
      if (location == AppRoutes.welcome && !session.onboardingSeen) {
        return null;
      }
      return AppRoutes.profileSetup;
    case SessionPhase.ready:
      if (_isAuthGate(location)) {
        return AppRoutes.home;
      }
      return null;
  }
}

String? _signedOutRedirect(SessionState session, String location) {
  if (location == AppRoutes.otp && session.pendingPhone != null) {
    return null;
  }
  if (location == AppRoutes.phone) {
    return null;
  }
  if (location == AppRoutes.language && !session.languageSeen) {
    return null;
  }
  if (location == AppRoutes.welcome &&
      session.languageSeen &&
      !session.onboardingSeen) {
    return null;
  }
  if ((location == AppRoutes.legalTerms ||
          location == AppRoutes.legalPrivacy) &&
      !session.languageSeen) {
    return null;
  }
  return _signedOutTarget(session);
}

String _signedOutTarget(SessionState session) {
  if (session.pendingPhone != null) {
    return AppRoutes.otp;
  }
  if (!session.languageSeen) {
    return AppRoutes.language;
  }
  if (!session.onboardingSeen) {
    return AppRoutes.welcome;
  }
  return AppRoutes.phone;
}

bool _isAuthGate(String location) {
  return location == AppRoutes.splash ||
      location == AppRoutes.restore ||
      location == AppRoutes.language ||
      location == AppRoutes.welcome ||
      location == AppRoutes.phone ||
      location == AppRoutes.otp ||
      location == AppRoutes.profileSetup;
}
