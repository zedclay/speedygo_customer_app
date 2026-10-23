import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_preview_blocks.dart';

/// Full approved Home composition for visual review.
///
/// Gated by [NavPreview]. Fixture data is local and never sent to APIs.
class HomeDesignPreviewScreen extends ConsumerWidget {
  const HomeDesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = NavPreview.isEnabled(ref.watch(navPreviewEnabledProvider));
    if (kReleaseMode || !preview) {
      return const SizedBox.shrink();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            Material(
              color: AppColors.tertiaryFixed,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.back,
                      onPressed: () => popOrParent(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.tertiary,
                      ),
                    ),
                    const Expanded(child: HomePreviewBannerStrip()),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeHeader(
                          addressLabel: AppStrings.previewAddress,
                          onAddressTap: () {},
                          onAlertsTap: () {},
                        ),
                        HomeGreeting(
                          text: AppStrings.homeGreeting(
                            AppStrings.previewCustomerName,
                          ),
                        ),
                        HomeSearchField(onTap: () {}),
                        const SizedBox(height: 24),
                        const HomePreviewCategoryStrip(),
                        const SizedBox(height: 32),
                        const HomePreviewPromoBanner(),
                        const SizedBox(height: 32),
                        HomeSectionTitle(
                          title: AppStrings.nearbyMerchants,
                          trailing: Icon(
                            Icons.tune,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const HomePreviewMerchantCard(),
                      ],
                    ),
                  ),
                  const Positioned(
                    left: HomeLayout.margin,
                    right: HomeLayout.margin,
                    bottom: 16,
                    child: HomePreviewActiveOrderCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: HomeBottomBar(selectedIndex: 0, onSelect: (_) {}),
      ),
    );
  }
}
