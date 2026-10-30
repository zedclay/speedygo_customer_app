import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const searchHistoryMaxItems = 8;

/// Account-scoped recent search queries. Not a favorite and not cross-device sync.
abstract class SearchHistoryStore {
  Future<List<String>> read(String profileId);

  Future<List<String>> record(String profileId, String query);

  Future<void> clear(String profileId);
}

class SecureSearchHistoryStore implements SearchHistoryStore {
  SecureSearchHistoryStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'speedygo.customer.search-history.v1.';

  final FlutterSecureStorage _storage;

  String _key(String profileId) => '$_prefix$profileId';

  @override
  Future<List<String>> read(String profileId) async {
    if (profileId.isEmpty) {
      return const [];
    }
    final raw = await _storage.read(key: _key(profileId));
    return _decode(raw);
  }

  @override
  Future<List<String>> record(String profileId, String query) async {
    final normalized = query.trim();
    if (profileId.isEmpty || normalized.isEmpty) {
      return read(profileId);
    }
    final current = await read(profileId);
    final next = [
      normalized,
      ...current.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(searchHistoryMaxItems).toList();
    await _storage.write(key: _key(profileId), value: jsonEncode(next));
    return next;
  }

  @override
  Future<void> clear(String profileId) {
    if (profileId.isEmpty) {
      return Future<void>.value();
    }
    return _storage.delete(key: _key(profileId));
  }

  List<String> _decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      final items = <String>[];
      for (final item in decoded) {
        final text = item?.toString().trim() ?? '';
        if (text.isEmpty) {
          continue;
        }
        if (items.any((existing) => existing.toLowerCase() == text.toLowerCase())) {
          continue;
        }
        items.add(text);
        if (items.length >= searchHistoryMaxItems) {
          break;
        }
      }
      return items;
    } on FormatException {
      return const [];
    }
  }
}

class MemorySearchHistoryStore implements SearchHistoryStore {
  MemorySearchHistoryStore();

  final Map<String, List<String>> _byProfile = {};

  @override
  Future<List<String>> read(String profileId) async {
    return List<String>.from(_byProfile[profileId] ?? const []);
  }

  @override
  Future<List<String>> record(String profileId, String query) async {
    final normalized = query.trim();
    if (profileId.isEmpty || normalized.isEmpty) {
      return read(profileId);
    }
    final current = await read(profileId);
    final next = [
      normalized,
      ...current.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(searchHistoryMaxItems).toList();
    _byProfile[profileId] = next;
    return next;
  }

  @override
  Future<void> clear(String profileId) async {
    _byProfile.remove(profileId);
  }
}
