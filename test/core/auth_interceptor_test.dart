import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_client.dart';
import 'package:speedygo_customer_app/core/network/api_config.dart';
import 'package:speedygo_customer_app/core/network/token_refresher.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

import '../helpers/fakes.dart';

const _initial = TokenPair(
  accessToken: 'access-1',
  refreshToken: 'refresh-1-token-value',
  expiresIn: 900,
  tokenType: 'Bearer',
);

ResponseBody _json(int status, [Map<String, dynamic>? body]) {
  return ResponseBody.fromString(
    jsonEncode(body ?? {'ok': true}),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ResponseBody _unauthorized() {
  return _json(401, {
    'error': {
      'code': 'AUTH_INVALID_TOKEN',
      'message': 'Authentication required',
    },
  });
}

class _AuthAwareAdapter implements HttpClientAdapter {
  _AuthAwareAdapter({this.delayAccess1Paths = const {}, this.releaseAccess1});

  final Set<String> delayAccess1Paths;
  final Future<void>? releaseAccess1;
  int calls = 0;
  final authorizations = <String?>[];
  final paths = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    authorizations.add(options.headers['Authorization']?.toString());
    paths.add(options.path);
    final access = options.headers['Authorization']?.toString();
    if (access == 'Bearer access-1' &&
        delayAccess1Paths.contains(options.path) &&
        releaseAccess1 != null) {
      await releaseAccess1;
    }
    if (access == 'Bearer access-1') {
      return _unauthorized();
    }
    if (access == 'Bearer access-2') {
      return _json(200);
    }
    return _unauthorized();
  }
}

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

({
  Dio dio,
  FakeAuthClient auth,
  TokenRefresher refresher,
  MemorySessionStore store,
  TokenCache cache,
})
_client({
  required HttpClientAdapter adapter,
  FakeAuthClient? auth,
  int Function()? generation,
  OnSessionInvalid? onSessionInvalid,
  Duration? refreshDelay,
}) {
  final store = MemorySessionStore()..value = _initial;
  final cache = TokenCache()..current = _initial;
  final fake = auth ?? FakeAuthClient();
  if (refreshDelay != null) {
    fake.refreshDelay = refreshDelay;
  }
  var epoch = 0;
  final refresher = TokenRefresher(
    authApi: fake,
    store: store,
    cache: cache,
    currentGeneration: generation ?? () => epoch,
  );
  const config = ApiConfig(apiBaseUrl: 'http://127.0.0.1:3000/api/v1');
  final dio = createApiClient(
    config: config,
    readSession: () async => cache.current ?? await store.read(),
    refresher: refresher,
    onSessionInvalid:
        onSessionInvalid ??
        () async {
          cache.current = null;
          await store.clear();
          epoch += 1;
        },
  );
  dio.httpClientAdapter = adapter;
  return (
    dio: dio,
    auth: fake,
    refresher: refresher,
    store: store,
    cache: cache,
  );
}

void main() {
  test(
    '401 triggers one refresh then retries with rotated access token',
    () async {
      final adapter = _ScriptedAdapter([
        (_) => _unauthorized(),
        (_) => _json(200),
      ]);
      final client = _client(adapter: adapter);

      final response = await client.dio.get<Map<String, dynamic>>(
        '/customer/me',
      );
      expect(response.statusCode, 200);
      expect(client.auth.refreshCount, 1);
      expect(adapter.authorizations[0], 'Bearer access-1');
      expect(adapter.authorizations[1], 'Bearer access-2');
      expect(client.store.value?.accessToken, 'access-2');
    },
  );

  test(
    'concurrent 401s from different Home clients cause one refresh',
    () async {
      final adapter = _AuthAwareAdapter();
      final client = _client(
        adapter: adapter,
        refreshDelay: const Duration(milliseconds: 40),
      );

      final responses = await Future.wait([
        client.dio.get<Map<String, dynamic>>('/customer/commerce-verticals'),
        client.dio.get<Map<String, dynamic>>('/customer/branches'),
        client.dio.get<Map<String, dynamic>>('/customer/promotions'),
        client.dio.get<Map<String, dynamic>>(
          '/customer/ratings/merchant-summaries',
        ),
      ]);

      expect(responses.every((item) => item.statusCode == 200), isTrue);
      expect(client.auth.refreshCount, 1);
      expect(client.auth.presentedRefreshTokens, ['refresh-1-token-value']);
      expect(client.store.value?.accessToken, 'access-2');
    },
  );

  test('delayed old-token 401 after rotation does not refresh again', () async {
    final released = Completer<void>();
    final adapter = _AuthAwareAdapter(
      delayAccess1Paths: {'/customer/promotions'},
      releaseAccess1: released.future,
    );
    final client = _client(adapter: adapter);

    late final Future<Response<Map<String, dynamic>>> lateRequest;
    lateRequest = client.dio.get<Map<String, dynamic>>('/customer/promotions');
    await Future<void>.delayed(const Duration(milliseconds: 15));
    final early = await client.dio.get<Map<String, dynamic>>(
      '/customer/commerce-verticals',
    );
    expect(early.statusCode, 200);
    expect(client.auth.refreshCount, 1);
    released.complete();
    final late = await lateRequest;
    expect(late.statusCode, 200);
    expect(client.auth.refreshCount, 1);
    expect(client.auth.presentedRefreshTokens, ['refresh-1-token-value']);
  });

  test('logout during refresh cannot restore the session', () async {
    final adapter = _AuthAwareAdapter();
    final store = MemorySessionStore()..value = _initial;
    final cache = TokenCache()..current = _initial;
    final auth = FakeAuthClient()
      ..refreshDelay = const Duration(milliseconds: 40);
    var generation = 1;
    final refresher = TokenRefresher(
      authApi: auth,
      store: store,
      cache: cache,
      currentGeneration: () => generation,
    );
    var invalidated = 0;
    const config = ApiConfig(apiBaseUrl: 'http://127.0.0.1:3000/api/v1');
    final dio = createApiClient(
      config: config,
      readSession: () async => cache.current ?? await store.read(),
      refresher: refresher,
      onSessionInvalid: () async {
        invalidated += 1;
        cache.current = null;
        await store.clear();
        generation += 1;
      },
    );
    dio.httpClientAdapter = adapter;

    final pending = dio.get<Map<String, dynamic>>('/customer/me');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    generation += 1;
    cache.current = null;
    await store.clear();

    await expectLater(pending, throwsA(isA<DioException>()));
    expect(store.value, isNull);
    expect(cache.current, isNull);
    expect(invalidated, 1);
    expect(auth.refreshCount, 1);
  });

  test('refresh timeout does not reuse the old refresh token', () async {
    final auth = FakeAuthClient()
      ..refreshError = const RefreshAmbiguousException();
    final adapter = _AuthAwareAdapter();
    final client = _client(adapter: adapter, auth: auth);

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/customer/me'),
      throwsA(isA<DioException>()),
    );
    expect(client.auth.refreshCount, 1);
    expect(client.store.value, isNull);
    expect(client.cache.current, isNull);

    client.auth.refreshError = null;
    await expectLater(
      client.dio.get<Map<String, dynamic>>('/customer/branches'),
      throwsA(isA<DioException>()),
    );
    expect(client.auth.refreshCount, 1);
    expect(client.auth.presentedRefreshTokens, ['refresh-1-token-value']);
  });
}
