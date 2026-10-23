/// Map / geocoding configuration for the Customer location picker.
///
/// Planned provider: Google Maps Platform (Places Autocomplete New + Geocoding).
/// `GOOGLE_MAPS_API_KEY` is empty in Backend `.env` — live search is fail-closed
/// via `GET /geo/places/autocomplete` (503 GEO_GEOCODING_NOT_CONFIGURED).
/// Default raster tiles are OSM public tiles for local/dev only.
class CustomerMapConfig {
  const CustomerMapConfig._();

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  static const _defaultOsmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const tileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL_TEMPLATE',
    defaultValue: _defaultOsmTileUrl,
  );

  static bool get usingDefaultOsmTiles => tileUrlTemplate == _defaultOsmTileUrl;

  static const osmAttribution = '© OpenStreetMap contributors';

  static const userAgentPackageName = 'com.speedygo.speedygoCustomerApp';

  /// Sidi Bel Abbès centre — camera start only, never auto-saved.
  static const explorationLatitude = 35.1939;
  static const explorationLongitude = -0.6417;
  static const explorationZoom = 13.0;
  static const confirmedZoom = 16.0;

  static String get configurationBlocker {
    final parts = <String>[
      if (!hasGoogleMapsKey)
        'GOOGLE_MAPS_API_KEY is empty. Places/Geocoding live verification is blocked.',
      if (usingDefaultOsmTiles)
        'MAP_TILE_URL_TEMPLATE unset — default OSM public tiles are not production-approved.',
    ];
    return parts.join(' ');
  }
}
