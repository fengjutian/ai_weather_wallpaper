import 'package:hive_flutter/hive_flutter.dart';

/// Singleton helper for lightweight key-value storage backed by Hive.
///
/// Manages three Hive boxes:
///   - `settings`      — app preferences (theme, units, temperature scale)
///   - `weather_cache`  — lightweight weather data snapshots
///   - `session`        — current-session state (last city, onboarding flag)
///
/// Usage:
/// ```dart
/// final hive = HiveHelper.instance;
/// await hive.init();
/// await hive.put('settings', 'themeMode', 'dark');
/// final theme = hive.get('settings', 'themeMode', defaultValue: 'light');
/// ```
class HiveHelper {
  HiveHelper._internal();
  static final HiveHelper instance = HiveHelper._internal();

  static bool _initialized = false;

  /// The names of the boxes managed by this helper.
  static const List<String> boxNames = [
    'settings',
    'weather_cache',
    'session',
  ];

  final Map<String, Box> _boxes = {};

  /// Whether [init] has been called successfully.
  bool get isInitialized => _initialized;

  /// Initializes Hive and opens all managed boxes.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops once
  /// the boxes have been opened.
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    for (final name in boxNames) {
      final box = await Hive.openBox(name);
      _boxes[name] = box;
    }

    _initialized = true;
  }

  /// Returns the opened [Box] for [boxName], or throws a [StateError] if
  /// [init] has not been called or the box was not opened.
  Box _box(String boxName) {
    if (!_initialized) {
      throw StateError(
        'HiveHelper has not been initialized. Call init() first.',
      );
    }
    final box = _boxes[boxName];
    if (box == null) {
      throw ArgumentError('Unknown Hive box: "$boxName". '
          'Available boxes: $boxNames');
    }
    return box;
  }

  /// Writes a [value] for [key] in the specified [boxName].
  ///
  /// [boxName] must be one of: `settings`, `weather_cache`, or `session`.
  Future<void> put(String boxName, String key, dynamic value) async {
    await _box(boxName).put(key, value);
  }

  /// Reads the value for [key] from [boxName].
  ///
  /// Returns [defaultValue] when the key is absent (defaults to `null`).
  dynamic get(String boxName, String key, {dynamic defaultValue}) {
    return _box(boxName).get(key, defaultValue: defaultValue);
  }

  /// Removes the entry for [key] from [boxName].
  Future<void> delete(String boxName, String key) async {
    await _box(boxName).delete(key);
  }

  /// Returns `true` when [boxName] contains [key].
  bool containsKey(String boxName, String key) {
    return _box(boxName).containsKey(key);
  }

  /// Removes **all** entries from [boxName].
  Future<void> clearBox(String boxName) async {
    await _box(boxName).clear();
  }

  /// Closes all open Hive boxes and resets the helper state.
  ///
  /// After calling this method [init] must be called again before further use.
  Future<void> close() async {
    for (final box in _boxes.values) {
      await box.close();
    }
    _boxes.clear();
    _initialized = false;
  }
}
