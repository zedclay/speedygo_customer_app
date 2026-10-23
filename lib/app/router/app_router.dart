import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_catalog.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/features/account/presentation/account_hub_screen.dart';
import 'package:speedygo_customer_app/features/account/presentation/account_status_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/active_sessions_screen.dart';
import 'package:speedygo_customer_app/features/notifications/presentation/notification_inbox_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_cancel_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_confirmation_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_payment_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:speedygo_customer_app/features/orders/presentation/orders_tab_screen.dart';
import 'package:speedygo_customer_app/features/orders/application/order_tracking_controller.dart';
import 'package:speedygo_customer_app/features/ratings/presentation/merchant_reviews_screen.dart';
import 'package:speedygo_customer_app/features/ratings/presentation/order_rate_screen.dart';
import 'package:speedygo_customer_app/features/ratings/presentation/order_write_review_screen.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_create_screen.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_detail_screen.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_list_screen.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/address_form_screen.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/address_list_screen.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/address_picker_screen.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/location_confirm_screen.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/location_permission_screen.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/auth/presentation/language_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/otp_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/phone_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/profile_setup_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/restore_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/splash_screen.dart';
import 'package:speedygo_customer_app/features/auth/presentation/welcome_screen.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';
import 'package:speedygo_customer_app/features/cart/presentation/cart_screen.dart';
import 'package:speedygo_customer_app/features/cart/presentation/product_configure_screen.dart';
import 'package:speedygo_customer_app/features/checkout/presentation/checkout_payment_method_screen.dart';
import 'package:speedygo_customer_app/features/checkout/presentation/checkout_review_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/search_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/storefront_detail_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/storefront_info_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/storefront_list_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/commerce_verticals_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_design_preview_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/promotions/presentation/promotions_list_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_shell.dart';
import 'package:speedygo_customer_app/features/nav/presentation/nav_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeBranch');
  final searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'searchBranch');
  final ordersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ordersBranch');
  final alertsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'alertsBranch');
  final accountNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'accountBranch');
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (previous, next) {
    if (previous == null ||
        previous.phase != next.phase ||
        previous.generation != next.generation ||
        previous.pendingPhone != next.pendingPhone ||
        previous.languageSeen != next.languageSeen ||
        previous.onboardingSeen != next.onboardingSeen ||
        previous.tokens?.accessToken != next.tokens?.accessToken) {
      refresh.value++;
    }
  });
  ref.listen(navPreviewEnabledProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    // Hot restart otherwise keeps the engine's last path and also rebuilds
    // splash→home, which puts two Pages with the same key on one Navigator.
    overridePlatformDefaultLocation: true,
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
        builder: (_, _) => AccountStatusScreen(
          title: AppStrings.legalTermsTitle,
          body: AppStrings.legalUnavailableBody,
          icon: Icons.gavel,
        ),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        builder: (_, _) => AccountStatusScreen(
          title: AppStrings.legalPrivacyTitle,
          body: AppStrings.legalUnavailableBody,
          icon: Icons.privacy_tip_outlined,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'categories',
                    builder: (_, _) => const CommerceVerticalsScreen(),
                    routes: [
                      GoRoute(
                        path: 'results',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final verticalId =
                              state.uri.queryParameters['verticalId'];
                          return StorefrontListScreen(verticalId: verticalId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: searchNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) =>
                    SearchScreen(initialQuery: state.uri.queryParameters['q']),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: ordersNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, _) => const OrdersTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: alertsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.alerts,
                builder: (_, _) => const NotificationInboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: accountNavigatorKey,
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
        builder: (context, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
          showBack: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.directory,
        builder: (_, _) => const NavDirectoryScreen(),
        routes: [
          GoRoute(
            path: 'home-design',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const HomeDesignPreviewScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.restaurants,
        builder: (context, state) {
          final verticalId = state.uri.queryParameters['verticalId'];
          return StorefrontListScreen(verticalId: verticalId);
        },
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (_, _) => const CommerceVerticalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, _) => NavScaffold(entry: NavCatalog.byId('favorites')!),
      ),
      GoRoute(
        path: AppRoutes.promotions,
        builder: (_, _) => const PromotionsListScreen(),
      ),
      GoRoute(path: AppRoutes.cart, builder: (_, _) => const CartScreen()),
      GoRoute(
        path: AppRoutes.checkoutNotes,
        builder: (_, _) => AccountStatusScreen(
          title: AppStrings.checkoutNotesTitle,
          body: AppStrings.checkoutNotesUnavailable,
          icon: Icons.notes_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkoutReview,
        builder: (_, _) => const CheckoutReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkoutAddress,
        builder: (_, _) => const AddressPickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkoutAddressPicker,
        builder: (_, _) => const AddressPickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkoutMethod,
        builder: (_, _) => const CheckoutPaymentMethodScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkoutPayment,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          if (orderId == null ||
              orderId.isEmpty ||
              orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('checkout-payment')!,
            );
          }
          return OrderPaymentScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutRedirect,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          if (orderId == null ||
              orderId.isEmpty ||
              orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('checkout-redirect')!,
            );
          }
          return OrderPaymentScreen(orderId: orderId, autoRedirect: true);
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutSubmit,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('checkout-submit')!),
      ),
      GoRoute(
        path: AppRoutes.accountAddresses,
        builder: (_, _) => const AddressListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressForm,
        builder: (context, state) => AddressFormScreen(
          addressId: state.uri.queryParameters['addressId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.addressConfirm,
        builder: (context, state) {
          final extra = state.extra;
          return LocationConfirmScreen(
            fix: extra is DeviceLocation ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.locationPermission,
        builder: (_, _) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountLanguage,
        builder: (_, _) => const LanguageScreen(settings: true),
      ),
      GoRoute(
        path: AppRoutes.accountNotifications,
        builder: (context, _) => AccountStatusScreen(
          title: AppStrings.accountNotificationsSettingsTitle,
          body: AppStrings.accountNotificationsSettingsBody,
          icon: Icons.notifications_outlined,
          secondaryLabel: AppStrings.accountNotificationsOpenInbox,
          secondaryKey: const Key('account-notifications-inbox'),
          onSecondary: () => context.go(AppRoutes.alerts),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountPaymentMethods,
        builder: (_, _) => AccountStatusScreen(
          title: AppStrings.accountPaymentMethodsTitle,
          body: AppStrings.accountPaymentMethodsBody,
          icon: Icons.payments_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutes.accountSecurity,
        builder: (_, _) => const ActiveSessionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountLegal,
        builder: (_, _) => AccountStatusScreen(
          title: AppStrings.accountSectionLegal,
          body: AppStrings.legalUnavailableBody,
          icon: Icons.policy_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutes.accountDelete,
        builder: (_, _) => AccountStatusScreen(
          title: AppStrings.accountDeleteTitle,
          body: AppStrings.accountDeleteBody,
          icon: Icons.delete_forever_outlined,
          actionLabel: AppStrings.accountDeleteAction,
          actionMessage: AppStrings.deleteUnavailable,
          actionKey: Key('account-delete-confirm'),
        ),
      ),
      GoRoute(
        path: AppRoutes.alertsPermission,
        builder: (_, _) =>
            NavScaffold(entry: NavCatalog.byId('alerts-permission')!),
      ),
      GoRoute(
        path: AppRoutes.supportList,
        builder: (_, _) => const SupportListScreen(),
      ),
      GoRoute(
        path: AppRoutes.supportNew,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          return SupportCreateScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/support/:ticketId',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId'] ?? '';
          if (ticketId == AppRoutes.navTicket || ticketId.isEmpty) {
            return NavScaffold(
              entry: NavCatalog.byId('support-ticket')!,
              params: {'ticketId': ticketId},
            );
          }
          return SupportDetailScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/merchants/:branchId',
        builder: (context, state) {
          final branchId = state.pathParameters['branchId'] ?? '';
          if (!CatalogIds.isLiveUuid(branchId)) {
            return NavScaffold(
              entry: NavCatalog.byId('merchant')!,
              params: {'branchId': branchId},
            );
          }
          return StorefrontDetailScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/merchants/:branchId/info',
        builder: (context, state) {
          final branchId = state.pathParameters['branchId'] ?? '';
          if (!CatalogIds.isLiveUuid(branchId)) {
            return NavScaffold(
              entry: NavCatalog.byId('merchant-info')!,
              params: {'branchId': branchId},
            );
          }
          return StorefrontInfoScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/merchants/:branchId/menu',
        builder: (context, state) {
          final branchId = state.pathParameters['branchId'] ?? '';
          if (!CatalogIds.isLiveUuid(branchId)) {
            return NavScaffold(
              entry: NavCatalog.byId('menu')!,
              params: {'branchId': branchId},
            );
          }
          return StorefrontDetailScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/merchants/:branchId/products/:productId/configure',
        builder: (context, state) {
          final qty = int.tryParse(state.uri.queryParameters['qty'] ?? '');
          return ProductConfigureScreen(
            branchId: state.pathParameters['branchId'] ?? '',
            productId: state.pathParameters['productId'] ?? '',
            initialQuantity: qty ?? 1,
          );
        },
      ),
      GoRoute(
        path: '/merchants/:branchId/products/:productId',
        builder: (context, state) {
          return ProductDetailScreen(
            branchId: state.pathParameters['branchId'] ?? '',
            productId: state.pathParameters['productId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/merchants/:branchId/reviews',
        builder: (context, state) {
          final branchId = state.pathParameters['branchId'] ?? '';
          if (!CatalogIds.isLiveUuid(branchId)) {
            return NavScaffold(
              entry: NavCatalog.byId('merchant-reviews')!,
              params: {'branchId': branchId},
            );
          }
          return MerchantReviewsScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/products/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          final branchId =
              state.uri.queryParameters['branchId'] ?? AppRoutes.navBranch;
          if (CatalogIds.isFixture(productId) ||
              CatalogIds.isFixture(branchId)) {
            return NavScaffold(
              entry: NavCatalog.byId('product')!,
              params: {'productId': productId, 'branchId': branchId},
            );
          }
          return ProductDetailScreen(branchId: branchId, productId: productId);
        },
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
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-detail')!,
              params: {'orderId': orderId},
            );
          }
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/status',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-status')!,
              params: {'orderId': orderId},
            );
          }
          return OrderTrackingScreen(
            orderId: orderId,
            focus: OrderTrackingFocus.statusDetails,
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderId/cancel',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-cancel')!,
              params: {'orderId': orderId},
            );
          }
          return OrderCancelScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/tracking',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-tracking')!,
              params: {'orderId': orderId},
            );
          }
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/searching-driver',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-searching')!,
              params: {'orderId': orderId},
            );
          }
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/map',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-map')!,
              params: {'orderId': orderId},
            );
          }
          return OrderTrackingScreen(
            orderId: orderId,
            focus: OrderTrackingFocus.map,
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderId/nearby',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-nearby')!,
              params: {'orderId': orderId},
            );
          }
          return OrderTrackingScreen(
            orderId: orderId,
            focus: OrderTrackingFocus.nearby,
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderId/waiting',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-waiting')!,
              params: {'orderId': orderId},
            );
          }
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/confirmation',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-confirmation')!,
              params: {'orderId': orderId},
            );
          }
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/payment',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('checkout-payment')!,
              params: {'orderId': orderId},
            );
          }
          return OrderPaymentScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/payment/redirect',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('checkout-redirect')!,
              params: {'orderId': orderId},
            );
          }
          return OrderPaymentScreen(orderId: orderId, autoRedirect: true);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/completed',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-completed')!,
              params: {'orderId': orderId},
            );
          }
          return OrderTrackingScreen(
            orderId: orderId,
            focus: OrderTrackingFocus.completed,
          );
        },
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
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-rate')!,
              params: {'orderId': orderId},
            );
          }
          return OrderRateScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/write-review',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-write-review')!,
              params: {'orderId': orderId},
            );
          }
          return OrderWriteReviewScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/delivery-code',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          if (orderId == AppRoutes.navOrder) {
            return NavScaffold(
              entry: NavCatalog.byId('order-delivery-code')!,
              params: {'orderId': orderId},
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(AppStrings.trackingTitle),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppStrings.trackingDeliveryCodeUnavailable,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderId/delivery-notes',
        builder: (context, state) => NavScaffold(
          entry: NavCatalog.byId('order-delivery-notes')!,
          params: {'orderId': state.pathParameters['orderId'] ?? ''},
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
      if (location == AppRoutes.legalTerms ||
          location == AppRoutes.legalPrivacy) {
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
