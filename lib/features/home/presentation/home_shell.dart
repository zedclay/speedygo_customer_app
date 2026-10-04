import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_inbox_controller.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _alertsBranchIndex = 3;

  static const _branchRoots = [
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.orders,
    AppRoutes.alerts,
    AppRoutes.account,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: false,
        body: navigationShell,
        bottomNavigationBar: HomeBottomBar(
          selectedIndex: navigationShell.currentIndex,
          onSelect: (index) {
            if (index == _alertsBranchIndex) {
              ref
                  .read(notificationInboxControllerProvider.notifier)
                  .refresh(quiet: true);
              ref.read(notificationUnreadCountProvider.notifier).refresh();
            }
            // Always go() to the branch root. goBranch(restore) can replay a
            // prior match list and put two Pages with the same shell key on
            // the root Navigator (duplicate keyReservation crash).
            final root = _branchRoots[index];
            if (index == navigationShell.currentIndex &&
                GoRouterState.of(context).uri.path == root) {
              navigationShell.goBranch(index, initialLocation: true);
              return;
            }
            context.go(root);
          },
        ),
      ),
    );
  }
}
