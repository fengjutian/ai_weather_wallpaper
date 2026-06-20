import '../models/weather.dart';
import '../models/forecast.dart';
import '../models/city.dart';
import 'weather_provider.dart';

/// QWeather (和风天气) API implementation of [WeatherProvider].
///
/// Uses the QWeather dev API to fetch weather data for Chinese cities.
class QWeatherProvider implements WeatherProvider {
  final String apiKey;
  final String? apiSecret;

  QWeatherProvider({required this.apiKey, this.apiSecret});

  @override
  String get providerName => 'QWeather';

  @override
  Future<WeatherModel> fetchCurrentWeather(City city) async {
    throw UnimplementedError('fetchCurrentWeather not yet implemented');
  }

  @override
  Future<Forecast> fetchForecast(City city, {int days = 7}) async {
    throw UnimplementedError('fetchForecast not yet implemented');
  }

  @override
  Future<List<City>> searchCities(String query) async {
    throw UnimplementedError('searchCities not yet implemented');
  }
}
