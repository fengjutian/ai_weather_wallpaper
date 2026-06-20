import 'dart:async';
import 'package:flutter/services.dart';

/// A single decoded video frame delivered from the native player.
class VideoFrame {
  /// Constructs a [VideoFrame].
  const VideoFrame({
    required this.data,
    required this.width,
    required this.height,
    required this.timestamp,
  });

  /// Raw RGBA pixel buffer (width × height × 4 bytes).
  final Uint8List data;

  /// Frame width in pixels.
  final int width;

  /// Frame height in pixels.
  final int height;

  /// Presentation timestamp in microseconds.
  final int timestamp;

  /// Duration since the start of the video.
  Duration get position => Duration(microseconds: timestamp);
}

/// Renders video wallpapers (MP4, WebM, GIF, MOV).
///
/// The [VideoRenderer] wraps a native FFmpeg-based player via
/// [MethodChannel]. It supports playback controls (play, pause,
/// seek, loop) and volume management. Decoded frames are delivered
/// through the [frames] stream.
class VideoRenderer {
  static const String _channelName = 'ai_weather_wallpaper/video_player';
  final MethodChannel _channel = const MethodChannel(_channelName);

  bool _initialised = false;
  bool _disposed = false;
  bool _loop = false;
  double _volume = 1.0;

  final StreamController<VideoFrame> _frameController =
      StreamController<VideoFrame>.broadcast();

  /// Stream of decoded video frames from the native player.
  ///
  /// Listen to this to render frames onto the wallpaper canvas.
  Stream<VideoFrame>? get frames =>
      _disposed ? null : _frameController.stream;

  /// Whether the renderer has been disposed.
  bool get isDisposed => _disposed;

  /// Whether a media file is currently opened.
  bool get isOpen => _initialised;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Opens a video file at [path] and prepares the native player.
  ///
  /// Returns `true` on success, `false` if the file cannot be opened.
  Future<bool> open(String path) async {
    _ensureNotDisposed();

    if (_initialised) {
      await _channel.invokeMethod('stop');
      _initialised = false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('open', {
        'path': path,
        'volume': _volume,
        'loop': _loop,
      });
      _initialised = result ?? false;
      if (_initialised) {
        _setupFrameListener();
      }
      return _initialised;
    } on PlatformException catch (e) {
      print('VideoRenderer.open error: ${e.message}');
      return false;
    }
  }

  /// Starts or resumes playback.
  void play() {
    _ensureNotDisposed();
    if (!_initialised) return;
    _channel.invokeMethod<void>('play');
  }

  /// Pauses playback. The current frame is retained.
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
  }

  /// Seeks to [position] in the video.
  Future<void> seek(Duration position) async {
    _ensureNotDisposed();
    if (!_initialised) return;
    await _channel.invokeMethod<void>('seek', {
      'positionMs': position.inMilliseconds,
    });
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

  /// Releases the native player and all associated resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _initialised = false;

    try {
      _channel.invokeMethod<void>('dispose');
    } catch (_) {}

    _frameController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('VideoRenderer has been disposed');
    }
  }

  void _setupFrameListener() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (_disposed) return;
      switch (call.method) {
        case 'onFrame':
          final args = call.arguments as Map<dynamic, dynamic>;
          final frame = VideoFrame(
            data: (args['data'] as Uint8List?) ?? Uint8List(0),
            width: (args['width'] as int?) ?? 0,
            height: (args['height'] as int?) ?? 0,
            timestamp: (args['timestamp'] as int?) ?? 0,
          );
          _frameController.add(frame);
          break;
        case 'onError':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final message = args?['message'] as String? ?? 'Unknown error';
          print('VideoRenderer error: $message');
          _frameController.addError(Exception(message));
          break;
        case 'onCompleted':
          // Video ended; loop is handled by the native side.
          break;
      }
    });
  }
}
