import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/network/api_client.dart';
import 'package:speedygo_customer_app/core/network/api_config.dart';
import 'package:speedygo_customer_app/core/network/token_refresher.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

import '../helpers/fakes.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.script);

  final List<ResponseBody Function(RequestOptions)> script;
  int calls = 0;
  final authorizations = <String?>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorizations.add(options.headers['Authorization']?.toString());
    final index = calls;
    calls += 1;
    return script[index](options);
  }
}

void main() {
  test(
    '401 triggers one refresh then retries with rotated access token',
    () async {
      final store = MemorySessionStore()
        ..value = const TokenPair(
          accessToken: 'access-1',
          refreshToken: 'refresh-1-token-value',
          expiresIn: 900,
          tokenType: 'Bearer',
        );
      final cache = TokenCache()..current = store.value;
      final auth = FakeAuthClient();
      final refresher = TokenRefresher(
        authApi: auth,
        store: store,
        cache: cache,
        currentGeneration: () => 0,
      );
      const config = ApiConfig(apiBaseUrl: 'http://127.0.0.1:3000/api/v1');
      final dio = createApiClient(
        config: config,
        readSession: () async => cache.current,
        refresher: refresher,
      );
      final adapter = _ScriptedAdapter([
        (_) => ResponseBody.fromString(
          jsonEncode({
            'error': {
              'code': 'AUTH_INVALID_TOKEN',
              'message': 'Authentication required',
            },
          }),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
        (_) => ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      ]);
      dio.httpClientAdapter = adapter;

      final response = await dio.get<Map<String, dynamic>>('/customer/me');
      expect(response.statusCode, 200);
      expect(auth.refreshCount, 1);
      expect(adapter.authorizations[0], 'Bearer access-1');
      expect(adapter.authorizations[1], 'Bearer access-2');
      expect(store.value?.accessToken, 'access-2');
    },
  );
}
