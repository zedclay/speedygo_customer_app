import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/auth/application/active_sessions_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

/// Stitch `s_curit_et_sessions_actives_speedygo` — honest OTP (no invented 2FA).
const _kSessionCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeSessionsControllerProvider);
    final phone = ref.watch(sessionControllerProvider).signedInPhone;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        shadowColor: const Color(0x14000000),
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          AppStrings.securityTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(activeSessionsControllerProvider.notifier).refresh(),
        child: _body(context, ref, state, phone),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    ActiveSessionsState state,
    String? phone,
  ) {
    if (state.loading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('sessions-loading')),
      );
    }
    if (state.errorMessage != null && state.activeItems.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            state.errorMessage!,
            key: const Key('sessions-error'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('sessions-retry'),
            onPressed: () =>
                ref.read(activeSessionsControllerProvider.notifier).refresh(),
            child: const Text(AppStrings.retry),
          ),
        ],
      );
    }

    final active = state.activeItems;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330A4096),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: AppColors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.securityOtpGuidanceTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.securityOtpGuidance,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.securityAccountHeading.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.outline,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: const [_kSessionCardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.smartphone,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.securityVerifiedPhone,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                      Text(
                        phone ?? '—',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.tertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.securitySessionsHeading.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.outline,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (state.infoMessage != null) ...[
          Text(
            state.infoMessage!,
            key: const Key('sessions-info'),
            style: const TextStyle(color: AppColors.tertiary),
          ),
          const SizedBox(height: 8),
        ],
        if (state.errorMessage != null) ...[
          Text(
            state.errorMessage!,
            key: const Key('sessions-inline-error'),
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 8),
        ],
        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              AppStrings.securityEmpty,
              key: Key('sessions-empty'),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...active.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SessionTile(
                session: session,
                enabled: !state.mutating,
                onRevoke: () => _confirmRevoke(context, ref, session),
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            key: const Key('sessions-logout-all'),
            onPressed: state.mutating
                ? null
                : () => _confirmLogoutAll(context, ref),
            icon: const Icon(Icons.no_accounts_outlined),
            label: const Text(AppStrings.securityLogoutAll),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            key: const Key('sessions-report'),
            onPressed: () => context.push(AppRoutes.supportNew),
            icon: const Icon(Icons.report_problem_outlined, size: 20),
            label: const Text(AppStrings.securityReportSuspicious),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    AuthSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          session.currentSession
              ? AppStrings.securityRevokeCurrentTitle
              : AppStrings.securityRevokeTitle,
        ),
        content: Text(
          session.currentSession
              ? AppStrings.securityRevokeCurrentBody
              : AppStrings.securityRevokeBody,
        ),
        actions: [
          TextButton(
            key: const Key('sessions-revoke-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            key: const Key('sessions-revoke-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.securityRevokeConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref
        .read(activeSessionsControllerProvider.notifier)
        .revokeSession(session.id);
  }

  Future<void> _confirmLogoutAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.securityLogoutAllTitle),
        content: const Text(AppStrings.securityLogoutAllBody),
        actions: [
          TextButton(
            key: const Key('sessions-logout-all-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            key: const Key('sessions-logout-all-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.securityLogoutAllConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(activeSessionsControllerProvider.notifier).logoutAll();
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.enabled,
    required this.onRevoke,
  });

  final AuthSession session;
  final bool enabled;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final title = _sessionTitle(session);
    final subtitle = _sessionSubtitle(session);
    final isCurrent = session.currentSession;
    return DecoratedBox(
      key: Key('session-tile-${session.id}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.primaryContainer
              : AppColors.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: const [_kSessionCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _platformIcon(session.platform),
              color: isCurrent ? AppColors.primary : AppColors.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryFixed,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            AppStrings.securityCurrentPill,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF171E00),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              key: Key('session-revoke-${session.id}'),
              tooltip: AppStrings.securityRevoke,
              onPressed: enabled ? onRevoke : null,
              icon: Icon(
                Icons.logout,
                color: enabled
                    ? AppColors.onSurfaceVariant
                    : AppColors.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _sessionTitle(AuthSession session) {
  final name = session.deviceName?.trim();
  final platform = session.platform?.trim();
  if (session.currentSession) {
    if (name != null && name.isNotEmpty) {
      return '${AppStrings.securityCurrentBadge} ($name)';
    }
    if (platform != null && platform.isNotEmpty) {
      return '${AppStrings.securityCurrentBadge} ($platform)';
    }
    return AppStrings.securityCurrentBadge;
  }
  if (name != null && name.isNotEmpty) {
    return name;
  }
  if (platform != null && platform.isNotEmpty) {
    return platform;
  }
  return 'Session';
}

String _sessionSubtitle(AuthSession session) {
  final created = _formatTimestamp(session.createdAt);
  if (created.isEmpty) {
    return '';
  }
  return 'Créée $created';
}

String _formatTimestamp(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) {
    return '';
  }
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year} $hour:$minute';
}

IconData _platformIcon(String? platform) {
  switch (platform?.toLowerCase()) {
    case 'ios':
      return Icons.phone_iphone;
    case 'android':
      return Icons.phone_android;
    case 'web':
      return Icons.laptop;
    default:
      return Icons.devices;
  }
}
