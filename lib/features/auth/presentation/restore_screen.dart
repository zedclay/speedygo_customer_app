import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';

/// Session restore UI aligned to Stitch `r_cup_ration_de_session_speedygo`.
/// Order/continuity card is omitted (no restore payload for in-progress orders).
class RestoreScreen extends ConsumerWidget {
  const RestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final retryable = session.phase == SessionPhase.restoreRetryable;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _RestoreMesh(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Center(
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            height: 32 / 24,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _StatusGlyph(retryable: retryable),
                        const SizedBox(height: 24),
                        Text(
                          retryable
                              ? AppStrings.restoreOfflineTitle
                              : AppStrings.restoreTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                height: 32 / 24,
                                color: AppColors.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            retryable
                                ? (session.errorMessage ??
                                    AppStrings.restoreOffline)
                                : AppStrings.restoreLoading,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 16,
                                  height: 24 / 16,
                                ),
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    bottomInset > 0 ? 8 : 24,
                  ),
                  child: retryable
                      ? Column(
                          children: [
                            SgPrimaryButton(
                              label: AppStrings.restoreRetry,
                              loading: session.busy,
                              onPressed: () {
                                ref
                                    .read(sessionControllerProvider.notifier)
                                    .retryRestore();
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  ref
                                      .read(sessionControllerProvider.notifier)
                                      .switchAccount();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                ),
                                child: const Text(
                                  AppStrings.restoreOtherAccount,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreMesh extends StatelessWidget {
  const _RestoreMesh();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.surface),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0x66D9E2FF),
                    Color(0x00D9E2FF),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0x66D3EE78),
                    Color(0x00D3EE78),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.retryable});

  final bool retryable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.tertiaryFixed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        retryable ? Icons.wifi_off_rounded : Icons.check_circle,
        color: AppColors.tertiary,
        size: 40,
      ),
    );
  }
}
