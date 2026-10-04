import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

/// Onboarding carousel aligned to Stitch onboarding 01–03 (+ bienvenue chrome).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _page = PageController();
  int _index = 0;

  static const _muted = Color(0xFF64748B);
  static const _dotInactive = Color(0xFFCBD5E1);

  static const _slides = [
    (
      AppStrings.welcomeDiscoverEyebrow,
      AppStrings.welcomeDiscoverTitle,
      AppStrings.welcomeDiscoverBody,
      'assets/onboarding/discover.png',
    ),
    (
      AppStrings.welcomeOrderEyebrow,
      AppStrings.welcomeOrderTitle,
      AppStrings.welcomeOrderBody,
      'assets/onboarding/order.png',
    ),
    (
      AppStrings.welcomeTrackEyebrow,
      AppStrings.welcomeTrackTitle,
      AppStrings.welcomeTrackBody,
      'assets/onboarding/track.png',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(sessionControllerProvider.notifier).markWelcomeSeen();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Text(
                      AppStrings.welcomeWordmark,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1,
                        letterSpacing: 1.12,
                      ),
                    ),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: _muted,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.skip,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: _muted,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                        ),
                      )
                    else
                      const SizedBox(width: 32, height: 16),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const copyReserve = 176.0;
                      final artHeight = (constraints.maxHeight - copyReserve)
                          .clamp(160.0, constraints.maxWidth * 1.15);
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: artHeight,
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.outlineVariant
                                        .withValues(alpha: 0.1),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0F000000),
                                      blurRadius: 30,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        slide.$4,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                      ),
                                      const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0x00000000),
                                              Color(0x33000000),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.$1,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    height: 1.2,
                                    letterSpacing: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide.$2,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 31,
                                    height: 1.15,
                                    letterSpacing: -0.4,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.$3,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: _muted,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad > 0 ? 8 : 24),
              child: Column(
                children: [
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          right: i == _slides.length - 1 ? 0 : 6,
                        ),
                        height: 8,
                        width: active ? 24 : 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : _dotInactive,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (last) {
                          _finish();
                        } else {
                          _page.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 2,
                        shadowColor: const Color(0x330A4096),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            last ? AppStrings.start : AppStrings.next,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
