import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/token_refresher.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';

import '../helpers/fakes.dart';

void main() {
  test(
    'concurrent refresh calls share one attempt and persist rotation',
    () async {
      final auth = FakeAuthClient()
        ..refreshDelay = const Duration(milliseconds: 40);
      final store = MemorySessionStore();
      final cache = TokenCache();
      var generation = 0;
      final refresher = TokenRefresher(
        authApi: auth,
        store: store,
        cache: cache,
        currentGeneration: () => generation,
      );

      final results = await Future.wait([
        refresher.refresh('refresh-1-token-value'),
        refresher.refresh('refresh-1-token-value'),
        refresher.refresh('refresh-1-token-value'),
      ]);

      expect(auth.refreshCount, 1);
      expect(results.every((pair) => pair.accessToken == 'access-2'), isTrue);
      expect(store.value?.refreshToken, 'refresh-2-token-value');
      expect(cache.current?.accessToken, 'access-2');
      expect(refresher.refreshCount, 1);
    },
  );

  test('does not persist when generation changed during refresh', () async {
    final auth = FakeAuthClient()
      ..refreshDelay = const Duration(milliseconds: 20);
    final store = MemorySessionStore();
    final cache = TokenCache();
    var generation = 1;
    final refresher = TokenRefresher(
      authApi: auth,
      store: store,
      cache: cache,
      currentGeneration: () => generation,
    );

    final future = refresher.refresh('refresh-1-token-value');
    generation = 2;
    expect(future, throwsA(isA<ApiException>()));
    await expectLater(future, throwsA(isA<ApiException>()));
    expect(store.value, isNull);
  });

  test('ambiguous timeout is not retried by the refresher itself', () async {
    final auth = FakeAuthClient()
      ..refreshError = const RefreshAmbiguousException();
    final store = MemorySessionStore();
    final refresher = TokenRefresher(
      authApi: auth,
      store: store,
      cache: TokenCache(),
      currentGeneration: () => 0,
    );

    await expectLater(
      refresher.refresh('refresh-1-token-value'),
      throwsA(isA<RefreshAmbiguousException>()),
    );
    expect(store.value, isNull);
  });
}
