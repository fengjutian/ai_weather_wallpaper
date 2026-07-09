import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lottie/lottie.dart';

/// Renders Lottie animation wallpapers.
///
/// Loads `.json` Lottie animation files and renders them via the Lottie
/// package. Exposes controls for animation progress, looping, and speed.
class LottieRenderer {
  LottieComposition? _composition;
  bool _disposed = false;
  bool _playing = false;

  LottieComposition? get composition => _composition;
  Duration get duration => _composition?.duration ?? Duration.zero;
  bool get isDisposed => _disposed;
  bool get isPlaying => _playing;

  /// Loads a Lottie animation from a `.json` file at [path].
  Future<LottieComposition?> load(String path) async {
    _ensureNotDisposed();
    _composition = null;
    _playing = false;

    try {
      final file = File(path);
      if (!await file.exists()) {
        print('LottieRenderer: file not found at $path');
        return null;
      }

      final bytes = await file.readAsBytes();
      final composition = await LottieComposition.fromBytes(
        Uint8List.fromList(bytes),
      );

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

  void play() => _playing = true;
  void pause() => _playing = false;
  void stop() {
    _playing = false;
    _composition = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _composition = null;
    _playing = false;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('LottieRenderer has been disposed');
    }
  }
}
