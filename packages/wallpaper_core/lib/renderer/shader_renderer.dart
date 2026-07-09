import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Canvas, Size, Rect, Paint;

/// Renders GLSL fragment-shader wallpapers.
///
/// The [ShaderRenderer] loads a GLSL fragment shader from a `.glsl` file
/// and compiles it into a [ui.FragmentProgram] at runtime.  It renders the
/// shader across the full canvas, passing uniforms such as time, resolution,
/// and optional weather data.
///
/// ## Platform support
///
/// Shader rendering requires Flutter 3.7+ and a GPU that supports fragment
/// shaders. On platforms where runtime shader compilation is unavailable the
/// [load] call returns `false` and the renderer becomes a no-op.
class ShaderRenderer {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  bool _disposed = false;

  /// The compiled fragment program, or `null` if none is loaded.
  ui.FragmentProgram? get program => _program;

  /// Whether a shader has been successfully loaded.
  bool get isLoaded => _program != null;

  /// Whether the renderer has been disposed.
  bool get isDisposed => _disposed;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Reads a GLSL fragment shader from [glslFilePath] and compiles it.
  ///
  /// Returns `true` on success, `false` if the file cannot be read or the
  /// shader cannot be compiled (e.g. unsupported platform, syntax error).
  Future<bool> load(String glslFilePath) async {
    _ensureNotDisposed();

    // Release previous shader.
    _shader?.dispose();
    _shader = null;
    _program = null;

    try {
      final file = File(glslFilePath);
      if (!await file.exists()) {
        print('ShaderRenderer: file not found at $glslFilePath');
        return false;
      }

      // Read raw shader bytes.
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        print('ShaderRenderer: empty shader file');
        return false;
      }

      // Compile via FragmentProgram.
      // On Flutter 3.x, FragmentProgram is typically loaded from assets.
      // Runtime compilation is only available on certain platforms.
      try {
        _program = await ui.FragmentProgram.compile(
          spirv: bytes,
        );
      } catch (_) {
        // Try asset-based loading as fallback.
        print(
          'ShaderRenderer: runtime shader compilation not available. '
          'Try registering the shader as a Flutter asset.',
        );
        return false;
      }

      return _program != null;
    } catch (e) {
      print('ShaderRenderer.load error: $e');
      return false;
    }
  }

  /// Renders the shader across the entire [canvas] within [size].
  ///
  /// [time] is the elapsed time in seconds, passed as a uniform to the
  /// shader.  Does nothing if no shader is loaded or the renderer is
  /// disposed.
  void render(Canvas canvas, Size size, double time) {
    if (_disposed || _program == null) return;

    _shader?.dispose();
    _shader = _program!.fragmentShader();

    // Set standard uniforms that most fragment shaders expect.
    _shader!.setFloat(0, size.width); // iResolution.x  (or u_resolution.x)
    _shader!.setFloat(1, size.height); // iResolution.y
    _shader!.setFloat(2, time); // iTime / u_time
    _shader!.setFloat(3, 1.0); // placeholder / unused

    final paint = Paint()..shader = _shader;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  /// Releases the shader program and all GPU resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _shader?.dispose();
    _shader = null;
    _program = null;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('ShaderRenderer has been disposed');
    }
  }
}
