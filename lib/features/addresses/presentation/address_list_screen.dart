import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';

const _kAddressCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CustomerAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteAddressTitle),
        content: Text(AppStrings.deleteAddressBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            key: const Key('confirm-delete-address'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.confirmDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(addressBookProvider.notifier).delete(address.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(addressBookProvider);
    final selection = ref.watch(addressSelectionProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          AppStrings.addressesTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('add-address-appbar'),
            tooltip: AppStrings.addAddress,
            onPressed: () => context.push(AppRoutes.addressForm),
            icon: const Icon(Icons.add, color: AppColors.primary),
          ),
        ],
      ),
      body: _body(context, ref, book, selection.addressId),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00F9F9FF),
              AppColors.surface,
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              key: const Key('add-address-button'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.push(AppRoutes.addressForm),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(
                book.addresses.isEmpty
                    ? AppStrings.addAddress
                    : AppStrings.addAddressNew,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AddressUiState book,
    String? selectedId,
  ) {
    if (book.loading && book.addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (book.error != null && book.addresses.isEmpty) {
      return CatalogStatusView(
        message: book.error!,
        onRetry: () => ref.read(addressBookProvider.notifier).refresh(),
      );
    }
    if (book.addresses.isEmpty) {
      return CatalogStatusView(
        key: const Key('addresses-empty'),
        icon: Icons.location_on_outlined,
        message: AppStrings.addressesEmpty,
        retryLabel: AppStrings.addAddress,
        onRetry: () => context.push(AppRoutes.addressForm),
      );
    }

    final defaults = book.addresses.where((a) => a.isDefault).toList();
    final others = book.addresses.where((a) => !a.isDefault).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(addressBookProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        children: [
          if (book.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                book.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          if (book.actionError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                book.actionError!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          if (defaults.isNotEmpty) ...[
            Text(
              AppStrings.addressesDefaultSection.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            for (final address in defaults) ...[
              _AddressCard(
                address: address,
                selected: address.id == selectedId,
                mutating: book.mutating,
                onEdit: () =>
                    context.push(AppRoutes.addressFormFor(address.id)),
                onDelete: () => _confirmDelete(context, ref, address),
                onSetDefault: null,
              ),
              const SizedBox(height: 16),
            ],
          ],
          if (others.isNotEmpty) ...[
            Text(
              AppStrings.addressesOtherSection.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            for (final address in others) ...[
              _AddressCard(
                address: address,
                selected: address.id == selectedId,
                mutating: book.mutating,
                onEdit: () =>
                    context.push(AppRoutes.addressFormFor(address.id)),
                onDelete: () => _confirmDelete(context, ref, address),
                onSetDefault: () => ref
                    .read(addressBookProvider.notifier)
                    .setDefault(address.id),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.mutating,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final CustomerAddress address;
  final bool selected;
  final bool mutating;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  IconData get _labelIcon {
    final label = address.displayLabel.toLowerCase();
    if (label.contains('domicile') || label.contains('home')) {
      return Icons.home;
    }
    if (label.contains('travail') ||
        label.contains('bureau') ||
        label.contains('work')) {
      return Icons.work_outline;
    }
    return Icons.location_on_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('address-card-${address.id}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [_kAddressCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _labelIcon,
                  color: address.isDefault
                      ? AppColors.primary
                      : AppColors.outline,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.displayLabel.isEmpty
                        ? AppStrings.deliverToSaved
                        : address.displayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  _Badge(label: AppStrings.defaultAddressBadge,
                    uppercase: true,
                  ),
                ],
                if (selected) ...[
                  const SizedBox(width: 8),
                  _Badge(label: AppStrings.selectedAddressBadge),
                ],
                IconButton(
                  key: Key('edit-address-${address.id}'),
                  tooltip: AppStrings.editAddress,
                  onPressed: mutating ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.outline),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  key: Key('delete-address-${address.id}'),
                  tooltip: AppStrings.deleteAddress,
                  onPressed: mutating ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.outline),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.addressText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (onSetDefault != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('set-default-${address.id}'),
                  onPressed: mutating ? null : onSetDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(AppStrings.setAsDefault),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.uppercase = false});

  final String label;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final text = uppercase ? label.toUpperCase() : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: uppercase
            ? AppColors.onTertiaryContainer.withValues(alpha: 0.35)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: uppercase ? AppColors.tertiary : AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: uppercase ? 10 : null,
          letterSpacing: uppercase ? 0.3 : null,
        ),
      ),
    );
  }
}
