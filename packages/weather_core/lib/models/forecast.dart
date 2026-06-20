import 'weather.dart';

/// A single forecast entry for a specific day/time slot.
class ForecastEntry {
  final DateTime timestamp;
  final double tempMin;
  final double tempMax;
  final String weather;
  final int humidity;
  final String? iconCode;

  const ForecastEntry({
    required this.timestamp,
    required this.tempMin,
    required this.tempMax,
    required this.weather,
    required this.humidity,
    this.iconCode,
  });

  factory ForecastEntry.fromJson(Map<String, dynamic> json) => ForecastEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        tempMin: (json['temp_min'] as num).toDouble(),
        tempMax: (json['temp_max'] as num).toDouble(),
        weather: json['weather'] as String,
        humidity: json['humidity'] as int,
        iconCode: json['icon_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'temp_min': tempMin,
        'temp_max': tempMax,
        'weather': weather,
        'humidity': humidity,
        'icon_code': iconCode,
      };
}

/// A collection of [ForecastEntry] items for a multi-day forecast.
class Forecast {
  final List<ForecastEntry> entries;
  final DateTime fetchedAt;

  const Forecast({required this.entries, DateTime? fetchedAt})
      : fetchedAt = fetchedAt ?? DateTime.now();

  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
        entries: (json['entries'] as List)
            .map((e) => ForecastEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(json['fetched_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'fetched_at': fetchedAt.toIso8601String(),
      };
}
