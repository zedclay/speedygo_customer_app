import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

/// Persists one coherent token pair. Never writes a half-updated session.
abstract class SessionStore {
  Future<TokenPair?> read();

  Future<void> write(TokenPair pair);

  Future<void> clear();

  /// True when a refresh HTTP call may already have reached the server.
  /// A new isolate must not present the same refresh token again.
  Future<bool> isRefreshPending();

  Future<void> markRefreshPending();

  Future<void> clearRefreshPending();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'speedygo.customer.session.v1';
  static const _pendingKey = 'speedygo.customer.refresh-pending.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<TokenPair?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      return TokenPair.fromJson(map);
    } on FormatException {
      await clear();
      return null;
    } on SessionParseException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(TokenPair pair) {
    return _storage.write(key: _key, value: jsonEncode(pair.toJson()));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _pendingKey);
  }

  @override
  Future<bool> isRefreshPending() async {
    return await _storage.read(key: _pendingKey) == '1';
  }

  @override
  Future<void> markRefreshPending() {
    return _storage.write(key: _pendingKey, value: '1');
  }

  @override
  Future<void> clearRefreshPending() {
    return _storage.delete(key: _pendingKey);
  }
}

abstract class LaunchStore {
  Future<bool> readOnboardingSeen();

  Future<void> markOnboardingSeen();

  Future<bool> readLanguageSeen();

  Future<void> markLanguageSeen();

  Future<String> readLocale();

  Future<void> writeLocale(String locale);
}

class SecureLaunchStore implements LaunchStore {
  SecureLaunchStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _onboardingKey = 'speedygo.customer.onboarding.v1';
  static const _languageKey = 'speedygo.customer.language.v1';
  static const _localeKey = 'speedygo.customer.locale.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> readOnboardingSeen() async {
    final raw = await _storage.read(key: _onboardingKey);
    return raw == '1';
  }

  @override
  Future<void> markOnboardingSeen() {
    return _storage.write(key: _onboardingKey, value: '1');
  }

  @override
  Future<bool> readLanguageSeen() async {
    final raw = await _storage.read(key: _languageKey);
    return raw == '1';
  }

  @override
  Future<void> markLanguageSeen() {
    return _storage.write(key: _languageKey, value: '1');
  }

  @override
  Future<String> readLocale() async {
    final raw = await _storage.read(key: _localeKey);
    final sanitized = AppLocale.sanitize(raw);
    if (raw != null && raw != sanitized) {
      await writeLocale(sanitized);
    }
    return sanitized;
  }

  @override
  Future<void> writeLocale(String locale) {
    return _storage.write(key: _localeKey, value: AppLocale.sanitize(locale));
  }
}

class MemoryLaunchStore implements LaunchStore {
  MemoryLaunchStore({
    this.onboardingSeen = false,
    bool? languageSeen,
    this.locale = AppLocale.french,
  }) : languageSeen = languageSeen ?? onboardingSeen;

  bool onboardingSeen;
  bool languageSeen;
  String locale;

  @override
  Future<bool> readOnboardingSeen() async => onboardingSeen;

  @override
  Future<void> markOnboardingSeen() async {
    onboardingSeen = true;
  }

  @override
  Future<bool> readLanguageSeen() async => languageSeen;

  @override
  Future<void> markLanguageSeen() async {
    languageSeen = true;
  }

  @override
  Future<String> readLocale() async {
    final sanitized = AppLocale.sanitize(locale);
    if (locale != sanitized) {
      locale = sanitized;
    }
    return sanitized;
  }

  @override
  Future<void> writeLocale(String value) async {
    locale = AppLocale.sanitize(value);
  }
}

class MemorySessionStore implements SessionStore {
  TokenPair? value;
  var refreshPending = false;

  @override
  Future<TokenPair?> read() async => value;

  @override
  Future<void> write(TokenPair pair) async {
    value = pair;
  }

  @override
  Future<void> clear() async {
    value = null;
    refreshPending = false;
  }

  @override
  Future<bool> isRefreshPending() async => refreshPending;

  @override
  Future<void> markRefreshPending() async {
    refreshPending = true;
  }

  @override
  Future<void> clearRefreshPending() async {
    refreshPending = false;
  }
}
