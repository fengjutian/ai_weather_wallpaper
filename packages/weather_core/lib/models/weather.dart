/// Represents the current weather conditions at a specific location.
class WeatherModel {
  final String weather; // e.g. "Rain", "Clear", "Snow", "Clouds"
  final double temp;    // Current temperature in Celsius
  final int humidity;   // Humidity percentage (0–100)
  final double? tempFeelsLike;
  final double? windSpeed;
  final int? pressure;
  final String? iconCode; // Weather icon code from the provider

  const WeatherModel({
    required this.weather,
    required this.temp,
    required this.humidity,
    this.tempFeelsLike,
    this.windSpeed,
    this.pressure,
    this.iconCode,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      weather: json['weather'] as String? ?? 'Unknown',
      temp: (json['temp'] as num?)?.toDouble() ?? 0.0,
      humidity: json['humidity'] as int? ?? 0,
      tempFeelsLike: (json['temp_feels_like'] as num?)?.toDouble(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      pressure: json['pressure'] as int?,
      iconCode: json['icon_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'weather': weather,
        'temp': temp,
        'humidity': humidity,
        'temp_feels_like': tempFeelsLike,
        'wind_speed': windSpeed,
        'pressure': pressure,
        'icon_code': iconCode,
      };

  @override
  String toString() => 'WeatherModel($weather, ${temp}°C, ${humidity}%)';
}
