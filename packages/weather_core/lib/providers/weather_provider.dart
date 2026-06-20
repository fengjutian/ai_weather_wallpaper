import '../models/weather.dart';
import '../models/forecast.dart';
import '../models/city.dart';

/// Abstract interface for weather data providers.
///
/// Each concrete provider (OpenWeather, QWeather, etc.) implements
/// this interface to supply [WeatherModel] and [Forecast] data.
abstract class WeatherProvider {
  /// Fetch the current weather for [city].
  Future<WeatherModel> fetchCurrentWeather(City city);

  /// Fetch a multi-day forecast for [city].
  Future<Forecast> fetchForecast(City city, {int days = 7});

  /// Search for cities matching [query].
  Future<List<City>> searchCities(String query);

  /// The human-readable name of this provider (e.g. "OpenWeather").
  String get providerName;
}
