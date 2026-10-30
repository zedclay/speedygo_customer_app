import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/features/account/presentation/logout_sheet.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

/// Visual tokens from Stitch `profil_speedygo_1` (list chrome only).
const _kSecondaryContainer = Color(0xFF94A6FF);
const _kOnSecondaryContainer = Color(0xFF24388B);
const _kProfileCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class AccountHubScreen extends ConsumerWidget {
  const AccountHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final name = session.customer?.displayName ?? AppStrings.appName;
    final phone = session.signedInPhone;

    return Scaffold(
      key: const Key('account-hub'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              AppStrings.tabProfile,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _ProfileHeaderCard(name: name, phone: phone),
            const SizedBox(height: 24),
            _Section(
              title: AppStrings.accountSectionAccount,
              children: [
                _Row(
                  key: const Key('account-addresses'),
                  icon: Icons.location_on_outlined,
                  label: AppStrings.accountAddressesLabel,
                  onTap: () => context.push(AppRoutes.accountAddresses),
                ),
                _Row(
                  key: const Key('account-payment-methods'),
                  icon: Icons.payments_outlined,
                  label: AppStrings.accountPaymentMethodsTitle,
                  onTap: () => context.push(AppRoutes.accountPaymentMethods),
                  showDivider: false,
                ),
              ],
            ),
            _Section(
              title: AppStrings.accountSectionPreferences,
              children: [
                _Row(
                  key: const Key('account-notifications'),
                  icon: Icons.notifications_outlined,
                  label: AppStrings.accountNotificationsSettingsTitle,
                  onTap: () => context.push(AppRoutes.accountNotifications),
                ),
                _Row(
                  key: const Key('account-language'),
                  icon: Icons.language,
                  label: AppStrings.accountLanguageLabel,
                  subtitle: AppLocale.isArabic(session.locale)
                      ? AppStrings.languageArabic
                      : AppStrings.languageFrench,
                  onTap: () => context.push(AppRoutes.accountLanguage),
                  showDivider: false,
                ),
              ],
            ),
            _Section(
              title: AppStrings.accountSectionSupport,
              children: [
                _Row(
                  key: const Key('account-support-new'),
                  icon: Icons.help_outline,
                  label: AppStrings.supportCentreAide,
                  onTap: () => context.push(AppRoutes.accountSupportNew),
                ),
                _Row(
                  key: const Key('account-support'),
                  icon: Icons.confirmation_number_outlined,
                  label: AppStrings.supportTicketsLabel,
                  onTap: () => context.push(AppRoutes.accountSupport),
                  showDivider: false,
                ),
              ],
            ),
            _Section(
              title: AppStrings.accountSectionLegal,
              children: [
                _Row(
                  key: const Key('account-legal-privacy'),
                  icon: Icons.privacy_tip_outlined,
                  label: AppStrings.legalPrivacyTitle,
                  onTap: () => context.push(AppRoutes.accountLegalPrivacy),
                ),
                _Row(
                  key: const Key('account-legal-terms'),
                  icon: Icons.gavel,
                  label: AppStrings.legalTermsTitle,
                  onTap: () => context.push(AppRoutes.accountLegalTerms),
                ),
                _Row(
                  key: const Key('account-security'),
                  icon: Icons.security,
                  label: AppStrings.accountSecurityLabel,
                  onTap: () => context.push(AppRoutes.accountSecurity),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                key: const Key('account-logout'),
                onPressed: () => confirmLogout(context, ref),
                icon: const Icon(Icons.logout),
                label: Text(
                  AppStrings.logoutConfirmAction,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: AppColors.surfaceContainerLowest,
                  side: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                key: const Key('account-delete'),
                onPressed: () => context.push(AppRoutes.accountDelete),
                icon: const Icon(Icons.delete_forever, size: 18),
                label: Text(AppStrings.accountDeleteTitle),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.outline,
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            if (session.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                session.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.name, this.phone});

  final String name;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_kProfileCardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              LogoutSheet.initialsFor(name),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.call_outlined,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          PhoneInput.maskInternational(phone!),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [_kProfileCardShadow],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kSecondaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: _kOnSecondaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.outline),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
