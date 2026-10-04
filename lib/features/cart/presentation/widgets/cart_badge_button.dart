import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';

class CartBadgeButton extends ConsumerWidget {
  const CartBadgeButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartControllerProvider).badgeCount;
    return IconButton(
      tooltip: AppStrings.cartTitle,
      onPressed: () => context.push(AppRoutes.cart),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.shopping_basket_outlined,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
