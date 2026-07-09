import 'dart:ui' show Canvas, Size;

/// Renders GLSL fragment-shader wallpapers.
///
/// Shader rendering requires pre-compiled SPIRV shaders registered as
/// Flutter assets. This renderer is a placeholder for future GPU shader
/// wallpaper support.
class ShaderRenderer {
  bool _disposed = false;

  bool get isLoaded => false;
  bool get isDisposed => _disposed;

  /// Not yet implemented — requires SPIRV-compiled shader assets.
  Future<bool> load(String glslFilePath) async {
    return false;
  }

  /// No-op: shader rendering not yet available.
  void render(Canvas canvas, Size size, double time) {}

  void dispose() {
    _disposed = true;
  }
}
