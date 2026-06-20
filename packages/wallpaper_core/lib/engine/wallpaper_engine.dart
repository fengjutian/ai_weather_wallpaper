import 'dart:async';
import 'package:flutter/foundation.dart';

import '../renderer/image_renderer.dart';
import '../renderer/video_renderer.dart';
import '../renderer/lottie_renderer.dart';
import '../renderer/shader_renderer.dart';

/// Possible states of the wallpaper engine.
enum WallpaperState {
  /// Engine is not initialised.
  idle,

  /// Engine is loading a wallpaper.
  loading,

  /// Wallpaper is actively playing / displayed.
  playing,

  /// Wallpaper playback is paused.
  paused,

  /// An error has occurred.
  error,
}

/// The type of wallpaper being rendered.
enum WallpaperType {
  /// Static image (PNG, JPG, BMP, WebP).
  image,

  /// Video file (MP4, WebM, MOV, GIF).
  video,

  /// Lottie animation (.json).
  lottie,

  /// GLSL fragment shader (.glsl).
  shader,
}

/// Manages the lifecycle of wallpapers.
///
/// [WallpaperEngine] acts as the central coordinator — it loads
/// the appropriate renderer based on wallpaper type, handles
/// the transition between wallpapers, manages resource cleanup,
/// and applies global configuration (fps limit, quality, etc.).
///
/// This class follows a singleton pattern: access the shared
/// instance via [instance].
class WallpaperEngine {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static final WallpaperEngine _singleton = WallpaperEngine._internal();

  /// Returns the shared [WallpaperEngine] instance.
  static WallpaperEngine get instance => _singleton;

  WallpaperEngine._internal();

  // ---------------------------------------------------------------------------
  // Renderers
  // ---------------------------------------------------------------------------

  ImageRenderer? _imageRenderer;
  VideoRenderer? _videoRenderer;
  LottieRenderer? _lottieRenderer;
  ShaderRenderer? _shaderRenderer;

  /// The currently active renderer, or `null` if no wallpaper is running.
  Object? _activeRenderer;

  /// The type of the currently active wallpaper.
  WallpaperType? _activeType;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  WallpaperState _state = WallpaperState.idle;
  final ValueNotifier<WallpaperState> _stateNotifier =
      ValueNotifier<WallpaperState>(WallpaperState.idle);

  /// The current engine state.
  WallpaperState get state => _state;

  /// A [ValueNotifier] that fires whenever [state] changes.
  ValueNotifier<WallpaperState> get stateNotifier => _stateNotifier;

  /// The currently active wallpaper type, or `null`.
  WallpaperType? get activeType => _activeType;

  /// Whether the engine has been initialised.
  bool get isInitialised =>
      _imageRenderer != null || _videoRenderer != null ||
      _lottieRenderer != null || _shaderRenderer != null;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the engine and creates all renderer instances.
  ///
  /// Call this once before starting a wallpaper.
  Future<void> initialise() async {
    _imageRenderer = ImageRenderer();
    _videoRenderer = VideoRenderer();
    _lottieRenderer = LottieRenderer();
    _shaderRenderer = ShaderRenderer();
    _setState(WallpaperState.idle);
  }

  /// Loads and starts a wallpaper from [wallpaperPath].
  ///
  /// The [type] parameter specifies the renderer to use.  If omitted the
  /// engine attempts to infer the type from the file extension.
  ///
  /// Supported extensions:
  ///   - image: .png, .jpg, .jpeg, .bmp, .webp
  ///   - video: .mp4, .webm, .mov, .gif, .avi, .mkv
  ///   - lottie: .json
  ///   - shader: .glsl, .frag
  Future<void> start(
    String wallpaperPath, {
    String? type,
  }) async {
    _ensureInitialised();

    // Stop any currently active wallpaper.
    await stopInternal();

    final resolvedType = type ?? _inferType(wallpaperPath);
    _setState(WallpaperState.loading);

    try {
      switch (resolvedType) {
        case 'image':
          await _startImage(wallpaperPath);
          break;
        case 'video':
          await _startVideo(wallpaperPath);
          break;
        case 'lottie':
          await _startLottie(wallpaperPath);
          break;
        case 'shader':
          await _startShader(wallpaperPath);
          break;
        default:
          throw ArgumentError('Unknown wallpaper type: $resolvedType');
      }
      _setState(WallpaperState.playing);
    } catch (e) {
      print('WallpaperEngine.start error: $e');
      _setState(WallpaperState.error, error: e);
    }
  }

  /// Stops the currently active wallpaper and releases its resources.
  void stop() {
    if (_state == WallpaperState.idle) return;
    stopInternal();
    _setState(WallpaperState.idle);
  }

  /// Internal stop that releases the active renderer without changing state.
  Future<void> stopInternal() async {
    if (_activeRenderer != null) {
      switch (_activeType) {
        case WallpaperType.image:
          (_activeRenderer as ImageRenderer).dispose();
          break;
        case WallpaperType.video:
          (_activeRenderer as VideoRenderer).dispose();
          break;
        case WallpaperType.lottie:
          (_activeRenderer as LottieRenderer).dispose();
          break;
        case WallpaperType.shader:
          (_activeRenderer as ShaderRenderer).dispose();
          break;
        case null:
          break;
      }
    }

    // Re-create renderers so they can be reused.
    _imageRenderer = ImageRenderer();
    _videoRenderer = VideoRenderer();
    _lottieRenderer = LottieRenderer();
    _shaderRenderer = ShaderRenderer();

    _activeRenderer = null;
    _activeType = null;
  }

  /// Pauses the active wallpaper without releasing resources.
  void pause() {
    _ensureInitialised();
    if (_state != WallpaperState.playing) return;

    switch (_activeType) {
      case WallpaperType.video:
        _videoRenderer?.pause();
        break;
      case WallpaperType.lottie:
        _lottieRenderer?.pause();
        break;
      default:
        // Image and shader wallpapers are static; pausing is a no-op.
        break;
    }
    _setState(WallpaperState.paused);
  }

  /// Resumes a paused wallpaper.
  void resume() {
    _ensureInitialised();
    if (_state != WallpaperState.paused) return;

    switch (_activeType) {
      case WallpaperType.video:
        _videoRenderer?.play();
        break;
      case WallpaperType.lottie:
        _lottieRenderer?.play();
        break;
      default:
        break;
    }
    _setState(WallpaperState.playing);
  }

  /// Releases all resources held by the engine and its renderers.
  ///
  /// After calling [dispose] the engine should not be reused without
  /// another call to [initialise].
  Future<void> dispose() async {
    // Stop active wallpaper first.
    if (_activeRenderer != null) {
      switch (_activeType) {
        case WallpaperType.image:
          (_activeRenderer as ImageRenderer).dispose();
          break;
        case WallpaperType.video:
          (_activeRenderer as VideoRenderer).dispose();
          break;
        case WallpaperType.lottie:
          (_activeRenderer as LottieRenderer).dispose();
          break;
        case WallpaperType.shader:
          (_activeRenderer as ShaderRenderer).dispose();
          break;
        case null:
          break;
      }
    }

    _imageRenderer?.dispose();
    _videoRenderer?.dispose();
    _lottieRenderer?.dispose();
    _shaderRenderer?.dispose();

    _imageRenderer = null;
    _videoRenderer = null;
    _lottieRenderer = null;
    _shaderRenderer = null;
    _activeRenderer = null;
    _activeType = null;

    _setState(WallpaperState.idle);
    _stateNotifier.dispose();
  }

  // ---------------------------------------------------------------------------
  // Internal – start specific renderer types
  // ---------------------------------------------------------------------------

  Future<void> _startImage(String path) async {
    final renderer = _imageRenderer!;
    await renderer.load(path);
    _activeRenderer = renderer;
    _activeType = WallpaperType.image;
  }

  Future<void> _startVideo(String path) async {
    final renderer = _videoRenderer!;
    final ok = await renderer.open(path);
    if (!ok) {
      throw Exception('Failed to open video: $path');
    }
    renderer.play();
    _activeRenderer = renderer;
    _activeType = WallpaperType.video;
  }

  Future<void> _startLottie(String path) async {
    final renderer = _lottieRenderer!;
    final composition = await renderer.load(path);
    if (composition == null) {
      throw Exception('Failed to load Lottie animation: $path');
    }
    renderer.play();
    _activeRenderer = renderer;
    _activeType = WallpaperType.lottie;
  }

  Future<void> _startShader(String path) async {
    final renderer = _shaderRenderer!;
    final ok = await renderer.load(path);
    if (!ok) {
      throw Exception('Failed to load shader: $path');
    }
    _activeRenderer = renderer;
    _activeType = WallpaperType.shader;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Infers the wallpaper type from a file extension.
  String _inferType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.json')) return 'lottie';
    if (lower.endsWith('.glsl') || lower.endsWith('.frag')) return 'shader';
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv')) {
      return 'video';
    }
    // Default to image for common image formats.
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    // Unknown — default to image.
    return 'image';
  }

  void _ensureInitialised() {
    if (!isInitialised) {
      throw StateError(
        'WallpaperEngine has not been initialised. Call initialise() first.',
      );
    }
  }

  void _setState(WallpaperState newState, {Object? error}) {
    _state = newState;
    _stateNotifier.value = newState;
  }
}
