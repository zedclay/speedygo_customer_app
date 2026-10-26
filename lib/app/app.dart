import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/providers/app_providers.dart';
import 'package:speedygo_customer_app/app/router/app_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/notifications/presentation/customer_push_host.dart';

class SpeedyGoApp extends ConsumerWidget {
  const SpeedyGoApp({super.key});

  static const _arabicFallback = [
    'Geeza Pro',
    'Noto Naskh Arabic',
    'Noto Sans Arabic',
    'SF Arabic',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final title = ref.watch(appNameProvider);
    final localeCode = ref.watch(
      sessionControllerProvider.select((state) => state.locale),
    );
    final sanitized = AppLocale.sanitize(localeCode);
    final locale = Locale(sanitized);
    AppStrings.bind(sanitized);

    return MaterialApp.router(
      title: title,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final rtl = sanitized == AppLocale.arabic;
        Widget content = Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
        if (rtl) {
          content = DefaultTextStyle.merge(
            style: const TextStyle(fontFamilyFallback: _arabicFallback),
            child: content,
          );
        }
        return CustomerPushHost(child: content);
      },
      routerConfig: router,
    );
  }
}
