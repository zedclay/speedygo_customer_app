import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
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

TokenRefresher _refresher({
  required FakeAuthClient auth,
  required MemorySessionStore store,
  required TokenCache cache,
  int Function()? generation,
}) {
  store.value ??= _initial;
  cache.current ??= store.value;
  return TokenRefresher(
    authApi: auth,
    store: store,
    cache: cache,
    currentGeneration: generation ?? () => 0,
  );
}

void main() {
  test(
    'concurrent refresh calls share one attempt and persist rotation',
    () async {
      final auth = FakeAuthClient()
        ..refreshDelay = const Duration(milliseconds: 40);
      final store = MemorySessionStore();
      final cache = TokenCache();
      var generation = 0;
      final refresher = _refresher(
        auth: auth,
        store: store,
        cache: cache,
        generation: () => generation,
      );

      final results = await Future.wait([
        refresher.ensureFresh(failedAccessToken: 'access-1'),
        refresher.ensureFresh(failedAccessToken: 'access-1'),
        refresher.ensureFresh(failedAccessToken: 'access-1'),
      ]);

      expect(auth.refreshCount, 1);
      expect(auth.presentedRefreshTokens, ['refresh-1-token-value']);
      expect(results.every((pair) => pair.accessToken == 'access-2'), isTrue);
      expect(store.value?.refreshToken, 'refresh-2-token-value');
      expect(cache.current?.accessToken, 'access-2');
      expect(refresher.refreshCount, 1);
    },
  );

  test('delayed old access token does not start a second refresh', () async {
    final auth = FakeAuthClient();
    final store = MemorySessionStore();
    final cache = TokenCache();
    final refresher = _refresher(auth: auth, store: store, cache: cache);

    final first = await refresher.ensureFresh(failedAccessToken: 'access-1');
    expect(first.accessToken, 'access-2');
    expect(auth.refreshCount, 1);

    final late = await refresher.ensureFresh(failedAccessToken: 'access-1');
    expect(late.accessToken, 'access-2');
    expect(auth.refreshCount, 1);
    expect(auth.presentedRefreshTokens, ['refresh-1-token-value']);
  });

  test('does not persist when generation changed during refresh', () async {
    final auth = FakeAuthClient()
      ..refreshDelay = const Duration(milliseconds: 20);
    final store = MemorySessionStore();
    final cache = TokenCache();
    var generation = 1;
    final refresher = _refresher(
      auth: auth,
      store: store,
      cache: cache,
      generation: () => generation,
    );

    final future = refresher.ensureFresh(failedAccessToken: 'access-1');
    generation = 2;
    await expectLater(future, throwsA(isA<ApiException>()));
    expect(store.value?.accessToken, 'access-1');
    expect(cache.current?.accessToken, 'access-1');
  });

  test('stale refresh-pending after restart is not replayed', () async {
    final auth = FakeAuthClient();
    final store = MemorySessionStore()
      ..value = _initial
      ..refreshPending = true;
    final cache = TokenCache()..current = _initial;
    final refresher = TokenRefresher(
      authApi: auth,
      store: store,
      cache: cache,
      currentGeneration: () => 0,
    );

    await expectLater(
      refresher.ensureFresh(failedAccessToken: 'access-1'),
      throwsA(isA<RefreshAmbiguousException>()),
    );
    expect(auth.refreshCount, 0);
    expect(auth.presentedRefreshTokens, isEmpty);
    expect(store.value, isNull);
    expect(cache.current, isNull);
  });

  test('ambiguous timeout drops the pair and is not retried', () async {
    final auth = FakeAuthClient()
      ..refreshError = RefreshAmbiguousException();
    final store = MemorySessionStore();
    final cache = TokenCache();
    final refresher = _refresher(auth: auth, store: store, cache: cache);

    await expectLater(
      refresher.ensureFresh(failedAccessToken: 'access-1'),
      throwsA(isA<RefreshAmbiguousException>()),
    );
    expect(store.value, isNull);
    expect(cache.current, isNull);
    expect(auth.refreshCount, 1);

    auth.refreshError = null;
    await expectLater(
      refresher.ensureFresh(failedAccessToken: 'access-1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'AUTH_INVALID_TOKEN',
        ),
      ),
    );
    expect(auth.refreshCount, 1);
  });
}
