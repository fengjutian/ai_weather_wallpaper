import 'dart:async';
import 'package:flutter/services.dart';
import '../renderer/video_renderer.dart';

/// Controls video / audio playback for wallpapers.
///
/// [MediaPlayer] provides low-level playback control for video
/// (MP4, WebM, MOV) and audio files used in dynamic wallpapers.
/// It supports play, pause, stop, seek, volume control, looping,
/// and playback-speed adjustment.
///
/// Internally this delegates to the native FFmpeg player via
/// [VideoRenderer]'s [MethodChannel].
class MediaPlayer {
  static const String _channelName = 'ai_weather_wallpaper/media_player';
  final MethodChannel _channel = const MethodChannel(_channelName);

  bool _initialised = false;
  bool _disposed = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _loop = false;

  /// Current playback position.
  Duration get position => _position;

  /// Total duration of the opened media.
  Duration get duration => _duration;

  /// Whether a media file is currently open.
  bool get isOpen => _initialised;

  /// Whether the player has been disposed.
  bool get isDisposed => _disposed;

  /// Opens a media file at [path] and prepares playback.
  ///
  /// Returns `true` on success, `false` otherwise.
  Future<bool> open(String path) async {
    _ensureNotDisposed();

    if (_initialised) {
      await _channel.invokeMethod('stop');
      _initialised = false;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'open',
        {
          'path': path,
          'volume': _volume,
          'loop': _loop,
        },
      );

      if (result != null) {
        _initialised = true;
        _duration = Duration(
          milliseconds: (result['durationMs'] as int?) ?? 0,
        );
        _position = Duration.zero;
        _setupEventHandler();
      }

      return _initialised;
    } on PlatformException catch (e) {
      print('MediaPlayer.open error: ${e.message}');
      return false;
    }
  }

  /// Starts or resumes playback.
  void play() {
    _ensureNotDisposed();
    if (!_initialised) return;
    _channel.invokeMethod<void>('play');
  }

  /// Pauses playback.
  void pause() {
    _ensureNotDisposed();
    if (!_initialised) return;
    _channel.invokeMethod<void>('pause');
  }

  /// Stops playback and resets to the beginning.
  void stop() {
    _ensureNotDisposed();
    if (!_initialised) return;
    _channel.invokeMethod<void>('stop');
    _position = Duration.zero;
  }

  /// Seeks to [position] in the media.
  Future<void> seek(Duration position) async {
    _ensureNotDisposed();
    if (!_initialised) return;
    try {
      await _channel.invokeMethod<void>('seek', {
        'positionMs': position.inMilliseconds,
      });
      _position = position;
    } on PlatformException catch (e) {
      print('MediaPlayer.seek error: ${e.message}');
    }
  }

  /// Sets the playback volume (0.0 = silent, 1.0 = full).
  void setVolume(double vol) {
    _ensureNotDisposed();
    _volume = vol.clamp(0.0, 1.0);
    if (_initialised) {
      _channel.invokeMethod<void>('setVolume', {'volume': _volume});
    }
  }

  /// Enables or disables looping.
  void setLoop(bool loop) {
    _ensureNotDisposed();
    _loop = loop;
    if (_initialised) {
      _channel.invokeMethod<void>('setLoop', {'loop': _loop});
    }
  }

  /// Releases the native player and all resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _initialised = false;

    try {
      _channel.invokeMethod<void>('dispose');
    } catch (_) {}

    _position = Duration.zero;
    _duration = Duration.zero;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('MediaPlayer has been disposed');
    }
  }

  void _setupEventHandler() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (_disposed) return;
      switch (call.method) {
        case 'onPosition':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final ms = (args?['positionMs'] as int?) ?? 0;
          _position = Duration(milliseconds: ms);
          break;
        case 'onDuration':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final ms = (args?['durationMs'] as int?) ?? _duration.inMilliseconds;
          _duration = Duration(milliseconds: ms);
          break;
        case 'onCompleted':
          // Media finished; loop is handled by the native side.
          break;
        case 'onError':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final message = args?['message'] as String? ?? 'Unknown error';
          print('MediaPlayer error: $message');
          break;
      }
    });
  }
}
