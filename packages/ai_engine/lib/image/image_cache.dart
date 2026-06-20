import 'dart:typed_data';

/// A cache for storing generated images in memory and optionally on disk.
///
/// Images are keyed by a string identifier (e.g., a weather condition combined
/// with a timestamp or hash of the prompt) to avoid redundant generation.
///
/// TODO: Implement actual caching logic.
/// - Add configurable max cache size with LRU eviction.
/// - Add optional disk persistence (e.g., using `path_provider`).
/// - Add TTL (time-to-live) for stale entries.
/// - Add thread-safety for concurrent access.
class ImageCache {
  /// Internal in-memory store mapping keys to image bytes.
  final Map<String, Uint8List> _cache = {};

  /// The maximum number of entries to keep in memory.
  final int maxEntries;

  /// Creates an [ImageCache] with the given [maxEntries].
  const ImageCache({this.maxEntries = 50});

  /// Retrieves cached image bytes for the given [key].
  /// Returns `null` if the key is not in the cache.
  Uint8List? get(String key) {
    // TODO: Implement LRU tracking and TTL checks.
    return _cache[key];
  }

  /// Stores [bytes] in the cache under the given [key].
  ///
  /// If the cache is full, the least recently used entry is evicted.
  void set(String key, Uint8List bytes) {
    // TODO: Implement LRU eviction when _cache.length >= maxEntries.
    _cache[key] = bytes;
  }

  /// Returns `true` if the cache contains the given [key].
  bool contains(String key) => _cache.containsKey(key);

  /// Removes the entry for the given [key] from the cache.
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clears all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// The number of entries currently in the cache.
  int get length => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache has reached its maximum capacity.
  bool get isFull => _cache.length >= maxEntries;
}
