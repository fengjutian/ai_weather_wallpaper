import 'package:flutter/material.dart';

/// App-wide theme constants for the AI Weather Wallpaper app.
///
/// Provides a consistent dark theme with frosted-glass aesthetics.
/// Use [AppTheme.dark] as the top-level [ThemeData] for [MaterialApp].
///
/// ```dart
/// MaterialApp(
///   theme: AppTheme.dark,
///   home: const HomeScreen(),
/// )
/// ```
class AppTheme {
  AppTheme._();

  // -------------------------------------------------------------------------
  // Colors
  // -------------------------------------------------------------------------

  /// Deep midnight background.
  static const Color background = Color(0xFF0D0D1A);

  /// Slightly lighter surface for cards / sheets.
  static const Color surface = Color(0xFF1A1A2E);

  /// Frosted-glass overlay tint.
  static const Color glassOverlay = Color(0x33FFFFFF);

  /// Primary accent — a soft cyan/teal.
  static const Color primary = Color(0xFF64FFDA);

  /// Secondary accent — a muted purple.
  static const Color secondary = Color(0xFFBB86FC);

  /// Error / warning red.
  static const Color error = Color(0xFFCF6679);

  /// On-primary text colour.
  static const Color onPrimary = Color(0xFF000000);

  /// Standard high-emphasis text on dark surfaces.
  static const Color onSurface = Color(0xFFE8E8F0);

  // -------------------------------------------------------------------------
  // ThemeData
  // -------------------------------------------------------------------------

  /// The complete dark [ThemeData] instance.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: onPrimary,
          onSurface: onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w300,
          ),
          titleMedium: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(color: onSurface),
          bodySmall: TextStyle(color: Color(0xFFB0B0C0)),
        ),
      );
}
