import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_models.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/addresses/domain/address_policy.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/location_picker_screen.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_scope.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _label = TextEditingController();
  final _addressText = TextEditingController();
  final _building = TextEditingController();
  final _floor = TextEditingController();
  final _entrance = TextEditingController();
  final _landmark = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  String? _labelError;
  String? _textError;
  String? _pointError;
  var _hydrated = false;
  var _pointConfirmed = false;

  bool get _isEdit {
    final id = widget.addressId;
    return id != null && id.isNotEmpty && id != 'new';
  }

  @override
  void initState() {
    super.initState();
    _hydrateFromBook();
  }

  @override
  void dispose() {
    _label.dispose();
    _addressText.dispose();
    _building.dispose();
    _floor.dispose();
    _entrance.dispose();
    _landmark.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  void _hydrateFromBook() {
    if (!_isEdit || _hydrated) {
      return;
    }
    final existing = ref.read(addressBookProvider).byId(widget.addressId);
    if (existing == null) {
      return;
    }
    _applyAddress(existing);
    _hydrated = true;
  }

  void _applyAddress(CustomerAddress address) {
    _label.text = address.label;
    _addressText.text = address.addressText;
    _building.text = address.building ?? '';
    _floor.text = address.floor ?? '';
    _entrance.text = address.entrance ?? '';
    _landmark.text = address.landmark ?? '';
    if (address.latitude != null && address.longitude != null) {
      _applyPoint(address.latitude!, address.longitude!);
    }
  }

  void _applyPoint(double latitude, double longitude) {
    _latitude.text = latitude.toString();
    _longitude.text = longitude.toString();
    _pointConfirmed = AddressPolicy.isUsablePoint(latitude, longitude);
    _pointError = _pointConfirmed ? null : AppStrings.addressPointRequired;
  }

  void _applyFix(DeviceLocation fix) {
    _applyPoint(fix.latitude, fix.longitude);
    setState(() {});
  }

  bool _validate() {
    final labelError = AddressPolicy.validateLabel(_label.text);
    final textError = AddressPolicy.validateAddressText(_addressText.text);
    final lat = AddressPolicy.parseCoordinate(_latitude.text);
    final lng = AddressPolicy.parseCoordinate(_longitude.text);
    final pointOk =
        lat != null && lng != null && AddressPolicy.isUsablePoint(lat, lng);
    setState(() {
      _labelError = switch (labelError) {
        'empty' => AppStrings.addressLabelRequired,
        'tooLong' => AppStrings.addressLabelTooLong,
        _ => null,
      };
      _textError = switch (textError) {
        'empty' => AppStrings.addressTextRequired,
        'tooLong' => AppStrings.addressTextTooLong,
        _ => null,
      };
      _pointError = pointOk ? null : AppStrings.addressPointRequired;
    });
    return _labelError == null && _textError == null && pointOk;
  }

  Future<void> _openPicker() async {
    final lat = AddressPolicy.parseCoordinate(_latitude.text);
    final lng = AddressPolicy.parseCoordinate(_longitude.text);
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: lat,
          initialLongitude: lng,
          addressHint: _addressText.text.trim(),
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _applyPoint(result.latitude, result.longitude);
      final formatted = result.formattedAddress?.trim();
      // Autocomplete selected-street exception: fill empty street only.
      // Never rewrite a saved addressText. Reverse-geocode text is not stored.
      if (result.fromPlaceSelection &&
          formatted != null &&
          formatted.isNotEmpty &&
          _addressText.text.trim().isEmpty) {
        _addressText.text = formatted;
      }
    });
  }

  Future<void> _save() async {
    if (!_validate()) {
      return;
    }
    final latitude = AddressPolicy.parseCoordinate(_latitude.text)!;
    final longitude = AddressPolicy.parseCoordinate(_longitude.text)!;
    final addressText = _addressText.text.trim();
    final book = ref.read(addressBookProvider.notifier);
    final ok = _isEdit
        ? await book.update(
            addressId: widget.addressId!,
            request: UpdateAddressRequest(
              label: _label.text.trim(),
              addressText: addressText,
              latitude: latitude,
              longitude: longitude,
              building: _building.text,
              floor: _floor.text,
              entrance: _entrance.text,
              landmark: _landmark.text,
              patchDetails: true,
            ),
          )
        : await book.create(
            CreateAddressRequest(
              label: _label.text.trim(),
              addressText: addressText,
              latitude: latitude,
              longitude: longitude,
              building: _building.text,
              floor: _floor.text,
              entrance: _entrance.text,
              landmark: _landmark.text,
            ),
          );
    if (!mounted) {
      return;
    }
    if (ok) {
      CustomerAddress? match;
      for (final address in ref.read(addressBookProvider).addresses) {
        if (AddressPolicy.sameDraft(
          label: _label.text.trim(),
          addressText: addressText,
          latitude: latitude,
          longitude: longitude,
          building: _building.text,
          floor: _floor.text,
          entrance: _entrance.text,
          landmark: _landmark.text,
          otherLabel: address.label,
          otherAddressText: address.addressText,
          otherLatitude: address.latitude,
          otherLongitude: address.longitude,
          otherBuilding: address.building,
          otherFloor: address.floor,
          otherEntrance: address.entrance,
          otherLandmark: address.landmark,
        )) {
          match = address;
          break;
        }
      }
      if (match != null) {
        await ref.read(addressSelectionProvider.notifier).select(match.id);
      }
      if (!mounted) {
        return;
      }
      SgSnack.success(context, message: AppStrings.addressSaved);
      popOrParent(context);
      return;
    }
    final actionError = ref.read(addressBookProvider).actionError;
    if (actionError != null) {
      SgSnack.error(context, message: actionError);
    }
  }

  void _selectChip(String value) {
    setState(() {
      _label.text = value;
      _labelError = null;
    });
  }

  bool _chipSelected(String value) =>
      _label.text.trim().toLowerCase() == value.toLowerCase();

  @override
  Widget build(BuildContext context) {
    ref.listen(addressBookProvider, (previous, next) {
      if (_isEdit && !_hydrated) {
        final existing = next.byId(widget.addressId);
        if (existing != null) {
          _applyAddress(existing);
          _hydrated = true;
        }
      }
    });
    ref.listen(pendingLocationFixProvider, (previous, next) {
      if (next == null) {
        return;
      }
      _applyFix(next);
      ref.read(pendingLocationFixProvider.notifier).clear();
    });
    final book = ref.watch(addressBookProvider);
    final existing = _isEdit ? book.byId(widget.addressId) : null;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    const fieldScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 140);
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          _isEdit ? AppStrings.editAddress : AppStrings.addAddress,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isEdit && !book.loading && existing == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppStrings.addressNotFound,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                180 + keyboardBottom,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (book.actionError != null) ...[
                  Text(
                    book.actionError!,
                    key: const Key('address-form-error'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  AppStrings.addressTypeLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LabelChip(
                      label: AppStrings.addressLabelHome,
                      icon: Icons.home,
                      selected: _chipSelected(AppStrings.addressLabelHome),
                      onTap: () => _selectChip(AppStrings.addressLabelHome),
                    ),
                    _LabelChip(
                      label: AppStrings.addressLabelWork,
                      icon: Icons.work_outline,
                      selected: _chipSelected(AppStrings.addressLabelWork),
                      onTap: () => _selectChip(AppStrings.addressLabelWork),
                    ),
                    _LabelChip(
                      label: AppStrings.addressLabelOther,
                      icon: Icons.location_on_outlined,
                      selected: _chipSelected(AppStrings.addressLabelOther),
                      onTap: () => _selectChip(AppStrings.addressLabelOther),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.addressWilayaField,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                FilterChip(
                  key: const Key('address-wilaya-field'),
                  selected:
                      ref.watch(launchWilayaCodeProvider) ==
                      LaunchWilaya.sidiBelAbbes,
                  label: const Text('Sidi Bel Abbès'),
                  onSelected: book.mutating
                      ? null
                      : (_) => ref
                            .read(launchWilayaCodeProvider.notifier)
                            .select(LaunchWilaya.sidiBelAbbes),
                ),
                Text(
                  AppStrings.addressWilayaHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (book.addresses.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.addressFirstDefaultHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  key: const Key('address-label-field'),
                  controller: _label,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: AddressPolicy.labelMaxLength,
                  scrollPadding: fieldScrollPadding,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: AppStrings.addressLabelField,
                    hintText: AppStrings.addressLabelHint,
                    errorText: _labelError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('address-text-field'),
                  controller: _addressText,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: AddressPolicy.addressTextMaxLength,
                  scrollPadding: fieldScrollPadding,
                  decoration: InputDecoration(
                    labelText: AppStrings.addressTextField,
                    hintText: AppStrings.addressTextHint,
                    errorText: _textError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.addressCoordsHint,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('address-choose-map'),
                  onPressed: book.mutating ? null : _openPicker,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    _pointConfirmed
                        ? AppStrings.addressPointConfirmed
                        : AppStrings.addressChooseOnMap,
                  ),
                ),
                if (_pointError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _pointError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('use-my-location'),
                  onPressed: book.mutating
                      ? null
                      : () => context.push(AppRoutes.locationPermission),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.my_location),
                  label: Text(AppStrings.useMyLocation),
                ),
                Offstage(
                  offstage: true,
                  child: Column(
                    children: [
                      TextField(
                        key: const Key('address-latitude-field'),
                        controller: _latitude,
                        onChanged: (_) {
                          final lat = AddressPolicy.parseCoordinate(
                            _latitude.text,
                          );
                          final lng = AddressPolicy.parseCoordinate(
                            _longitude.text,
                          );
                          setState(() {
                            _pointConfirmed =
                                lat != null &&
                                lng != null &&
                                AddressPolicy.isUsablePoint(lat, lng);
                          });
                        },
                      ),
                      TextField(
                        key: const Key('address-longitude-field'),
                        controller: _longitude,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('address-building-field'),
                  controller: _building,
                  maxLength: AddressPolicy.buildingMaxLength,
                  scrollPadding: fieldScrollPadding,
                  decoration: InputDecoration(
                    labelText: AppStrings.addressBuildingField,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('address-floor-field'),
                  controller: _floor,
                  maxLength: AddressPolicy.floorMaxLength,
                  scrollPadding: fieldScrollPadding,
                  decoration: InputDecoration(
                    labelText: AppStrings.addressFloorField,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('address-entrance-field'),
                  controller: _entrance,
                  maxLength: AddressPolicy.entranceMaxLength,
                  scrollPadding: fieldScrollPadding,
                  decoration: InputDecoration(
                    labelText: AppStrings.addressEntranceField,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('address-landmark-field'),
                  controller: _landmark,
                  maxLength: AddressPolicy.landmarkMaxLength,
                  scrollPadding: fieldScrollPadding,
                  decoration: InputDecoration(
                    labelText: AppStrings.addressLandmarkField,
                    counterText: '',
                  ),
                ),
                if (book.reconciling) ...[
                  const SizedBox(height: 16),
                  Text(AppStrings.addressReconciling),
                ],
                if (book.actionError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    book.actionError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: _isEdit && !book.loading && existing == null
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: keyboardBottom),
              child: SafeArea(
                maintainBottomViewPadding: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SgPrimaryButton(
                    key: const Key('address-save-button'),
                    label: book.mutating
                        ? AppStrings.addressSaving
                        : AppStrings.saveAddress,
                    loading: book.mutating,
                    onPressed: book.mutating ? null : _save,
                  ),
                ),
              ),
            ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
