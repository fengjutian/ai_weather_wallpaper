import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';

/// The entry point for the AI Weather Wallpaper desktop application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Perform early bootstrap (native channels, engine init, etc.)
  await bootstrap();

  runApp(const AIWeatherWallpaperApp());
}
