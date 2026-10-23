import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/geo_api.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/addresses/data/map_config.dart';
import 'package:speedygo_customer_app/features/addresses/domain/address_policy.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';

class LocationPickResult {
  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String? formattedAddress;
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
  final _mapController = MapController();
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
    _mapController.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd ||
        event is MapEventMove ||
        event is MapEventFlingAnimationEnd) {
      _unfocusSearch();
      final next = event.camera.center;
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
      });
    }
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
      _mapController.move(target, CustomerMapConfig.confirmedZoom);
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
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = const [];
        _searchMessage = null;
      });
      return;
    }
    final generation = _generation;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_runSearch(q, generation));
    });
  }

  Future<void> _runSearch(String q, int generation) async {
    setState(() {
      _searchBusy = true;
      _searchMessage = null;
    });
    try {
      final hits = await ref
          .read(geoClientProvider)
          .autocomplete(
            q: q,
            language: AppStrings.languageCode,
            generation: generation,
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
    final generation = ++_generation;
    _search.text = hit.text;
    setState(() {
      _suggestions = const [];
      _searchBusy = true;
      _searchMessage = null;
    });
    try {
      final details = await ref
          .read(geoClientProvider)
          .placeDetails(placeId: hit.placeId);
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
      _mapController.move(target, CustomerMapConfig.confirmedZoom);
      setState(() {
        _center = target;
        _selectionReady = true;
        _searchBusy = false;
        _searchMessage = null;
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
    final generation = _generation;
    String? formatted;
    try {
      formatted = await ref
          .read(geoClientProvider)
          .reverseGeocode(
            latitude: lat,
            longitude: lng,
            language: AppStrings.languageCode,
          );
    } on GeocodingNotConfiguredException {
      formatted = null;
    } catch (_) {
      formatted = null;
    }
    if (!mounted || generation != _generation) {
      return;
    }
    Navigator.of(context).pop(
      LocationPickResult(
        latitude: lat,
        longitude: lng,
        formattedAddress: formatted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = (widget.addressHint ?? '').trim();
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
                  if (_searchMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        _searchMessage!,
                        key: const Key('customer-location-search-message'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  if (_suggestions.isNotEmpty)
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
                        child: Stack(
                          children: [
                            FlutterMap(
                              key: const Key('customer-location-map'),
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _center,
                                initialZoom: _hadConfirmedInitial
                                    ? CustomerMapConfig.confirmedZoom
                                    : CustomerMapConfig.explorationZoom,
                                minZoom: 5,
                                maxZoom: 19,
                                onMapReady: () =>
                                    setState(() => _mapReady = true),
                                onMapEvent: _onMapEvent,
                                onTap: (tapPosition, point) => _unfocusSearch(),
                                interactionOptions: const InteractionOptions(
                                  flags:
                                      InteractiveFlag.all &
                                      ~InteractiveFlag.rotate,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      CustomerMapConfig.tileUrlTemplate,
                                  userAgentPackageName:
                                      CustomerMapConfig.userAgentPackageName,
                                  maxNativeZoom: 19,
                                  tileProvider: NetworkTileProvider(
                                    cachingProvider:
                                        const DisabledMapCachingProvider(),
                                  ),
                                ),
                                const RichAttributionWidget(
                                  attributions: [
                                    TextSourceAttribution(
                                      CustomerMapConfig.osmAttribution,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IgnorePointer(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 36),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              const BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20),
                                                bottomRight: Radius.circular(
                                                  20,
                                                ),
                                              ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.place,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      Container(
                                        width: 3,
                                        height: 14,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Material(
                                color: AppColors.surface,
                                elevation: 4,
                                borderRadius: BorderRadius.circular(12),
                                child: IconButton(
                                  key: const Key('customer-location-use-gps'),
                                  tooltip: AppStrings.useMyLocation,
                                  onPressed: _gpsBusy ? null : _useMyLocation,
                                  icon: _gpsBusy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
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
                                if (CustomerMapConfig.usingDefaultOsmTiles)
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
                            onPressed: _selectionReady && _mapReady
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
