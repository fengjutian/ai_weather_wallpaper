import 'dart:collection';
import 'hive/hive_helper.dart';

/// Internal wrapper holding a cached value, its expiry timestamp, and TTL.
class _CacheEntry<T> {
  final T value;
  final DateTime expiry;

  const _CacheEntry({required this.value, required this.expiry});
}

/// Generic TTL-based cache manager with optional Hive persistence.
///
/// Stores values in memory with configurable time-to-live.  When the optional
/// [persistToHive] flag is `true` (the default), entries are also persisted to
/// the Hive `weather_cache` box, making them survive app restarts.
///
/// Expired entries are evicted lazily on read and eagerly via [evictExpired].
///
/// Type parameter [T] should be JSON-serializable (e.g. `String`, `int`,
/// `Map<String, dynamic>`, `List`) when persistence is enabled.
///
/// Usage:
/// ```dart
/// final cache = CacheManager<String>(defaultTtl: Duration(minutes: 30));
/// await cache.set('weather_beijing', '{"temp":28}');
/// final data = await cache.get<String>('weather_beijing');
/// ```
class CacheManager<T> {
  /// The per-instance default time-to-live when none is supplied to [set].
  final Duration defaultTtl;

  /// Whether entries are persisted to the Hive `weather_cache` box.
  final bool persistToHive;

  final Map<String, _CacheEntry<T>> _store = HashMap();

  /// Creates a [CacheManager] with an optional [defaultTtl] (default 30 min)
  /// and optional [persistToHive] (default `true`).
  CacheManager({
    this.defaultTtl = const Duration(minutes: 30),
    this.persistToHive = true,
  });

  /// The Hive helper used for persistence.
  HiveHelper get _hive => HiveHelper.instance;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Stores [value] under [key] with an optional [ttl].
  ///
  /// If [ttl] is omitted the manager's [defaultTtl] is used.
  /// When [persistToHive] is enabled the value is also written to Hive so it
  /// survives app restarts.
  Future<void> set(String key, T value, {Duration? ttl}) async {
    final expiry = DateTime.now().add(ttl ?? defaultTtl);

    _store[key] = _CacheEntry(value: value, expiry: expiry);

    if (persistToHive) {
      await _hive.put(
        'weather_cache',
        key,
        {
          'value': value,
          'expiry': expiry.toIso8601String(),
        },
      );
    }
  }

  /// Retrieves the value for [key], or `null` if absent / expired.
  ///
  /// Expired entries are removed from the store as a side-effect.
  /// When [persistToHive] is enabled and the entry is missing from memory,
  /// this method attempts to restore it from Hive.
  Future<T?> get(String key) async {
    // Check in-memory store first.
    final entry = _store[key];
    if (entry != null) {
      if (DateTime.now().isAfter(entry.expiry)) {
        _store.remove(key); // lazy eviction
        return null;
      }
      return entry.value;
    }

    // Attempt restore from Hive when persistence is on.
    if (persistToHive) {
      final persisted = _hive.get('weather_cache', key);
      if (persisted is Map) {
        final expiryStr = persisted['expiry'] as String?;
        final expiry =
            expiryStr != null ? DateTime.parse(expiryStr) : null;
        if (expiry == null || DateTime.now().isAfter(expiry)) {
          // Entry expired or malformed — clean up.
          if (persistToHive) {
            await _hive.delete('weather_cache', key);
          }
          return null;
        }
        final restoredValue = persisted['value'] as T;
        _store[key] = _CacheEntry(value: restoredValue, expiry: expiry);
        return restoredValue;
      }
    }

    return null;
  }

  /// Removes a single entry from memory and (if [persistToHive] is enabled)
  /// from Hive as well.
  Future<void> remove(String key) async {
    _store.remove(key);
    if (persistToHive) {
      await _hive.delete('weather_cache', key);
    }
  }

  /// Removes **all** entries regardless of TTL, from both memory and Hive.
  Future<void> clear() async {
    _store.clear();
    if (persistToHive) {
      await _hive.clearBox('weather_cache');
    }
  }

  /// Removes all expired entries from memory and (if [persistToHive] is
  /// enabled) from Hive as well.
  ///
  /// Returns the number of entries evicted.
  Future<int> evictExpired() async {
    final now = DateTime.now();
    final toRemove = <String>[];
    for (final entry in _store.entries) {
      if (now.isAfter(entry.value.expiry)) {
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _store.remove(key);
      if (persistToHive) {
        await _hive.delete('weather_cache', key);
      }
    }
    return toRemove.length;
  }

  /// Returns `true` when [key] exists, has not expired, and its value is
  /// of type [T].
  Future<bool> containsKey(String key) async {
    return (await get(key)) != null;
  }

  /// Number of entries currently held in memory (including expired ones —
  /// call [evictExpired] first for an accurate count).
  int get length => _store.length;
}
