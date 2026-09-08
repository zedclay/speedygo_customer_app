import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/providers/app_providers.dart';
import 'package:speedygo_customer_app/core/widgets/app_placeholder.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appNameProvider);
    return AppPlaceholder(
      title: appName,
      message:
          'Application shell only. Customer features are not implemented yet.',
    );
  }
}
