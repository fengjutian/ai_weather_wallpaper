/// Local storage package for the AI Weather Wallpaper app.
///
/// Provides three persistence layers:
///   - **SQLite** via [DatabaseHelper] for relational data
///   - **Hive**   via [HiveHelper] for lightweight key-value storage
///   - **Cache**  via [CacheManager] for TTL-based in-memory caching
library local_storage;

export 'sqlite/database_helper.dart';
export 'hive/hive_helper.dart';
export 'cache/cache_manager.dart';
