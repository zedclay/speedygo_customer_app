import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';

/// Development-only navigation previews (fixtures + fabricated order states).
///
/// Enable with `--dart-define=CUSTOMER_NAV_PREVIEW=true` or by long-pressing
/// the home logo in a non-release build. Always off in release.
class NavPreview {
  NavPreview._();

  static const compileTimeEnabled = bool.fromEnvironment(
    'CUSTOMER_NAV_PREVIEW',
    defaultValue: false,
  );

  static const fixtureIds = {
    AppRoutes.navBranch,
    AppRoutes.navProduct,
    AppRoutes.navOrder,
    AppRoutes.navTicket,
    AppRoutes.navAddress,
    AppRoutes.navSession,
  };

  static bool isFixtureId(String? id) => fixtureIds.contains(id);

  static bool isEnabled(bool runtimeFlag) {
    if (kReleaseMode) {
      return false;
    }
    return runtimeFlag;
  }

  /// Preview-only when the path is the design directory or embeds a fixture id.
  ///
  /// Live order paths such as `/orders/<uuid>/confirmation` must NOT be gated —
  /// they share suffixes with design previews (`/confirmation`, `/completed`, …)
  /// and must stay reachable after Commander.
  static bool isPreviewPath(String path) {
    final normalized = path.split('?').first;
    if (normalized == AppRoutes.directory ||
        normalized.startsWith('${AppRoutes.directory}/')) {
      return true;
    }
    for (final id in fixtureIds) {
      if (normalized.contains('/$id')) {
        return true;
      }
    }
    return false;
  }
}

class NavPreviewFlag extends Notifier<bool> {
  NavPreviewFlag({this.initial});

  final bool? initial;

  @override
  bool build() => initial ?? NavPreview.compileTimeEnabled;

  void enable() {
    state = true;
  }
}

final navPreviewEnabledProvider = NotifierProvider<NavPreviewFlag, bool>(
  NavPreviewFlag.new,
);
