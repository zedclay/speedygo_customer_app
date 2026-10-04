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

/// When false, the splash logo and loader stay still. Tests set this so
/// `pumpAndSettle` is not blocked by a repeating ticker.
final splashAnimateProvider = Provider<bool>((ref) => true);

final tokenCacheProvider = Provider<TokenCache>((ref) => TokenCache());

final sessionEpochProvider = Provider<SessionEpoch>((ref) => SessionEpoch());

class TokenCache {
  TokenPair? current;

  /// Invoked after the interceptor drops a revoked/invalid pair so UI
  /// cannot stay on Home with a cached customer name.
  Future<void> Function()? onAuthFailure;
}

class SessionEpoch {
  int value = 0;
}
