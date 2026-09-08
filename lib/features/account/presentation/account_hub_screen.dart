import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/features/account/presentation/logout_sheet.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

class AccountHubScreen extends ConsumerWidget {
  const AccountHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final name = session.customer?.displayName ?? AppStrings.appName;
    final phone = session.signedInPhone;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              AppStrings.tabProfile,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
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
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (phone != null)
                        Text(
                          PhoneInput.maskInternational(phone),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Compte',
              children: [
                _Row(
                  icon: Icons.location_on_outlined,
                  label: 'Adresses enregistrées',
                  onTap: () => context.push(AppRoutes.accountAddresses),
                ),
                _Row(
                  icon: Icons.payments_outlined,
                  label: 'Méthodes de paiement',
                  onTap: () => context.push(AppRoutes.checkoutMethod),
                ),
              ],
            ),
            _Section(
              title: 'Préférences',
              children: [
                _Row(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => context.push(AppRoutes.accountNotifications),
                ),
                _Row(
                  icon: Icons.language,
                  label: 'Langue',
                  subtitle: AppStrings.languageFrench,
                  onTap: () => context.push(AppRoutes.accountLanguage),
                ),
              ],
            ),
            _Section(
              title: 'Support',
              children: [
                _Row(
                  icon: Icons.help_outline,
                  label: 'Centre d’aide',
                  onTap: () => context.push(AppRoutes.supportNew),
                ),
                _Row(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Tickets de support',
                  onTap: () => context.push(AppRoutes.supportNew),
                ),
              ],
            ),
            _Section(
              title: 'Légal & Sécurité',
              children: [
                _Row(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () => context.push(AppRoutes.legalPrivacy),
                ),
                _Row(
                  icon: Icons.gavel,
                  label: 'Conditions d’utilisation',
                  onTap: () => context.push(AppRoutes.legalTerms),
                ),
                _Row(
                  icon: Icons.security,
                  label: 'Sécurité',
                  onTap: () => context.push(AppRoutes.accountSecurity),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => confirmLogout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.logout),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.accountDelete),
              child: const Text('Supprimer mon compte'),
            ),
            if (session.errorMessage != null)
              Text(
                session.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
          ],
        ),
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
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppColors.primary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class SearchTabScreen extends StatefulWidget {
  const SearchTabScreen({super.key});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openResults() {
    final q = _controller.text.trim();
    if (q.length < 2) {
      showNavBlocked(context, AppStrings.navBlocked);
      return;
    }
    context.push(AppRoutes.searchResultsQuery(q));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabSearch)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: AppStrings.searchHint,
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _openResults(),
          ),
          const SizedBox(height: 16),
          Text(
            'Recherches récentes vides. GET /customer/catalog/search n’est pas appelé.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _openResults,
            child: const Text('Voir les résultats (navigation)'),
          ),
        ],
      ),
    );
  }
}

class OrdersTabScreen extends StatelessWidget {
  const OrdersTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabOrders)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.ordersEmpty,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'GET /customer/orders n’est pas appelé.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class AlertsTabScreen extends StatelessWidget {
  const AlertsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabAlerts)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Boîte de réception vide. Push serveur non configuré.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Autorisations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.alertsPermission),
          ),
          ListTile(
            title: const Text('Préférences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.accountNotifications),
          ),
        ],
      ),
    );
  }
}
