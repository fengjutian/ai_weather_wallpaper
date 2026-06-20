import 'package:flutter/material.dart';
import 'routes.dart';

/// The root widget of the AI Weather Wallpaper application.
///
/// This widget sets up the MaterialApp with the configured routes,
/// theme, and initial bootstrap state.
class AIWeatherWallpaperApp extends StatelessWidget {
  const AIWeatherWallpaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Weather Wallpaper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
