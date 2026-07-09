import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// Central route definitions for the desktop application.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';

  /// The route table used by [MaterialApp.routes].
  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeScreen(),
      };
}
