import '../models/weather.dart';
import '../models/forecast.dart';
import '../models/city.dart';
import '../providers/weather_provider.dart';

/// Repository that abstracts weather data retrieval.
///
/// Coordinates between one or more [WeatherProvider]s and a local
/// cache layer. Consumers (UI / wallpaper engine) interact with
/// this repository instead of providers directly.
class WeatherRepository {
  final WeatherProvider _primaryProvider;
  final WeatherProvider? _fallbackProvider;

  WeatherRepository({
    required WeatherProvider primaryProvider,
    WeatherProvider? fallbackProvider,
  })  : _primaryProvider = primaryProvider,
        _fallbackProvider = fallbackProvider;

  /// The name of the currently-active provider.
  String get activeProviderName => _primaryProvider.providerName;

  /// Fetch the current weather for [city].
  ///
  /// Attempts the primary provider first; falls back to [fallbackProvider]
  /// if the primary fails.
  Future<WeatherModel> getCurrentWeather(City city) async {
    try {
      return await _primaryProvider.fetchCurrentWeather(city);
    } catch (e) {
      if (_fallbackProvider != null) {
        return _fallbackProvider!.fetchCurrentWeather(city);
      }
      rethrow;
    }
  }

  /// Fetch a multi-day forecast for [city].
  Future<Forecast> getForecast(City city, {int days = 7}) async {
    try {
      return await _primaryProvider.fetchForecast(city, days: days);
    } catch (e) {
      if (_fallbackProvider != null) {
        return _fallbackProvider!.fetchForecast(city, days: days);
      }
      rethrow;
    }
  }

  /// Search for cities by name.
  Future<List<City>> searchCities(String query) async {
    return _primaryProvider.searchCities(query);
  }
}
