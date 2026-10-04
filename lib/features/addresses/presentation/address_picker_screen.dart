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

class AddressPickerScreen extends ConsumerWidget {
  const AddressPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(addressBookProvider);
    final selection = ref.watch(addressSelectionProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(AppStrings.addressPickerTitle),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.addressForm),
            child: const Text(AppStrings.addAddressShort),
          ),
        ],
      ),
      body: _body(context, ref, book, selection.addressId),
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
        key: const Key('picker-empty'),
        icon: Icons.location_on_outlined,
        message: AppStrings.addressPickerEmpty,
        retryLabel: AppStrings.addAddress,
        onRetry: () => context.push(AppRoutes.addressForm),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const Text(
          AppStrings.addressSelectionHint,
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        for (final address in book.addresses) ...[
          _PickerTile(
            address: address,
            selected: address.id == selectedId,
            enabled: !book.mutating,
            onTap: () async {
              await ref
                  .read(addressSelectionProvider.notifier)
                  .select(address.id);
              if (context.mounted) {
                popOrParent(context);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.address,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final CustomerAddress address;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('picker-address-${address.id}'),
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.displayLabel.isEmpty
                          ? AppStrings.deliverToSaved
                          : address.displayLabel,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.addressText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.defaultAddressBadge,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
