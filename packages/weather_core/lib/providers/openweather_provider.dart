import 'dart:convert';
import 'dart:io';

import '../models/weather.dart';
import '../models/forecast.dart';
import '../models/city.dart';
import 'weather_provider.dart';

/// OpenWeatherMap API implementation of [WeatherProvider].
///
/// Uses the One Call API 3.0 (or 2.5 fallback) to fetch weather data.
class OpenWeatherProvider implements WeatherProvider {
  final String apiKey;
  final HttpClient client;

  OpenWeatherProvider({required this.apiKey})
      : client = HttpClient();

  static const _baseUrl = 'https://api.openweathermap.org';

  @override
  String get providerName => 'OpenWeather';

  @override
  Future<WeatherModel> fetchCurrentWeather(City city) async {
    // TODO: Implement actual HTTP request
    // final uri = Uri.parse('$_baseUrl/data/2.5/weather'
    //     '?lat=${city.latitude}&lon=${city.longitude}'
    //     '&appid=$apiKey&units=metric');
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
