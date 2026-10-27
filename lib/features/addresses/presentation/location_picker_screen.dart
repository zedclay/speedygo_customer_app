import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/geo_api.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/addresses/data/map_config.dart';
import 'package:speedygo_customer_app/features/addresses/data/place_session_token.dart';
import 'package:speedygo_customer_app/features/addresses/domain/address_policy.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/location_map_surface.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';

class LocationPickResult {
  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.fromPlaceSelection = false,
  });

  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final bool fromPlaceSelection;
}

final geoClientProvider = Provider<GeoClient>((ref) {
  return GeoClient(ref.watch(authInfrastructureProvider).dio);
});

/// Fixed centre pin. The map moves under the pin. GPS is a suggestion only.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.addressHint,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String? addressHint;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  LocationMapController? _map;
  final _search = TextEditingController();
  late LatLng _center;
  late bool _selectionReady;
  var _gpsBusy = false;
  var _searchBusy = false;
  var _mapReady = false;
  var _generation = 0;
  String? _gpsMessage;
  String? _searchMessage;
  List<PlaceSuggestion> _suggestions = const [];
  Timer? _debounce;
  var _placeSessionToken = PlaceSessionToken.create();
  String _lastQuery = '';
  String? _placeFormatted;
  var _movedSincePlaceSelect = true;

  bool get _hadConfirmedInitial {
    final lat = widget.initialLatitude;
    final lng = widget.initialLongitude;
    return lat != null &&
        lng != null &&
        AddressPolicy.isUsablePoint(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    if (_hadConfirmedInitial) {
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectionReady = true;
    } else {
      _center = const LatLng(
        CustomerMapConfig.explorationLatitude,
        CustomerMapConfig.explorationLongitude,
      );
      _selectionReady = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onCameraIdle(double latitude, double longitude) {
    final next = LatLng(latitude, longitude);
    final moved =
        (next.latitude - _center.latitude).abs() > 1e-7 ||
        (next.longitude - _center.longitude).abs() > 1e-7;
    if (!moved && !_hadConfirmedInitial) {
      return;
    }
    setState(() {
      _center = next;
      _selectionReady = true;
      _generation += 1;
      _suggestions = const [];
      _movedSincePlaceSelect = true;
      _placeSessionToken = PlaceSessionToken.create();
    });
  }

  Future<void> _useMyLocation() async {
    final generation = ++_generation;
    setState(() {
      _gpsBusy = true;
      _gpsMessage = null;
    });
    final client = ref.read(locationClientProvider);
    try {
      final access = await client.requestAccess();
      if (!mounted || generation != _generation) {
        return;
      }
      switch (access) {
        case LocationAccess.denied:
          setState(() {
            _gpsBusy = false;
            _gpsMessage = AppStrings.locationGpsDenied;
          });
          return;
        case LocationAccess.deniedForever:
          setState(() {
            _gpsBusy = false;
            _gpsMessage = AppStrings.locationGpsDeniedForever;
          });
          return;
        case LocationAccess.servicesDisabled:
          setState(() {
            _gpsBusy = false;
            _gpsMessage = AppStrings.locationGpsDenied;
          });
          return;
        case LocationAccess.granted:
          break;
      }
      final fix = await client.readCurrent();
      if (!mounted || generation != _generation) {
        return;
      }
      if (!AddressPolicy.isUsablePoint(fix.latitude, fix.longitude)) {
        setState(() {
          _gpsBusy = false;
          _gpsMessage = AppStrings.locationUnavailable;
        });
        return;
      }
      final target = LatLng(fix.latitude, fix.longitude);
      await _map?.moveTo(
        target.latitude,
        target.longitude,
        CustomerMapConfig.confirmedZoom,
      );
      setState(() {
        _center = target;
        _selectionReady = true;
        _gpsBusy = false;
        _gpsMessage = null;
      });
    } on LocationUnavailableException {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _gpsBusy = false;
        _gpsMessage = AppStrings.locationUnavailable;
      });
    } catch (_) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _gpsBusy = false;
        _gpsMessage = AppStrings.locationUnavailable;
      });
    }
  }

  void _onSearchChanged(String raw) {
    if (!ref.read(mapRuntimeConfigProvider).placesLookupEnabled) {
      return;
    }
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = const [];
        _searchMessage = null;
        _lastQuery = '';
      });
      return;
    }
    final generation = _generation;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_runSearch(q, generation));
    });
  }

  bool get _searchCanRetry =>
      _lastQuery.length >= 2 &&
      (_searchMessage == AppStrings.locationSearchFailed ||
          _searchMessage == AppStrings.locationSearchUnavailable);

  Future<void> _runSearch(String q, int generation) async {
    if (!ref.read(mapRuntimeConfigProvider).placesLookupEnabled) {
      return;
    }
    setState(() {
      _searchBusy = true;
      _lastQuery = q;
      _searchMessage = AppStrings.locationSearchLoading;
    });
    try {
      final hits = await ref
          .read(geoClientProvider)
          .autocomplete(
            q: q,
            language: AppStrings.languageCode,
            generation: generation,
            sessionToken: _placeSessionToken,
          );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _searchBusy = false;
        _suggestions = hits;
        _searchMessage = hits.isEmpty ? AppStrings.locationSearchEmpty : null;
      });
    } on GeocodingNotConfiguredException {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _searchBusy = false;
        _suggestions = const [];
        _searchMessage = AppStrings.locationSearchUnavailable;
      });
    } catch (_) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _searchBusy = false;
        _suggestions = const [];
        _searchMessage = AppStrings.locationSearchFailed;
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion hit) async {
    if (!ref.read(mapRuntimeConfigProvider).placesLookupEnabled) {
      return;
    }
    final generation = ++_generation;
    _search.text = hit.text;
    setState(() {
      _suggestions = const [];
      _searchBusy = true;
      _searchMessage = AppStrings.locationSearchLoading;
    });
    try {
      final details = await ref
          .read(geoClientProvider)
          .placeDetails(
            placeId: hit.placeId,
            language: AppStrings.languageCode,
            sessionToken: _placeSessionToken,
          );
      if (!mounted || generation != _generation) {
        return;
      }
      if (!AddressPolicy.isUsablePoint(details.latitude, details.longitude)) {
        setState(() {
          _searchBusy = false;
          _searchMessage = AppStrings.locationSearchFailed;
        });
        return;
      }
      final target = LatLng(details.latitude, details.longitude);
      await _map?.moveTo(
        target.latitude,
        target.longitude,
        CustomerMapConfig.confirmedZoom,
      );
      setState(() {
        _center = target;
        _selectionReady = true;
        _searchBusy = false;
        _searchMessage = null;
        _placeFormatted = details.formattedAddress;
        _movedSincePlaceSelect = false;
      });
      if (details.formattedAddress != null &&
          details.formattedAddress!.isNotEmpty) {
        _search.text = details.formattedAddress!;
      }
    } on GeocodingNotConfiguredException {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _searchBusy = false;
        _searchMessage = AppStrings.locationSearchUnavailable;
      });
    } catch (_) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _searchBusy = false;
        _searchMessage = AppStrings.locationSearchFailed;
      });
    } finally {
      _placeSessionToken = PlaceSessionToken.create();
    }
  }

  Future<void> _confirm() async {
    if (!_selectionReady) {
      return;
    }
    final lat = _center.latitude;
    final lng = _center.longitude;
    if (!AddressPolicy.isUsablePoint(lat, lng)) {
      return;
    }
    final fromPlace =
        !_movedSincePlaceSelect &&
        (_placeFormatted?.trim().isNotEmpty ?? false);
    Navigator.of(context).pop(
      LocationPickResult(
        latitude: lat,
        longitude: lng,
        formattedAddress: fromPlace ? _placeFormatted!.trim() : null,
        fromPlaceSelection: fromPlace,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = (widget.addressHint ?? '').trim();
    final runtime = ref.watch(mapRuntimeConfigProvider);
    final lookups = runtime.placesLookupEnabled;
    final mode = runtime.mode;
    final searchMessage = !lookups
        ? (mode == MapRenderMode.osmDev
              ? AppStrings.locationSearchDisabledOnDevMap
              : AppStrings.locationMapUnavailable)
        : _searchMessage;
    return Scaffold(
      key: const Key('customer-location-picker'),
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: AppColors.surface.withValues(alpha: 0.96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('customer-location-back'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.locationPickerTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      key: const Key('customer-location-search'),
                      controller: _search,
                      enabled: lookups,
                      onChanged: _onSearchChanged,
                      onTapOutside: (_) => _unfocusSearch(),
                      decoration: InputDecoration(
                        hintText: AppStrings.locationSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchBusy
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (searchMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            searchMessage,
                            key: const Key('customer-location-search-message'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          if (_searchCanRetry)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: const Key('customer-location-search-retry'),
                                onPressed: _searchBusy
                                    ? null
                                    : () => unawaited(
                                        _runSearch(_lastQuery, _generation),
                                      ),
                                child: Text(AppStrings.retry),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (lookups && _suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final hit = _suggestions[index];
                          return ListTile(
                            key: Key('customer-location-suggestion-$index'),
                            dense: true,
                            title: Text(hit.text),
                            onTap: () => unawaited(_selectSuggestion(hit)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sheetMax = (constraints.maxHeight * 0.34).clamp(
                    72.0,
                    200.0,
                  );
                  return Column(
                    children: [
                      Expanded(
                        child: mode == MapRenderMode.unavailable
                            ? const ColoredBox(
                                key: Key('customer-location-map-unavailable'),
                                color: Color(0xFFE8EEF4),
                                child: SizedBox.expand(),
                              )
                            : Stack(
                                children: [
                                  LocationMapSurface(
                                    key: const Key('customer-location-map'),
                                    mode: mode,
                                    useStub: ref.watch(locationMapStubProvider),
                                    initialLatitude: _center.latitude,
                                    initialLongitude: _center.longitude,
                                    initialZoom: _hadConfirmedInitial
                                        ? CustomerMapConfig.confirmedZoom
                                        : CustomerMapConfig.explorationZoom,
                                    onReady: () =>
                                        setState(() => _mapReady = true),
                                    onCameraIdle: _onCameraIdle,
                                    onInteraction: _unfocusSearch,
                                    onCreated: (controller) =>
                                        _map = controller,
                                  ),
                                  const LocationFixedPin(),
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Material(
                                      color: AppColors.surface,
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(12),
                                      child: IconButton(
                                        key: const Key(
                                          'customer-location-use-gps',
                                        ),
                                        tooltip: AppStrings.useMyLocation,
                                        onPressed: _gpsBusy
                                            ? null
                                            : _useMyLocation,
                                        icon: _gpsBusy
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.my_location,
                                                color: AppColors.primary,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: sheetMax),
                        child: Material(
                          color: AppColors.surface,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (hint.isNotEmpty)
                                  Text(
                                    hint,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                if (_gpsMessage != null)
                                  Text(
                                    _gpsMessage!,
                                    key: const Key(
                                      'customer-location-gps-message',
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                if (!_selectionReady)
                                  Text(
                                    AppStrings.locationPickerMoveHint,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                if (mode == MapRenderMode.unavailable)
                                  Text(
                                    AppStrings.locationMapUnavailable,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                if (mode == MapRenderMode.google)
                                  const Text(
                                    'Google Maps',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Color(0xFF5E5E5E),
                                    ),
                                  ),
                                if (mode == MapRenderMode.osmDev)
                                  Text(
                                    AppStrings.locationMapTilesDev,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: AppColors.surface,
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SgPrimaryButton(
                            key: const Key('customer-location-confirm'),
                            label: AppStrings.locationPickerConfirm,
                            icon: Icons.check_circle_outline,
                            onPressed:
                                mode != MapRenderMode.unavailable &&
                                    _selectionReady &&
                                    _mapReady
                                ? _confirm
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
