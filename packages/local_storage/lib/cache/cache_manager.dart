import 'dart:collection';

/// TTL-based in-memory cache manager with configurable expiry.
///
/// Stores values together with their insertion timestamp.  Entries are lazily
/// evicted — on every read the entry's age is checked against its TTL; stale
/// entries are silently treated as absent.
///
/// Typical use for data that should not be cached for longer than [defaultTtl]:
/// ```dart
/// final cm = CacheManager<String>(defaultTtl: Duration(minutes: 15));
/// await cm.set('weather_paris', '{"temp":22}');
/// final data = await cm.get('weather_paris'); // null if expired
/// ```
class CacheManager<V> {
  /// The per-instance default time-to-live when none is supplied to [set].
  final Duration defaultTtl;

  final _store = HashMap<String, _CacheEntry<V>>();

  CacheManager({this.defaultTtl = const Duration(minutes: 10)});

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Store [value] under [key] with an optional [ttl].
  ///
  /// If [ttl] is omitted the manager's [defaultTtl] is used.
  void set(String key, V value, {Duration? ttl}) {
    _store[key] = _CacheEntry(
      value: value,
      createdAt: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// Retrieve the value for [key], or `null` if absent / expired.
  ///
  /// Expired entries are removed from the store as a side-effect.
  V? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.createdAt) > entry.ttl) {
      _store.remove(key); // lazy eviction
      return null;
    }
    return entry.value;
  }

  /// Returns `true` when [key] exists and has not expired.
  bool containsKey(String key) => get(key) != null;

  /// Remove a single entry.
  void remove(String key) => _store.remove(key);

  /// Remove **all** entries regardless of TTL.
  void clear() => _store.clear();

  /// Remove every entry whose key satisfies [test].
  void removeWhere(bool Function(String key) test) =>
      _store.removeWhere((k, _) => test(k));

  /// Number of entries currently held (including expired ones — use
  /// [evictExpired] first for an accurate count).
  int get length => _store.length;

  /// Explicitly purge all expired entries.
  int evictExpired() {
    final now = DateTime.now();
    final toRemove = <String>[];
    for (final entry in _store.entries) {
      if (now.difference(entry.value.createdAt) > entry.value.ttl) {
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _store.remove(key);
    }
    return toRemove.length;
  }
}

/// Internal wrapper holding a cached value, its creation timestamp, and TTL.
class _CacheEntry<V> {
  final V value;
  final DateTime createdAt;
  final Duration ttl;

  const _CacheEntry({
    required this.value,
    required this.createdAt,
    required this.ttl,
  });
}
