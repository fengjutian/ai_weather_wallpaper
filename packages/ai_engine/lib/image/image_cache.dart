import 'dart:collection';
import 'dart:typed_data';

/// Internal cache entry holding image data and metadata.
class _CacheEntry {
  final Uint8List data;
  final DateTime cachedAt;
  final String? prompt;

  _CacheEntry(this.data, {this.prompt}) : cachedAt = DateTime.now();
}

/// An in-memory LRU (Least Recently Used) cache for generated images.
///
/// Images are stored keyed by a string identifier (e.g., a weather condition
/// combined with a prompt hash) to avoid redundant generation.  When the
/// number of cached entries exceeds [maxEntries], the least recently accessed
/// entry is evicted.
///
/// Access ordering is maintained using a [LinkedHashMap] with access-order
/// iteration, so every [get] or [set] call promotes the entry to the most
/// recently used position.
class ImageCache {
  final int maxEntries;

  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap(
    equals: (a, b) => a == b,
    hashCode: (key) => key.hashCode,
  );

  /// Creates an [ImageCache] with the given [maxEntries] (default 50).
  ImageCache({this.maxEntries = 50});

  /// Stores [data] in the cache under [key].
  ///
  /// An optional [prompt] can be recorded for debugging or inspection purposes.
  /// If the cache is already at capacity, the least recently used entry is
  /// evicted before inserting the new one.
  void set(String key, Uint8List data, {String? prompt}) {
    if (_cache.containsKey(key)) {
      // Update existing entry and move to most-recent position.
      _cache[key] = _CacheEntry(data, prompt: prompt);
      return;
    }

    // Evict the oldest (first) entry if at capacity.
    if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(data, prompt: prompt);
  }

  /// Retrieves cached image bytes for [key].
  ///
  /// The entry is promoted to the most recently used position on access.
  /// Returns `null` if the key is not present (no TTL expiry is applied).
  Uint8List? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    // Accessing via [key] on an access-ordered LinkedHashMap promotes it.
    return entry.data;
  }

  /// Returns `true` if the cache contains [key] (without promoting it).
  bool containsKey(String key) => _cache.containsKey(key);

  /// Removes the entry for [key] from the cache.
  void remove(String key) {
    _cache.remove(key);
  }

  /// Removes all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// The number of entries currently in the cache.
  int get count => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache has reached its maximum capacity.
  bool get isFull => _cache.length >= maxEntries;

  /// An unmodifiable list of all cached keys in access order (LRU→MRU).
  List<String> get keys => List.unmodifiable(_cache.keys);
}
