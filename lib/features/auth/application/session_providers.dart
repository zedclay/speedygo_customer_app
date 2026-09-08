import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SecureSessionStore();
});

final launchStoreProvider = Provider<LaunchStore>((ref) {
  return SecureLaunchStore();
});

final splashMinDurationProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 1800);
});

final tokenCacheProvider = Provider<TokenCache>((ref) => TokenCache());

final sessionEpochProvider = Provider<SessionEpoch>((ref) => SessionEpoch());

class TokenCache {
  TokenPair? current;
}

class SessionEpoch {
  int value = 0;
}
