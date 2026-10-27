import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/features/addresses/data/geo_api.dart';
import 'package:speedygo_customer_app/features/addresses/data/place_session_token.dart';

void main() {
  test('autocomplete and details send a session token and omit blanks', () async {
    final captured = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add(options);
          if (options.path == ApiEndpoints.geoPlacesDetailsPath) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'configured': true,
                  'placeId': 'ChIJ-hydra',
                  'formattedAddress': 'Hydra, Alger',
                  'latitude': 36.748,
                  'longitude': 3.039,
                },
              ),
            );
            return;
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'configured': true,
                'suggestions': [
                  {'placeId': 'ChIJ-hydra', 'text': 'Hydra, Alger'},
                ],
              },
            ),
          );
        },
      ),
    );
    final client = GeoClient(dio);

    await client.autocomplete(q: 'Hydra', sessionToken: 'sess-1');
    expect(captured.single.path, ApiEndpoints.geoPlacesAutocompletePath);
    expect(captured.single.queryParameters['sessionToken'], 'sess-1');
    expect(captured.single.queryParameters['q'], 'Hydra');

    captured.clear();
    await client.autocomplete(q: 'Hydra', sessionToken: '  ');
    expect(captured.single.queryParameters.containsKey('sessionToken'), isFalse);

    captured.clear();
    final details = await client.placeDetails(
      placeId: 'ChIJ-hydra',
      language: 'ar',
      sessionToken: 'sess-1',
    );
    expect(details.formattedAddress, 'Hydra, Alger');
    expect(captured.single.queryParameters['sessionToken'], 'sess-1');
    expect(captured.single.queryParameters['language'], 'ar');
  });

  test('PlaceSessionToken is a UUID v4 and rotates', () {
    final first = PlaceSessionToken.create();
    final second = PlaceSessionToken.create();
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(first, matches(uuid));
    expect(second, matches(uuid));
    expect(first, isNot(second));
  });
}
