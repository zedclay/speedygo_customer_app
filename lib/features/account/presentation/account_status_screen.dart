import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';

/// Honest destination for live account/legal routes that have no write API.
class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
    this.actionLabel,
    this.actionMessage,
    this.actionKey,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryKey,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final String? actionMessage;
  final Key? actionKey;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Key? secondaryKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(icon, size: 40, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          if (actionLabel != null && actionMessage != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              key: actionKey,
              onPressed: () => showNavBlocked(context, actionMessage!),
              child: Text(actionLabel!),
            ),
          ],
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              key: secondaryKey,
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
