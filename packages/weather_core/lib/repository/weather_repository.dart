import '../models/weather.dart';
import '../models/forecast.dart';
import '../models/city.dart';
import '../providers/weather_provider.dart';

/// Cache entry with a time-to-live.
class _CacheEntry {
  final WeatherModel weather;
  final DateTime fetchedAt;

  const _CacheEntry(this.weather, this.fetchedAt);

  bool get isExpired {
    const ttl = Duration(minutes: 10);
    return DateTime.now().difference(fetchedAt) > ttl;
  }
}

/// Repository that abstracts weather data retrieval.
///
/// Coordinates between one or more [WeatherProvider]s and a local
/// in-memory cache layer. Consumers (UI / wallpaper engine) interact
/// with this repository instead of providers directly.
class WeatherRepository {
  final WeatherProvider _primaryProvider;
  final WeatherProvider? _fallbackProvider;

  /// In-memory cache keyed by a compound key derived from [City].
  final Map<String, _CacheEntry> _cache = {};

  /// The last time any successful weather fetch completed, or `null`
  /// if no fetch has been made yet.
  DateTime? _lastFetchTime;

  WeatherRepository({
    required WeatherProvider primaryProvider,
    WeatherProvider? fallbackProvider,
  })  : _primaryProvider = primaryProvider,
        _fallbackProvider = fallbackProvider;

  /// The name of the currently-active provider.
  String get activeProviderName => _primaryProvider.providerName;

  /// The last time a successful weather fetch was performed.
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Clear all cached weather data.
  void clearCache() {
    _cache.clear();
  }

  /// Invalidate a specific [city]'s cached entry, if any.
  void invalidateCity(City city) {
    _cache.remove(_cacheKey(city));
  }

  /// Fetch the current weather for [city].
  ///
  /// Checks the in-memory cache first (10-minute TTL). On a cache miss,
  /// attempts the primary provider first; falls back to [fallbackProvider]
  /// if the primary fails. Successful fetches update the cache and set
  /// [lastFetchTime].
  Future<WeatherModel> getCurrentWeather(City city) async {
    final key = _cacheKey(city);

    // Return cached entry if still valid.
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return cached.weather;
    }

    try {
      final weather = await _primaryProvider.fetchCurrentWeather(city);
      _cache[key] = _CacheEntry(weather, DateTime.now());
      _lastFetchTime = DateTime.now();
      return weather;
    } catch (e) {
      if (_fallbackProvider != null) {
        try {
          final weather = await _fallbackProvider!.fetchCurrentWeather(city);
          _cache[key] = _CacheEntry(weather, DateTime.now());
          _lastFetchTime = DateTime.now();
          return weather;
        } catch (_) {
          // Fallback also failed — rethrow the original error.
        }
      }
      rethrow;
    }
  }

  /// Fetch a multi-day forecast for [city].
  ///
  /// Forecast data is not cached by this repository.
  Future<Forecast> getForecast(City city, {int days = 7}) async {
    try {
      final forecast =
          await _primaryProvider.fetchForecast(city, days: days);
      _lastFetchTime = DateTime.now();
      return forecast;
    } catch (e) {
      if (_fallbackProvider != null) {
        try {
          final forecast =
              await _fallbackProvider!.fetchForecast(city, days: days);
          _lastFetchTime = DateTime.now();
          return forecast;
        } catch (_) {
          // Fallback also failed.
        }
      }
      rethrow;
    }
  }

  /// Search for cities by name.
  Future<List<City>> searchCities(String query) async {
    return _primaryProvider.searchCities(query);
  }

  /// Build a deterministic cache key from a [City].
  String _cacheKey(City city) =>
      '${city.latitude},${city.longitude}|${city.name}';
}
