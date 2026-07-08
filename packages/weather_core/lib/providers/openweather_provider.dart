import 'dart:convert';
import 'dart:io';

import '../models/weather.dart';
import '../models/forecast.dart';
import '../models/city.dart';
import 'weather_provider.dart';

/// Exception thrown when a weather API returns a non-200 status or a parse error.
class WeatherApiException implements Exception {
  final String message;
  final int? statusCode;

  const WeatherApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'WeatherApiException($statusCode): $message';
}

/// OpenWeatherMap API implementation of [WeatherProvider].
///
/// Uses the free-tier 2.5 API endpoints to fetch weather data.
/// All requests use `dart:io` [HttpClient] (no third-party HTTP package).
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
    final uri = Uri.parse(
      '$_baseUrl/data/2.5/weather'
      '?lat=${city.latitude}&lon=${city.longitude}'
      '&appid=$apiKey&units=metric',
    );

    final response = await _get(uri);
    final body = json.decode(response) as Map<String, dynamic>;
    final weatherListRaw = body['weather'];
    final weatherList = weatherListRaw is List ? weatherListRaw.cast<dynamic>() : null;
    final weather = (weatherList != null && weatherList.isNotEmpty)
        ? weatherList[0] as Map<String, dynamic>
        : null;

    final main = body['main'] as Map<String, dynamic>? ?? {};
    final wind = body['wind'] as Map<String, dynamic>? ?? {};

    return WeatherModel(
      weather: weather?['main'] as String? ?? 'Unknown',
      temp: (main['temp'] as num?)?.toDouble() ?? 0.0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      tempFeelsLike: (main['feels_like'] as num?)?.toDouble(),
      windSpeed: (wind['speed'] as num?)?.toDouble(),
      pressure: (main['pressure'] as num?)?.toInt(),
      iconCode: weather?['icon'] as String?,
    );
  }

  @override
  Future<Forecast> fetchForecast(City city, {int days = 7}) async {
    final uri = Uri.parse(
      '$_baseUrl/data/2.5/forecast'
      '?lat=${city.latitude}&lon=${city.longitude}'
      '&appid=$apiKey&units=metric',
    );

    final response = await _get(uri);
    final body = json.decode(response) as Map<String, dynamic>;
    final list = body['list'] as List<dynamic>? ?? [];

    // Group 3-hour forecast entries by calendar day.
    final Map<String, List<Map<String, dynamic>>> dayGroups = {};
    for (final entry in list) {
      final item = entry as Map<String, dynamic>;
      final dt = item['dt'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
      final dayKey = '${date.year}-${_pad(date.month)}-${_pad(date.day)}';

      dayGroups.putIfAbsent(dayKey, () => []);
      dayGroups[dayKey]!.add(item);
    }

    // Sort days chronologically and limit to requested count.
    final sortedDays = dayGroups.keys.toList()..sort();
    final limitedDays = sortedDays.take(days).toList();

    final entries = <ForecastEntry>[];
    for (final dayKey in limitedDays) {
      final items = dayGroups[dayKey]!;

      // Compute aggregate values across all 3-hour slots for this day.
      double tempMin = double.infinity;
      double tempMax = double.negativeInfinity;
      int humidity = 0;
      String weather = 'Unknown';
      String? iconCode;

      for (final item in items) {
        final main = item['main'] as Map<String, dynamic>? ?? {};
        final itemTempMin = (main['temp_min'] as num?)?.toDouble() ?? double.infinity;
        final itemTempMax = (main['temp_max'] as num?)?.toDouble() ?? double.negativeInfinity;

        if (itemTempMin < tempMin) tempMin = itemTempMin;
        if (itemTempMax > tempMax) tempMax = itemTempMax;

        final weatherList = item['weather'] as List<dynamic>?;
        if (weatherList != null && weatherList.isNotEmpty) {
          final w = weatherList[0] as Map<String, dynamic>;
          weather = w['main'] as String? ?? weather;
          iconCode ??= w['icon'] as String?;
        }

        humidity = (main['humidity'] as num?)?.toInt() ?? humidity;
      }

      // Parse the date from the day key.
      final parts = dayKey.split('-');
      final parsedDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      entries.add(ForecastEntry(
        timestamp: parsedDate,
        tempMin: tempMin,
        tempMax: tempMax,
        weather: weather,
        humidity: humidity,
        iconCode: iconCode,
      ));
    }

    return Forecast(entries: entries);
  }

  @override
  Future<List<City>> searchCities(String query) async {
    final uri = Uri(
      scheme: 'https',
      host: 'api.openweathermap.org',
      path: '/geo/1.0/direct',
      queryParameters: <String, String>{
        'q': query,
        'limit': '5',
        'appid': apiKey,
      },
    );

    final response = await _get(uri);
    final body = json.decode(response) as List<dynamic>;

    return body.map((item) {
      final map = item as Map<String, dynamic>;
      return City(
        name: map['name'] as String? ?? '',
        latitude: (map['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['lon'] as num?)?.toDouble() ?? 0.0,
        country: map['country'] as String?,
        adminArea: map['state'] as String?,
      );
    }).toList();
  }

  /// Perform an HTTP GET and return the response body as a String.
  ///
  /// Throws [WeatherApiException] on non-200 status codes or connection errors.
  Future<String> _get(Uri uri) async {
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw WeatherApiException(
          'OpenWeather API returned status ${response.statusCode}: $body',
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

  /// Pad a month or day number to two digits.
  static String _pad(int n) => n.toString().padLeft(2, '0');
}
