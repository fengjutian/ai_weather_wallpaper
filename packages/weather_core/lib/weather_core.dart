/// Weather Core — weather data models, providers, and repository.
///
/// This package provides the abstractions for fetching and caching
/// weather data from multiple providers (OpenWeatherMap, QWeather, etc.).
library weather_core;

export 'models/weather.dart';
export 'models/forecast.dart';
export 'models/city.dart';
export 'providers/weather_provider.dart';
export 'providers/openweather_provider.dart';
export 'providers/qweather_provider.dart';
export 'repository/weather_repository.dart';
