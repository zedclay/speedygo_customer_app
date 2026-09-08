import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/network/health_client.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final minDuration = ref.read(splashMinDurationProvider);
    final config = ref.read(apiConfigProvider);
    await Future.wait<void>([
      Future<void>.delayed(minDuration),
      HealthClient(config).ping().then((_) {}),
    ]);
    if (!mounted) {
      return;
    }
    await ref.read(sessionControllerProvider.notifier).restore();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppTheme.splashMid,
              AppTheme.splashDeep,
            ],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Image.asset(
                'assets/branding/speedygo_logo.png',
                width: 256,
                height: 256,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: AppStrings.appName,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 72, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: AppColors.onPrimary,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
            ),
            Text(
              AppStrings.splashLoading,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'VERSION ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.4),
                letterSpacing: 1.6,
              ),
            ),
            SizedBox(height: 24 + bottom),
          ],
        ),
      ),
    );
  }
}
