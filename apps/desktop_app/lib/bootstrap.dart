/// Bootstrap logic for the desktop application.
///
/// Performs early initialisation before the Flutter framework is fully
/// ready: sets up native channel listeners, initialises the wallpaper
/// engine, and configures error handling.
library bootstrap;

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:desktop_bridge/desktop_bridge.dart';
import 'package:wallpaper_core/wallpaper_core.dart';
import 'package:local_storage/local_storage.dart';

/// Called once during app startup, before [runApp].
///
/// Returns a [Future] that completes once all pre-run initialisation
/// has finished (or failed — errors are caught and logged).
Future<void> bootstrap() async {
  // --- Error handling ---
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Bootstrap: Flutter error: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Bootstrap: Platform error: $error\n$stack');
    return true; // handled
  };

  // --- Initialise local storage ---
  try {
    await HiveHelper.instance.init();
    debugPrint('Bootstrap: LocalStorage initialised.');
  } catch (e) {
    debugPrint('Bootstrap: LocalStorage init failed — $e');
  }

  // --- Initialise wallpaper engine ---
  try {
    final engine = WallpaperEngine.instance;
    await engine.initialise();
    debugPrint('Bootstrap: WallpaperEngine initialised.');
  } catch (e) {
    debugPrint('Bootstrap: WallpaperEngine init failed — $e');
  }
}
