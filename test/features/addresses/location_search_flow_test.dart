import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/addresses/data/geo_api.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/addresses/data/map_config.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/location_picker_screen.dart';

import '../../helpers/fakes.dart';

class FakeGeoClient extends GeoClient {
  FakeGeoClient() : super(Dio());

  List<PlaceSuggestion> suggestions = const [];
  Object? autocompleteError;
  PlaceDetails details = const PlaceDetails(
    placeId: 'ChIJ-hydra',
    latitude: 36.748,
    longitude: 3.039,
    formattedAddress: 'Hydra, Alger',
  );
  Object? detailsError;
  String? lastSessionToken;
  var autocompleteCalls = 0;
  var detailsCalls = 0;

  @override
  Future<List<PlaceSuggestion>> autocomplete({
    required String q,
    String language = 'fr',
    int generation = 0,
    String? sessionToken,
  }) async {
    autocompleteCalls += 1;
    lastSessionToken = sessionToken;
    if (autocompleteError != null) {
      throw autocompleteError!;
    }
    return suggestions;
  }

  @override
  Future<PlaceDetails> placeDetails({
    required String placeId,
    String language = 'fr',
    String? sessionToken,
  }) async {
    detailsCalls += 1;
    lastSessionToken = sessionToken;
    if (detailsError != null) {
      throw detailsError!;
    }
    return details;
  }

  @override
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
    String language = 'fr',
  }) async {
    return 'Hydra, Alger';
  }
}

Widget _picker({
  required FakeGeoClient geo,
  FakeLocationClient? location,
  double? initialLatitude,
  double? initialLongitude,
  MapRuntimeConfig runtime = const MapRuntimeConfig(
    googleMapsReady: true,
    osmDevMode: false,
  ),
}) {
  return ProviderScope(
    overrides: [
      mapRuntimeConfigProvider.overrideWithValue(runtime),
      locationMapStubProvider.overrideWithValue(true),
      geoClientProvider.overrideWithValue(geo),
      locationClientProvider.overrideWithValue(
        location ?? FakeLocationClient(access: LocationAccess.denied),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: LocationPickerScreen(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStrings.bind('fr'));

  test('search copy is French and Arabic without exposing coordinates', () {
    AppStrings.bind('fr');
    expect(AppStrings.locationSearchLoading, 'Recherche en cours…');
    expect(AppStrings.locationSearchEmpty, contains('Aucun résultat'));
    expect(AppStrings.locationSearchFailed, contains('Réessayez'));
    expect(AppStrings.locationSearchUnavailable, contains('carte'));
    expect(AppStrings.locationMapUnavailable, contains('configuré'));
    expect(AppStrings.locationSearchDisabledOnDevMap, contains('désactivée'));
    AppStrings.bind('ar');
    expect(AppStrings.locationSearchLoading, 'جاري البحث…');
    expect(AppStrings.locationSearchUnavailable, contains('غير مُعدّ'));
    expect(AppStrings.locationSearchEmpty, contains('لا توجد نتائج'));
    expect(AppStrings.retry, 'إعادة المحاولة');
    AppStrings.bind('fr');
  });

  testWidgets('GPS denied keeps the map and does not show raw coordinates', (
    tester,
  ) async {
    final geo = FakeGeoClient();
    await tester.pumpWidget(
      _picker(
        geo: geo,
        initialLatitude: 36.75,
        initialLongitude: 3.05,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('customer-location-use-gps')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.locationGpsDenied), findsOneWidget);
    expect(find.byKey(const Key('customer-location-map')), findsOneWidget);
    expect(find.textContaining('36.75'), findsNothing);
    expect(find.textContaining('3.05'), findsNothing);
    final cta = tester.widget<SgPrimaryButton>(
      find.byKey(const Key('customer-location-confirm')),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('unavailable search shows retry and leaves map selection usable', (
    tester,
  ) async {
    final geo = FakeGeoClient()
      ..autocompleteError = const GeocodingNotConfiguredException();
    await tester.pumpWidget(
      _picker(
        geo: geo,
        initialLatitude: 36.75,
        initialLongitude: 3.05,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
      find.byKey(const Key('customer-location-search')),
      'Hydra',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AppStrings.locationSearchUnavailable), findsOneWidget);
    expect(find.byKey(const Key('customer-location-search-retry')), findsOneWidget);
    await tester.tap(find.byKey(const Key('customer-location-search-retry')));
    await tester.pump();
    expect(geo.autocompleteCalls, 2);
    expect(geo.lastSessionToken, isNotEmpty);
    expect(find.byKey(const Key('customer-location-map')), findsOneWidget);
    expect(find.textContaining('36.75'), findsNothing);
  });

  testWidgets('empty and failed search states stay on the map', (tester) async {
    final geo = FakeGeoClient();
    await tester.pumpWidget(_picker(geo: geo));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
      find.byKey(const Key('customer-location-search')),
      'Hydra',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AppStrings.locationSearchEmpty), findsOneWidget);

    geo.autocompleteError = Exception('provider down');
    await tester.enterText(
      find.byKey(const Key('customer-location-search')),
      'Alger centre',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AppStrings.locationSearchFailed), findsOneWidget);
    expect(find.byKey(const Key('customer-location-search-retry')), findsOneWidget);
    expect(find.byKey(const Key('customer-location-map')), findsOneWidget);
  });

  testWidgets('selecting a suggestion moves the pin but save waits for confirm', (
    tester,
  ) async {
    LocationPickResult? result;
    final geo = FakeGeoClient()
      ..suggestions = const [
        PlaceSuggestion(placeId: 'ChIJ-hydra', text: 'Hydra, Alger'),
      ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapRuntimeConfigProvider.overrideWithValue(
            const MapRuntimeConfig(googleMapsReady: true, osmDevMode: false),
          ),
          locationMapStubProvider.overrideWithValue(true),
          geoClientProvider.overrideWithValue(geo),
          locationClientProvider.overrideWithValue(
            FakeLocationClient(access: LocationAccess.denied),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<LocationPickResult>(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen(),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    var cta = tester.widget<SgPrimaryButton>(
      find.byKey(const Key('customer-location-confirm')),
    );
    expect(cta.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('customer-location-search')),
      'Hydra',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('customer-location-suggestion-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('customer-location-suggestion-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(geo.detailsCalls, 1);
    expect(geo.lastSessionToken, isNotEmpty);
    expect(find.textContaining('36.748'), findsNothing);
    expect(find.textContaining('3.039'), findsNothing);

    cta = tester.widget<SgPrimaryButton>(
      find.byKey(const Key('customer-location-confirm')),
    );
    expect(cta.onPressed, isNotNull);
    expect(result, isNull);

    await tester.tap(find.byKey(const Key('customer-location-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(result?.formattedAddress, 'Hydra, Alger');
    expect(result?.fromPlaceSelection, isTrue);
    expect(result?.latitude, closeTo(36.748, 0.0001));
  });

  testWidgets('OSM development mode disables Google lookups and keeps confirm', (
    tester,
  ) async {
    final geo = FakeGeoClient()
      ..suggestions = const [
        PlaceSuggestion(placeId: 'ChIJ-hydra', text: 'Hydra, Alger'),
      ];
    await tester.pumpWidget(
      _picker(
        geo: geo,
        initialLatitude: 36.75,
        initialLongitude: 3.05,
        runtime: const MapRuntimeConfig(
          googleMapsReady: false,
          osmDevMode: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text(AppStrings.locationSearchDisabledOnDevMap),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('customer-location-search')))
          .enabled,
      isFalse,
    );
    await tester.enterText(
      find.byKey(const Key('customer-location-search')),
      'Hydra',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(geo.autocompleteCalls, 0);
    expect(find.byKey(const Key('customer-location-map')), findsOneWidget);
    final cta = tester.widget<SgPrimaryButton>(
      find.byKey(const Key('customer-location-confirm')),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('missing Google configuration is an honest unavailable state', (
    tester,
  ) async {
    final geo = FakeGeoClient();
    await tester.pumpWidget(
      _picker(
        geo: geo,
        initialLatitude: 36.75,
        initialLongitude: 3.05,
        runtime: const MapRuntimeConfig(
          googleMapsReady: false,
          osmDevMode: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(AppStrings.locationMapUnavailable), findsWidgets);
    expect(
      find.byKey(const Key('customer-location-map-unavailable')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('customer-location-map')), findsNothing);
    final cta = tester.widget<SgPrimaryButton>(
      find.byKey(const Key('customer-location-confirm')),
    );
    expect(cta.onPressed, isNull);
    expect(geo.autocompleteCalls, 0);
  });
}
