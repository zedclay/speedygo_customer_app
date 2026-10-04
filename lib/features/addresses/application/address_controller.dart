import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_api.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_models.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_selection_store.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/addresses/domain/address_policy.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';

final addressApiProvider = Provider<AddressClient>((ref) {
  return AddressApi(ref.watch(authInfrastructureProvider).dio);
});

final addressSelectionStoreProvider = Provider<AddressSelectionStore>((ref) {
  return SecureAddressSelectionStore();
});

final locationClientProvider = Provider<LocationClient>((ref) {
  return GeolocatorLocationClient();
});

class AddressUiState {
  const AddressUiState({
    this.loading = false,
    this.mutating = false,
    this.reconciling = false,
    this.addresses = const [],
    this.error,
    this.actionError,
    this.scope = '',
  });

  final bool loading;
  final bool mutating;
  final bool reconciling;
  final List<CustomerAddress> addresses;
  final String? error;
  final String? actionError;
  final String scope;

  CustomerAddress? get defaultAddress {
    for (final address in addresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return null;
  }

  CustomerAddress? byId(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final address in addresses) {
      if (address.id == id) {
        return address;
      }
    }
    return null;
  }

  AddressUiState copyWith({
    bool? loading,
    bool? mutating,
    bool? reconciling,
    List<CustomerAddress>? addresses,
    String? error,
    String? actionError,
    String? scope,
    bool clearError = false,
    bool clearActionError = false,
  }) {
    return AddressUiState(
      loading: loading ?? this.loading,
      mutating: mutating ?? this.mutating,
      reconciling: reconciling ?? this.reconciling,
      addresses: addresses ?? this.addresses,
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      scope: scope ?? this.scope,
    );
  }
}

class AddressBookController extends Notifier<AddressUiState> {
  Future<void> _queue = Future<void>.value();
  var _loadSeq = 0;

  @override
  AddressUiState build() {
    final scope = ref.watch(catalogScopeProvider);
    _loadSeq += 1;
    _queue = Future<void>.value();
    final seeded =
        ref.read(sessionControllerProvider).customer?.addresses ??
        const <CustomerAddress>[];
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(refresh());
    });
    return AddressUiState(loading: true, addresses: seeded, scope: scope);
  }

  String get _scope => ref.read(catalogScopeProvider);

  bool _isCurrent(String scope) {
    return ref.mounted && state.scope == scope && scope == _scope;
  }

  Future<T> _enqueue<T>(Future<T> Function() op) {
    final scope = _scope;
    late final Future<T> done;
    done = _queue.then((_) async {
      if (!_isCurrent(scope)) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      return op();
    });
    _queue = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  Future<void> refresh() async {
    final scope = _scope;
    final seq = ++_loadSeq;
    state = state.copyWith(
      loading: true,
      scope: scope,
      clearError: true,
      clearActionError: true,
    );
    try {
      final addresses = await ref.read(addressApiProvider).list();
      if (seq != _loadSeq || !_isCurrent(scope)) {
        return;
      }
      _commit(addresses: addresses, scope: scope);
    } catch (error) {
      if (seq != _loadSeq || !_isCurrent(scope)) {
        return;
      }
      state = state.copyWith(loading: false, error: _message(error));
    }
  }

  Future<bool> create(CreateAddressRequest request) {
    if (state.mutating) {
      return Future<bool>.value(false);
    }
    state = state.copyWith(mutating: true, clearActionError: true);
    return _enqueue(() => _create(request));
  }

  Future<bool> _create(CreateAddressRequest request) async {
    final scope = _scope;
    try {
      await ref.read(addressApiProvider).create(request);
      if (!_isCurrent(scope)) {
        return false;
      }
      await _reload(scope: scope);
      return true;
    } on AddressUncertainException {
      if (!_isCurrent(scope)) {
        return false;
      }
      return _reconcileCreate(scope: scope, request: request);
    } catch (error) {
      if (!_isCurrent(scope)) {
        return false;
      }
      state = state.copyWith(mutating: false, actionError: _message(error));
      return false;
    }
  }

  Future<bool> _reconcileCreate({
    required String scope,
    required CreateAddressRequest request,
  }) async {
    state = state.copyWith(mutating: true, reconciling: true);
    try {
      final addresses = await ref.read(addressApiProvider).list();
      if (!_isCurrent(scope)) {
        return false;
      }
      final confirmed = addresses.any(
        (address) => AddressPolicy.sameDraft(
          label: request.label,
          addressText: request.addressText,
          latitude: request.latitude,
          longitude: request.longitude,
          otherLabel: address.label,
          otherAddressText: address.addressText,
          otherLatitude: address.latitude,
          otherLongitude: address.longitude,
        ),
      );
      _commit(
        addresses: addresses,
        scope: scope,
        actionError: confirmed ? null : AppStrings.addressSaveUnconfirmed,
      );
      return confirmed;
    } catch (_) {
      if (!_isCurrent(scope)) {
        return false;
      }
      state = state.copyWith(
        mutating: false,
        reconciling: false,
        actionError: AppStrings.addressSaveUnconfirmed,
      );
      return false;
    }
  }

  Future<bool> update({
    required String addressId,
    required UpdateAddressRequest request,
  }) {
    if (state.mutating) {
      return Future<bool>.value(false);
    }
    if (CatalogIds.isFixture(addressId) || addressId.isEmpty) {
      return Future<bool>.value(false);
    }
    state = state.copyWith(mutating: true, clearActionError: true);
    return _enqueue(() async {
      final scope = _scope;
      try {
        await ref
            .read(addressApiProvider)
            .update(addressId: addressId, request: request);
        if (!_isCurrent(scope)) {
          return false;
        }
        await _reload(scope: scope);
        return true;
      } catch (error) {
        if (!_isCurrent(scope)) {
          return false;
        }
        state = state.copyWith(mutating: false, actionError: _message(error));
        return false;
      }
    });
  }

  Future<bool> delete(String addressId) {
    if (state.mutating) {
      return Future<bool>.value(false);
    }
    if (CatalogIds.isFixture(addressId) || addressId.isEmpty) {
      return Future<bool>.value(false);
    }
    state = state.copyWith(mutating: true, clearActionError: true);
    return _enqueue(() async {
      final scope = _scope;
      try {
        await ref.read(addressApiProvider).delete(addressId);
        if (!_isCurrent(scope)) {
          return false;
        }
        await ref.read(addressSelectionProvider.notifier).clearIf(addressId);
        await _reload(scope: scope);
        return true;
      } catch (error) {
        if (!_isCurrent(scope)) {
          return false;
        }
        state = state.copyWith(mutating: false, actionError: _message(error));
        return false;
      }
    });
  }

  Future<bool> setDefault(String addressId) {
    if (state.mutating) {
      return Future<bool>.value(false);
    }
    if (CatalogIds.isFixture(addressId) || addressId.isEmpty) {
      return Future<bool>.value(false);
    }
    state = state.copyWith(mutating: true, clearActionError: true);
    return _enqueue(() async {
      final scope = _scope;
      try {
        await ref.read(addressApiProvider).setDefault(addressId);
        if (!_isCurrent(scope)) {
          return false;
        }
        await _reload(scope: scope);
        return true;
      } catch (error) {
        if (!_isCurrent(scope)) {
          return false;
        }
        state = state.copyWith(mutating: false, actionError: _message(error));
        return false;
      }
    });
  }

  Future<void> _reload({required String scope}) async {
    final addresses = await ref.read(addressApiProvider).list();
    if (!_isCurrent(scope)) {
      return;
    }
    _commit(addresses: addresses, scope: scope);
  }

  void _commit({
    required List<CustomerAddress> addresses,
    required String scope,
    String? actionError,
  }) {
    state = AddressUiState(
      addresses: addresses,
      scope: scope,
      actionError: actionError,
    );
    ref.read(sessionControllerProvider.notifier).applyAddressBook(addresses);
    unawaited(ref.read(addressSelectionProvider.notifier).reconcile(addresses));
  }

  String _message(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return AppStrings.errorForCode(null);
  }
}

final addressBookProvider =
    NotifierProvider<AddressBookController, AddressUiState>(
      AddressBookController.new,
    );

class AddressSelectionState {
  const AddressSelectionState({this.profileId, this.addressId});

  final String? profileId;
  final String? addressId;
}

/// Temporary Home selection, scoped to the current CustomerProfile.
/// Logout / account switch rebuilds via [catalogScopeProvider] and ignores
/// records that belong to another profile. Deleting the selected address
/// clears it. This never writes the server default.
class AddressSelectionController extends Notifier<AddressSelectionState> {
  @override
  AddressSelectionState build() {
    ref.watch(catalogScopeProvider);
    final profileId = ref.read(sessionControllerProvider).customer?.profile?.id;
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      unawaited(_restore(profileId));
    });
    return AddressSelectionState(profileId: profileId);
  }

  Future<void> _restore(String? profileId) async {
    final stored = await ref.read(addressSelectionStoreProvider).read();
    if (!ref.mounted) {
      return;
    }
    final current = ref.read(sessionControllerProvider).customer?.profile?.id;
    if (current == null) {
      if (stored != null) {
        await ref.read(addressSelectionStoreProvider).clear();
      }
      if (ref.mounted) {
        state = const AddressSelectionState();
      }
      return;
    }
    if (state.profileId == current && state.addressId != null) {
      return;
    }
    if (stored == null || stored.profileId != current) {
      if (stored != null) {
        await ref.read(addressSelectionStoreProvider).clear();
      }
      if (ref.mounted) {
        state = AddressSelectionState(profileId: current);
      }
      return;
    }
    state = AddressSelectionState(
      profileId: stored.profileId,
      addressId: stored.addressId,
    );
  }

  Future<void> select(String addressId) async {
    final profileId = ref.read(sessionControllerProvider).customer?.profile?.id;
    if (profileId == null ||
        profileId.isEmpty ||
        CatalogIds.isFixture(addressId) ||
        addressId.isEmpty) {
      return;
    }
    final record = AddressSelectionRecord(
      profileId: profileId,
      addressId: addressId,
    );
    await ref.read(addressSelectionStoreProvider).write(record);
    if (!ref.mounted) {
      return;
    }
    state = AddressSelectionState(profileId: profileId, addressId: addressId);
  }

  Future<void> clearIf(String addressId) async {
    if (state.addressId != addressId) {
      return;
    }
    await ref.read(addressSelectionStoreProvider).clear();
    if (!ref.mounted) {
      return;
    }
    state = AddressSelectionState(profileId: state.profileId);
  }

  Future<void> reconcile(List<CustomerAddress> addresses) async {
    final selectedId = state.addressId;
    if (selectedId == null) {
      return;
    }
    final exists = addresses.any((address) => address.id == selectedId);
    if (!exists) {
      await clearIf(selectedId);
    }
  }
}

final addressSelectionProvider =
    NotifierProvider<AddressSelectionController, AddressSelectionState>(
      AddressSelectionController.new,
    );

class PendingLocationFix extends Notifier<DeviceLocation?> {
  @override
  DeviceLocation? build() => null;

  void set(DeviceLocation fix) {
    state = fix;
  }

  void clear() {
    state = null;
  }
}

final pendingLocationFixProvider =
    NotifierProvider<PendingLocationFix, DeviceLocation?>(
      PendingLocationFix.new,
    );

/// Home chip label: temporary selection if still in the book, else server
/// default, else unset. Home stays usable with no address.
String homeAddressLabel({
  required AddressUiState book,
  required AddressSelectionState selection,
  String? sessionFallback,
}) {
  final selected = book.byId(selection.addressId);
  if (selected != null) {
    final label = selected.displayLabel;
    if (label.isNotEmpty) {
      return label;
    }
  }
  final fallbackDefault = book.defaultAddress;
  if (fallbackDefault != null) {
    final label = fallbackDefault.displayLabel;
    if (label.isNotEmpty) {
      return label;
    }
  }
  if (book.loading && sessionFallback != null && sessionFallback.isNotEmpty) {
    return sessionFallback;
  }
  return AppStrings.deliverToUnset;
}
