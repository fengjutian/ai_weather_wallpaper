import 'package:flutter/material.dart';

/// App-wide theme constants for the AI Weather Wallpaper app.
///
/// Provides dark and light themes with frosted-glass aesthetics.
class AppTheme {
  AppTheme._();

  // ─── Shared ───────────────────────────────────────────────────────────

  static const Color primary = Color(0xFFE60012); // 中国红
  static const Color secondary = Color(0xFFBB86FC);
  static const Color error = Color(0xFFCF6679);
  static const Color lightPrimary = Color(0xFFC8102E); // 深红
  static const Color lightError = Color(0xFFFF3B30); // iOS red

  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkOnSurface = Color(0xFFE8E8F0);

  static const Color lightBg = Color(0xFFF2F2F7); // iOS system background
  static const Color lightSurface = Color(0xFFFFFFFF); // white cards
  static const Color lightOnSurface = Color(0xFF000000);

  static const Color glassOverlay = Color(0x33FFFFFF);

  // ─── Themes ──────────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: darkSurface,
          error: error,
          onPrimary: Color(0xFF000000),
          onSurface: darkOnSurface,
        ),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
        cardTheme: CardThemeData(
            color: darkSurface, elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: primary, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)))),
        textTheme: const TextTheme(
            displayLarge: TextStyle(color: darkOnSurface, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(color: darkOnSurface, fontWeight: FontWeight.w300),
            titleMedium: TextStyle(color: darkOnSurface, fontWeight: FontWeight.w600),
            bodyMedium: TextStyle(color: darkOnSurface),
            bodySmall: TextStyle(color: Color(0xFFB0B0C0))),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        colorScheme: const ColorScheme.light(
          primary: lightPrimary,
          secondary: Color(0xFF5856D6), // iOS purple
          surface: lightSurface,
          error: lightError,
          onPrimary: Colors.white,
          onSurface: lightOnSurface,
        ),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
        cardTheme: CardThemeData(
            color: lightSurface.withOpacity(0.7), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: lightPrimary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)))),
        textTheme: const TextTheme(
            displayLarge: TextStyle(color: lightOnSurface, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(color: lightOnSurface, fontWeight: FontWeight.w300),
            titleMedium: TextStyle(color: lightOnSurface, fontWeight: FontWeight.w600),
            bodyMedium: TextStyle(color: lightOnSurface),
            bodySmall: TextStyle(color: Color(0x8E3C3C43))), // iOS secondary label
      );
}
