import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_models.dart';
import 'package:speedygo_customer_app/core/navigation/nav_parents.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';

void showNavBlocked(BuildContext context, String message) {
  SgSnack.warning(context, message: message);
}

bool previewEnabledOf(BuildContext context) {
  return NavPreview.isEnabled(
    ProviderScope.containerOf(context).read(navPreviewEnabledProvider),
  );
}

void openNavLink(BuildContext context, NavLink link) {
  final blocked = link.blockedMessage;
  if (blocked != null) {
    showNavBlocked(context, blocked);
    return;
  }
  final location = link.location;
  if (location == null || location.isEmpty) {
    return;
  }
  if (NavPreview.isPreviewPath(location) && !previewEnabledOf(context)) {
    showNavBlocked(context, AppStrings.previewUnavailable);
    return;
  }
  if (location == AppRoutes.home ||
      location == AppRoutes.search ||
      location == AppRoutes.orders ||
      location == AppRoutes.alerts ||
      location == AppRoutes.account ||
      location == AppRoutes.promotions) {
    context.go(location);
    return;
  }
  context.push(location);
}

void popOrParent(BuildContext context, {String? fallback}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  final path = GoRouterState.of(context).uri.path;
  context.go(fallback ?? NavParents.forPath(path));
}

String capabilityLabel(NavCapability capability) {
  switch (capability) {
    case NavCapability.liveAuth:
      return AppStrings.liveAuthBadge;
    case NavCapability.navigationOnly:
      return AppStrings.navOnlyBadge;
    case NavCapability.unsupported:
      return AppStrings.unsupportedBadge;
    case NavCapability.productDecision:
      return AppStrings.productDecisionBadge;
    case NavCapability.designToken:
      return 'Design';
  }
}
