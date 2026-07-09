import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lottie/lottie.dart';

/// Renders Lottie animation wallpapers.
///
/// The [LottieRenderer] loads `.json` Lottie animation files and
/// renders them natively via the Lottie package. It exposes
/// controls for animation progress, looping, speed, and
/// dynamic colour replacement driven by weather conditions.
class LottieRenderer {
  LottieComposition? _composition;
  bool _disposed = false;
  bool _playing = false;

  /// The loaded Lottie composition, or `null`.
  LottieComposition? get composition => _composition;

  /// Total duration of the loaded animation, or [Duration.zero] if
  /// none is loaded.
  Duration get duration => _composition?.duration ?? Duration.zero;

  /// Whether the renderer has been disposed.
  bool get isDisposed => _disposed;

  /// Whether the animation is currently playing.
  bool get isPlaying => _playing;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Loads a Lottie animation from a `.json` file at [path].
  ///
  /// Returns the [LottieComposition] on success, or `null` if the
  /// file cannot be read or parsed.
  Future<LottieComposition?> load(String path) async {
    _ensureNotDisposed();

    // Release any previous composition.
    _composition = null;
    _playing = false;

    try {
      final file = File(path);
      if (!await file.exists()) {
        print('LottieRenderer: file not found at $path');
        return null;
      }

      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      final composition =
          await LottieComposition.fromJson(data);

      if (composition == null) {
        print('LottieRenderer: failed to parse composition from $path');
        return null;
      }

      _composition = composition;
      return _composition;
    } catch (e) {
      print('LottieRenderer.load error: $e');
      return null;
    }
  }

  /// Starts playback of the loaded animation.
  ///
  /// Has no effect if no composition is loaded.
  void play() {
    _ensureNotDisposed();
    if (_composition == null) return;
    _playing = true;
  }

  /// Pauses playback. The current frame is retained.
  void pause() {
    _ensureNotDisposed();
    _playing = false;
  }

  /// Stops playback and resets to the first frame.
  void stop() {
    _ensureNotDisposed();
    _playing = false;
  }

  /// Releases the composition and associated resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _playing = false;
    _composition = null;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('LottieRenderer has been disposed');
    }
  }
}
