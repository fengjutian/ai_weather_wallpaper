import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'routes.dart';

/// Global notifier for dark/light mode.  Any widget can listen or toggle.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

/// The root widget of the AI Weather Wallpaper application.
class AIWeatherWallpaperApp extends StatelessWidget {
  const AIWeatherWallpaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'AI 天气壁纸',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
