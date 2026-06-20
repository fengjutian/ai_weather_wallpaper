import 'dart:convert';
import 'dart:io';

import '../models/weather.dart';
import '../models/forecast.dart';
import '../models/city.dart';
import 'weather_provider.dart';
import 'openweather_provider.dart';

/// QWeather (和风天气) API implementation of [WeatherProvider].
///
/// Uses the QWeather dev API to fetch weather data for Chinese cities.
/// The free tier supports current weather and a 3-day forecast via the
/// `/v7/weather/now` and `/v7/weather/3d` endpoints respectively.
///
/// All requests use `dart:io` [HttpClient] (no third-party HTTP package).
class QWeatherProvider implements WeatherProvider {
  final String apiKey;
  final String? apiSecret;

  /// The [HttpClient] is lazily created to avoid constructing it before
  /// the zone / context is ready.
  HttpClient? _client;

  QWeatherProvider({required this.apiKey, this.apiSecret});

  HttpClient get _httpClient => _client ??= HttpClient();

  @override
  String get providerName => 'QWeather';

  @override
  Future<WeatherModel> fetchCurrentWeather(City city) async {
    final uri = Uri(
      scheme: 'https',
      host: 'devapi.qweather.com',
      path: '/v7/weather/now',
      queryParameters: <String, String>{
        'location': '${city.latitude},${city.longitude}',
        'key': apiKey,
      },
    );

    final response = await _get(uri);
    final body = json.decode(response) as Map<String, dynamic>;
    _checkQwCode(body);

    final now = body['now'] as Map<String, dynamic>? ?? {};

    return WeatherModel(
      weather: now['text'] as String? ?? 'Unknown',
      temp: _parseDouble(now['temp']),
      humidity: _parseInt(now['humidity']),
      tempFeelsLike: _parseDouble(now['feelsLike']),
      windSpeed: _parseDouble(now['windSpeed']),
      pressure: _parseInt(now['pressure']),
      iconCode: now['icon'] as String?,
    );
  }

  @override
  Future<Forecast> fetchForecast(City city, {int days = 7}) async {
    // QWeather free tier only supports 3-day forecast.
    final uri = Uri(
      scheme: 'https',
      host: 'devapi.qweather.com',
      path: '/v7/weather/3d',
      queryParameters: <String, String>{
        'location': '${city.latitude},${city.longitude}',
        'key': apiKey,
      },
    );

    final response = await _get(uri);
    final body = json.decode(response) as Map<String, dynamic>;
    _checkQwCode(body);

    final daily = body['daily'] as List<dynamic>? ?? [];
    // Limit to requested days (max 3 for free tier).
    final limited = daily.take(days).toList();

    final entries = <ForecastEntry>[];
    for (final item in limited) {
      final map = item as Map<String, dynamic>;
      final fxDate = map['fxDate'] as String?;

      entries.add(ForecastEntry(
        timestamp: fxDate != null ? DateTime.parse(fxDate) : DateTime.now(),
        tempMin: _parseDouble(map['tempMin']),
        tempMax: _parseDouble(map['tempMax']),
        weather: map['textDay'] as String? ?? 'Unknown',
        humidity: _parseInt(map['humidity']),
        iconCode: map['iconDay'] as String?,
      ));
    }

    return Forecast(entries: entries);
  }

  @override
  Future<List<City>> searchCities(String query) async {
    final uri = Uri(
      scheme: 'https',
      host: 'geoapi.qweather.com',
      path: '/v2/city/lookup',
      queryParameters: <String, String>{
        'location': query,
        'key': apiKey,
      },
    );

    final response = await _get(uri);
    final body = json.decode(response) as Map<String, dynamic>;
    _checkQwCode(body);

    final location = body['location'] as List<dynamic>? ?? [];

    return location.map((item) {
      final map = item as Map<String, dynamic>;
      return City(
        name: map['name'] as String? ?? '',
        latitude: _parseDouble(map['lat']),
        longitude: _parseDouble(map['lon']),
        country: map['country'] as String?,
        adminArea: map['adm1'] as String?,
      );
    }).toList();
  }

  /// Check the QWeather API response code and throw on failure.
  void _checkQwCode(Map<String, dynamic> body) {
    final code = body['code'] as String?;
    if (code != null && code != '200') {
      throw WeatherApiException(
        'QWeather API returned code $code',
        statusCode: int.tryParse(code),
      );
    }
  }

  /// Perform an HTTP GET and return the response body as a String.
  Future<String> _get(Uri uri) async {
    try {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw WeatherApiException(
          'QWeather API returned status ${response.statusCode}: $body',
          statusCode: response.statusCode,
        );
      }

      return body;
    } on SocketException catch (e) {
      throw WeatherApiException(
        'Network error: ${e.message}',
        statusCode: null,
      );
    } on HttpException catch (e) {
      throw WeatherApiException(
        'HTTP error: ${e.message}',
        statusCode: null,
      );
    }
  }

  /// Close the underlying HTTP client (idempotent).
  void close() {
    _client?.close(force: true);
    _client = null;
  }

  static double _parseDouble(dynamic value) =>
      (value as num?)?.toDouble() ?? 0.0;

  static int _parseInt(dynamic value) =>
      (value as num?)?.toInt() ?? 0;
}
