import 'package:flutter/services.dart';

/// Constants for all method channels used by the desktop wallpaper bridge.
///
/// Each [MethodChannel] is registered with a unique name so that the native
/// platform side (Windows / Linux / macOS) can dispatch calls to the correct
/// handler.
abstract class ChannelNames {
  /// Channel for wallpaper lifecycle operations.
  static const String wallpaper = 'ai_weather_wallpaper/wallpaper';

  /// Channel for audio-engine control (play, pause, volume).
  static const String audio = 'ai_weather_wallpaper/audio';

  /// Channel for overlay / quit / visibility commands.
  static const String overlay = 'ai_weather_wallpaper/overlay';
}

/// Handles registration and invocation of Flutter platform method channels
/// for desktop wallpaper operations.
///
/// ## Available Methods
///
/// | Channel            | Methods                                     |
/// |--------------------|---------------------------------------------|
/// | `wallpaper`        | `setWallpaper`, `pause`, `resume`, `quit`   |
/// | `audio`            | `play`, `pause`, `setVolume`                |
/// | `overlay`          | `show`, `hide`, `setOpacity`                |
///
/// ## Usage
///
/// ```dart
/// final handler = MethodChannelHandler();
/// await handler.setWallpaper();
/// ```
class MethodChannelHandler {
  final MethodChannel _wallpaperChannel =
      MethodChannel(ChannelNames.wallpaper);
  final MethodChannel _audioChannel =
      MethodChannel(ChannelNames.audio);
  final MethodChannel _overlayChannel =
      MethodChannel(ChannelNames.overlay);

  // ---------------------------------------------------------------------------
  // Wallpaper operations
  // ---------------------------------------------------------------------------

  /// Sets the current Flutter window as the desktop wallpaper.
  ///
  /// On Windows this calls through to `Win32Bindings` to invoke
  /// `FindWindow` / `SetParent` so the Flutter window becomes a child of
  /// the desktop shell's worker-window.  On Linux / macOS it delegates to
  /// platform-specific plugin code.
  ///
  /// Returns `true` when the wallpaper was set successfully.
  Future<bool> setWallpaper() async {
    // TODO(jutianfeng): Implement native platform channel handler for
    //   setWallpaper. On Windows, wire up the FFI calls from Win32Bindings.
    //   On Linux, use xdg-desktop-portal or similar.
    //   On macOS, NSWindow level shifting.
    try {
      final result = await _wallpaperChannel.invokeMethod<bool>('setWallpaper');
      return result ?? false;
    } on MissingPluginException {
      // No native implementation registered yet.
      return false;
    }
  }

  /// Pauses the wallpaper animation / rendering.
  ///
  /// The wallpaper window is hidden (not destroyed) so system resources are
  /// freed. Call [resume] to restore it.
  Future<bool> pause() async {
    // TODO(jutianfeng): Implement pause.  Possible approaches:
    //   - Hide the Flutter window (ShowWindow SW_HIDE on Windows).
    //   - Suspend the engine's rendering pipeline.
    try {
      final result = await _wallpaperChannel.invokeMethod<bool>('pause');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Resumes a previously paused wallpaper.
  ///
  /// Restores the Flutter window and re-activates the rendering loop.
  Future<bool> resume() async {
    // TODO(jutianfeng): Implement resume.  Inverse of [pause].
    try {
      final result = await _wallpaperChannel.invokeMethod<bool>('resume');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Quits the wallpaper application entirely.
  ///
  /// Calls `exit(0)` on the platform side after performing any necessary
  /// cleanup (saving state, freeing native resources, etc.).
  Future<bool> quit() async {
    // TODO(jutianfeng): Implement quit.  Ensure cleanup hooks run before
    //   the process exits (e.g. remove the window from the desktop worker-window
    //   parent, restore the original wallpaper).
    try {
      final result = await _wallpaperChannel.invokeMethod<bool>('quit');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Audio operations
  // ---------------------------------------------------------------------------

  /// Plays ambient audio through the platform's default audio device.
  ///
  /// [assetPath] is the key used to look up the audio resource.
  Future<bool> playAudio(String assetPath) async {
    // TODO(jutianfeng): Wire up to the audio_engine's AudioPlayer on the
    //   Dart side instead of (or in addition to) a platform channel.
    try {
      final result =
          await _audioChannel.invokeMethod<bool>('play', {'path': assetPath});
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Sets the volume of the currently playing audio (0.0 – 1.0).
  Future<bool> setAudioVolume(double volume) async {
    try {
      final result = await _audioChannel
          .invokeMethod<bool>('setVolume', {'volume': volume});
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Overlay operations
  // ---------------------------------------------------------------------------

  /// Shows a floating overlay above the wallpaper (e.g. weather info).
  Future<bool> showOverlay() async {
    try {
      final result = await _overlayChannel.invokeMethod<bool>('show');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Hides the floating overlay.
  Future<bool> hideOverlay() async {
    try {
      final result = await _overlayChannel.invokeMethod<bool>('hide');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Sets the opacity of the overlay widget (0.0 = transparent, 1.0 = opaque).
  Future<bool> setOverlayOpacity(double opacity) async {
    try {
      final result = await _overlayChannel
          .invokeMethod<bool>('setOpacity', {'opacity': opacity});
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// Singleton native bridge for desktop operations.
class DesktopBridgeNative {
  static const _channel = MethodChannel('desktop_bridge');

  /// Embeds the Flutter window behind desktop icons via native C++ WorkerW logic.
  static Future<bool> embedAsWallpaper() async {
    try {
      await _channel.invokeMethod('embedAsWallpaper');
      return true;
    } catch (e) {
      print('[DesktopBridge] embedAsWallpaper failed: $e');
      return false;
    }
  }

  /// Restores the Flutter window from behind desktop icons back to normal.
  static Future<bool> restoreFromWallpaper() async {
    try {
      await _channel.invokeMethod('restoreWindow');
      return true;
    } catch (e) {
      print('[DesktopBridge] restoreFromWallpaper failed: $e');
      return false;
    }
  }
}
