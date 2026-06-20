import 'dart:async';
import 'package:flutter/animation.dart';
import '../engine/wallpaper_engine.dart';

/// The type of transition between wallpapers.
enum TransitionType {
  /// Instant switch — no animation.
  instant,

  /// Cross-fade (dissolve) between the old and new wallpaper.
  fade,

  /// Slide the new wallpaper in from the right.
  slide,

  /// Slide the new wallpaper in from the left.
  slideLeft,
}

/// Manages scene transitions between wallpapers.
///
/// [SceneManager] orchestrates smooth transitions when switching
/// from one wallpaper to another. It supports cross-fade, slide,
/// and instant transition effects, and controls the timing and
/// easing curves for each transition.
class SceneManager {
  final WallpaperEngine _engine;
  final TickerProvider _vsync;

  AnimationController? _animationController;
  Animation<double>? _animation;

  TransitionType _transitionType = TransitionType.fade;
  Duration _transitionDuration = const Duration(milliseconds: 500);

  bool _disposed = false;

  /// The currently active transition type.
  TransitionType get transitionType => _transitionType;

  /// The duration of the current transition animation.
  Duration get transitionDuration => _transitionDuration;

  /// The current animation value (0.0 → 1.0 during a transition, 1.0 when
  /// idle). Useful for manually blending two wallpapers in a custom painter.
  double get progress => _animation?.value ?? 1.0;

  /// Whether a transition is currently in progress.
  bool get isTransitioning =>
      _animationController != null && _animationController!.isAnimating;

  /// Creates a [SceneManager] linked to [engine].
  ///
  /// [vsync] is required for the internal [AnimationController]; typically
  /// a [TickerProviderStateMixin] or [SingleTickerProviderStateMixin].
  SceneManager({
    required WallpaperEngine engine,
    required TickerProvider vsync,
  })  : _engine = engine,
        _vsync = vsync;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Sets the transition type to [type].
  void setTransition(TransitionType type) {
    _transitionType = type;
  }

  /// Sets the transition duration to [duration].
  void setTransitionDuration(Duration duration) {
    _transitionDuration = duration;
  }

  // ---------------------------------------------------------------------------
  // Switching
  // ---------------------------------------------------------------------------

  /// Switches to the wallpaper at [wallpaperPath] with the configured
  /// transition effect.
  ///
  /// If [type] is provided it overrides the inferred wallpaper type.
  /// A custom [transition] duration and [transitionType] can be supplied
  /// for this one switch without changing the global settings.
  Future<void> switchTo(
    String wallpaperPath, {
    String? type,
    Duration? transition,
    TransitionType? transitionType,
  }) async {
    _ensureNotDisposed();

    final dur = transition ?? _transitionDuration;
    final tt = transitionType ?? _transitionType;

    if (tt == TransitionType.instant || dur == Duration.zero) {
      // No animation — just start the new wallpaper directly.
      await _engine.start(wallpaperPath, type: type);
      return;
    }

    // Create an animation controller for this transition.
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: dur,
      vsync: _vsync,
    );

    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    // Start the new wallpaper in the background.
    // For a fade, we load the new wallpaper and animate the blend.
    await _engine.start(wallpaperPath, type: type);

    // Run the transition animation.
    await _animationController!.forward();

    // Clean up.
    _animationController!.dispose();
    _animationController = null;
    _animation = null;
  }

  /// Releases all resources held by the scene manager.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _animationController?.dispose();
    _animationController = null;
    _animation = null;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('SceneManager has been disposed');
    }
  }
}
