import 'package:flutter/material.dart';

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

// --- Placeholder screens (replace with real implementations later) ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home — AI Weather Wallpaper')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Screen')),
    );
  }
}

class WallpaperPickerScreen extends StatelessWidget {
  const WallpaperPickerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallpaper Picker')),
      body: const Center(child: Text('Wallpaper Picker Screen')),
    );
  }
}

class WeatherSettingsScreen extends StatelessWidget {
  const WeatherSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather Settings')),
      body: const Center(child: Text('Weather Settings Screen')),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About AI Weather Wallpaper v1.0.0')),
    );
  }
}
