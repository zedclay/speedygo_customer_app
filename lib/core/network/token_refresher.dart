import 'dart:async';

import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/data/auth_api.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

typedef SessionGeneration = int Function();

/// Single-flight refresh. Persists the rotated pair before releasing waiters.
class TokenRefresher {
  TokenRefresher({
    required this._authApi,
    required this._store,
    required this._cache,
    required this._currentGeneration,
  });

  final AuthClient _authApi;
  final SessionStore _store;
  final TokenCache _cache;
  final SessionGeneration _currentGeneration;

  Future<TokenPair>? _inFlight;
  int _refreshCount = 0;

  int get refreshCount => _refreshCount;

  Future<TokenPair> refresh(String refreshToken) {
    return _inFlight ??= _run(refreshToken);
  }

  Future<TokenPair> _run(String refreshToken) async {
    final generation = _currentGeneration();
    try {
      _refreshCount += 1;
      final pair = await _authApi.refresh(refreshToken);
      if (_currentGeneration() != generation) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      await _store.write(pair);
      if (_currentGeneration() != generation) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      _cache.current = pair;
      return pair;
    } finally {
      _inFlight = null;
    }
  }
}
