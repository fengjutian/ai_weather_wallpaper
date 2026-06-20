import 'package:flutter/material.dart';

/// An animated widget for transitioning between wallpaper scenes.
///
/// Wraps a [child] and applies an animated visual effect (e.g. cross-fade,
/// scale, or slide) whenever [animationKey] changes, providing a smooth
/// transition between AI-generated wallpapers.
///
/// ```dart
/// SceneTransition(
///   animationKey: currentSceneId,
///   duration: Duration(milliseconds: 800),
///   child: Image.network(currentWallpaperUrl),
/// )
/// ```
class SceneTransition extends StatefulWidget {
  /// The child widget to display (typically the wallpaper image).
  final Widget child;

  /// An identifier that, when changed, triggers the transition animation.
  final Object animationKey;

  /// Duration of the transition animation.
  final Duration duration;

  /// The type of transition effect to apply.
  final SceneTransitionType transitionType;

  const SceneTransition({
    super.key,
    required this.child,
    required this.animationKey,
    this.duration = const Duration(milliseconds: 600),
    this.transitionType = SceneTransitionType.fade,
  });

  @override
  State<SceneTransition> createState() => _SceneTransitionState();
}

class _SceneTransitionState extends State<SceneTransition>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Object? _previousKey;
  Widget? _previousChild;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = widget.transitionType.buildAnimation(_controller);
    _previousKey = widget.animationKey;
  }

  @override
  void didUpdateWidget(SceneTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationKey != oldWidget.animationKey) {
      _previousChild = oldWidget.child;
      _previousKey = oldWidget.animationKey;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_controller.value < 1.0 && _previousChild != null)
              widget.transitionType.buildPreviousLayer(
                child: _previousChild!,
                animationValue: _controller.value,
              ),
            widget.transitionType.buildCurrentLayer(
              child: widget.child,
              animationValue: _controller.value,
            ),
          ],
        );
      },
    );
  }
}

/// Supported transition effect types.
enum SceneTransitionType {
  /// Simple cross-fade between old and new scene.
  fade,

  /// New scene scales up from 0.9 to 1.0 while fading in.
  scale,

  /// New scene slides in from the bottom.
  slideUp;

  Animation<double> buildAnimation(AnimationController controller) {
    return switch (this) {
      SceneTransitionType.fade => CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      SceneTransitionType.scale => CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      SceneTransitionType.slideUp => CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
    };
  }

  Widget buildCurrentLayer({
    required Widget child,
    required double animationValue,
  }) {
    switch (this) {
      case SceneTransitionType.fade:
        return Opacity(opacity: animationValue, child: child);
      case SceneTransitionType.scale:
        return Opacity(
          opacity: animationValue,
          child: Transform.scale(
            scale: 0.9 + (0.1 * animationValue),
            child: child,
          ),
        );
      case SceneTransitionType.slideUp:
        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, (1 - animationValue) * 60),
            child: Opacity(opacity: animationValue, child: child),
          ),
        );
    }
  }

  Widget buildPreviousLayer({
    required Widget child,
    required double animationValue,
  }) {
    switch (this) {
      case SceneTransitionType.fade:
        return Opacity(opacity: 1.0 - animationValue, child: child);
      case SceneTransitionType.scale:
        return child; // old scene stays static beneath the scaling new one
      case SceneTransitionType.slideUp:
        return Opacity(
          opacity: 1.0 - animationValue,
          child: Transform.translate(
            offset: Offset(0, -(1 - animationValue) * 30),
            child: child,
          ),
        );
    }
  }
}
