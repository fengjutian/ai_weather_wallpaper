import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight key-value storage helper backed by Hive.
///
/// Use for small, frequently-read values such as:
///   - user preferences (theme, units, temperature scale)
///   - last-selected city
///   - onboarding completion flag
///   - feature flags
///
/// For relational or large payloads prefer [DatabaseHelper].
///
/// Usage:
/// ```dart
/// final helper = HiveHelper();
/// await helper.put('theme_mode', 'dark');
/// final theme = await helper.get<String>('theme_mode');
/// ```
class HiveHelper {
  static const String _defaultBoxName = 'app_prefs';

  /// Opens (or reuses) the default Hive box.
  Future<Box> get box => Hive.openBox(_defaultBoxName);

  // ---------------------------------------------------------------------------
  // Generic accessors
  // ---------------------------------------------------------------------------

  /// Reads a value of type [T] for [key], or null if absent.
  Future<T?> get<T>(String key) async {
    final b = await box;
    return b.get(key) as T?;
  }

  /// Writes a [value] for [key].
  Future<void> put<T>(String key, T value) async {
    final b = await box;
    await b.put(key, value);
  }

  /// Removes the entry for [key].
  Future<void> delete(String key) async {
    final b = await box;
    await b.delete(key);
  }

  /// Returns `true` when the box contains [key].
  Future<bool> containsKey(String key) async {
    final b = await box;
    return b.containsKey(key);
  }

  /// Clears **all** entries from the default box.
  Future<void> clear() async {
    final b = await box;
    await b.clear();
  }

  // ---------------------------------------------------------------------------
  // Convenience typed helpers
  // ---------------------------------------------------------------------------

  /// Persist a [bool] preference.
  Future<void> setBool(String key, bool value) => put(key, value);

  /// Retrieve a [bool] preference (defaults to `false`).
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return (await get<bool>(key)) ?? defaultValue;
  }

  /// Persist a [String] preference.
  Future<void> setString(String key, String value) => put(key, value);

  /// Retrieve a [String] preference.
  Future<String?> getString(String key) => get<String>(key);

  /// Persist an [int] preference.
  Future<void> setInt(String key, int value) => put(key, value);

  /// Retrieve an [int] preference.
  Future<int?> getInt(String key) => get<int>(key);
}
