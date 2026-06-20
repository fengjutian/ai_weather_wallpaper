import '../renderer/image_renderer.dart';
import '../renderer/video_renderer.dart';
import '../renderer/lottie_renderer.dart';
import '../renderer/shader_renderer.dart';

/// Manages the lifecycle of wallpapers.
///
/// [WallpaperEngine] acts as the central coordinator — it loads
/// the appropriate renderer based on wallpaper type, handles
/// the transition between wallpapers, manages resource cleanup,
/// and applies global configuration (fps limit, quality, etc.).
///
/// This class follows a singleton-like pattern: access the shared
/// instance via [instance].
class WallpaperEngine {
  // ---------------------------------------------------------------------------
  // Singleton pattern
  // ---------------------------------------------------------------------------

  static final WallpaperEngine _singleton = WallpaperEngine._internal();

  /// Returns the shared [WallpaperEngine] instance.
  static WallpaperEngine get instance => _singleton;

  WallpaperEngine._internal();

  // ---------------------------------------------------------------------------
  // Renderer instances (lazily initialized)
  // ---------------------------------------------------------------------------

  ImageRenderer? _imageRenderer;
  VideoRenderer? _videoRenderer;
  LottieRenderer? _lottieRenderer;
  ShaderRenderer? _shaderRenderer;

  /// The currently active renderer, or `null` if no wallpaper is running.
  Object? _activeRenderer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the engine and acquires any necessary platform resources.
  ///
  /// Call this once before starting a wallpaper.
  Future<void> initialise() async {
    // TODO: set up platform channels, register event listeners
  }

  /// Starts the wallpaper with the given [renderer].
  ///
  /// The [renderer] should be one of [ImageRenderer], [VideoRenderer],
  /// [LottieRenderer], or [ShaderRenderer].
  void start(Object renderer) {
    // TODO: attach renderer to the compositor, begin frame loop
  }

  /// Stops the currently active wallpaper and releases its resources.
  void stop() {
    // TODO: tear down active renderer, release GPU/IO resources
  }

  /// Pauses the active wallpaper without releasing resources.
  void pause() {
    // TODO: pause frame loop / video playback
  }

  /// Resumes a paused wallpaper.
  void resume() {
    // TODO: resume frame loop / video playback
  }

  /// Releases all resources held by the engine and its renderers.
  ///
  /// After calling [dispose] the engine should not be reused without
  /// another call to [initialise].
  Future<void> dispose() async {
    // TODO: clean up all renderers, close platform channels
  }
}
