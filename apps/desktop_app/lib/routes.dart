import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wallpaper_picker_screen.dart';
import 'screens/weather_settings_screen.dart';
import 'screens/about_screen.dart';

/// Central route definitions for the desktop application.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String settings = '/settings';
  static const String wallpaperPicker = '/wallpaper-picker';
  static const String weatherSettings = '/weather-settings';
  static const String about = '/about';

  /// The route table used by [MaterialApp.routes].
  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeScreen(),
        settings: (_) => const SettingsScreen(),
        wallpaperPicker: (_) => const WallpaperPickerScreen(),
        weatherSettings: (_) => const WeatherSettingsScreen(),
        about: (_) => const AboutScreen(),
      };
}
