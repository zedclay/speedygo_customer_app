import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';

class RestoreScreen extends ConsumerWidget {
  const RestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final retryable = session.phase == SessionPhase.restoreRetryable;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  retryable ? Icons.wifi_off : Icons.check_circle,
                  color: AppColors.tertiary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                retryable
                    ? AppStrings.restoreOfflineTitle
                    : AppStrings.restoreTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                retryable
                    ? (session.errorMessage ?? AppStrings.restoreOffline)
                    : AppStrings.restoreLoading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const Spacer(),
              if (retryable) ...[
                SgPrimaryButton(
                  label: AppStrings.restoreRetry,
                  loading: session.busy,
                  onPressed: () {
                    ref.read(sessionControllerProvider.notifier).retryRestore();
                  },
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(sessionControllerProvider.notifier)
                        .switchAccount();
                  },
                  child: const Text(AppStrings.restoreOtherAccount),
                ),
              ] else
                const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
