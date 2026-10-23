import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

/// Sheet lift from Stitch `d_connexion_speedygo`.
const _kAccountCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const LogoutSheet(),
  );
  if (confirmed == true) {
    await ref.read(sessionControllerProvider.notifier).logout();
  }
}

class LogoutSheet extends ConsumerWidget {
  const LogoutSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final name = session.customer?.displayName ?? AppStrings.appName;
    final phone = session.signedInPhone ?? session.pendingPhone;
    final initials = initialsFor(name);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.logoutConfirmTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: const [_kAccountCardShadow],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD9E2FF),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          initials,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceContainerLowest,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (phone != null && phone.isNotEmpty)
                        BidiLtr(
                          child: Text(
                            PhoneInput.maskInternational(phone),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.smartphone,
                            size: 14,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              AppStrings.logoutSessionActive.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.tertiary,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _LogoutNote(
                  icon: Icons.local_shipping,
                  text: AppStrings.logoutNoteOrders,
                ),
                const SizedBox(height: 16),
                _LogoutNote(
                  icon: Icons.notifications_active,
                  text: AppStrings.logoutNoteReconnect,
                ),
                const SizedBox(height: 16),
                _LogoutNote(
                  icon: Icons.security,
                  text: AppStrings.logoutNoteSafe,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SgPrimaryButton(
            label: AppStrings.logoutConfirmAction,
            icon: Icons.logout,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              child: Text(AppStrings.cancel),
            ),
          ),
        ],
      ),
    );
  }

  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'SG';
    }
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }
}

class _LogoutNote extends StatelessWidget {
  const _LogoutNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: AppColors.primaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
