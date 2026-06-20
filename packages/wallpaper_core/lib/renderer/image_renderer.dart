import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Renders static image wallpapers (PNG, JPG, BMP, WebP).
///
/// The [ImageRenderer] handles loading, decoding, and rendering
/// raster image formats onto the wallpaper canvas. It supports
/// local file paths and network URLs.
class ImageRenderer {
  ui.Image? _image;
  bool _disposed = false;

  /// The decoded image, or `null` if none is loaded.
  ui.Image? get image => _image;

  /// Whether the renderer has been disposed.
  bool get isDisposed => _disposed;

  /// Loads and decodes an image from [path].
  ///
  /// [path] can be a local file path or an HTTP(S) URL.
  /// Supported formats: PNG, JPG, BMP, WebP, GIF (first frame).
  ///
  /// Returns the decoded [ui.Image]. Throws on failure.
  Future<ui.Image> load(String path) async {
    _checkDisposed();

    // Dispose any previously loaded image.
    _image?.dispose();
    _image = null;

    final Uint8List bytes;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      bytes = await _loadFromUrl(path);
    } else {
      bytes = await _loadFromFile(path);
    }

    if (bytes.isEmpty) {
      throw FormatException('Empty image data from $path');
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image? result) {
      if (result == null) {
        completer.completeError(
          FormatException('Failed to decode image from $path'),
        );
      } else {
        completer.complete(result);
      }
    });

    _image = await completer.future;
    return _image!;
  }

  /// Renders the loaded image onto [canvas] fitting within [size].
  ///
  /// Maintains aspect ratio and centres the image. Does nothing if
  /// no image is loaded or the renderer has been disposed.
  void render(Canvas canvas, Size size) {
    if (_disposed || _image == null) return;

    final src = _image!;
    final srcWidth = src.width.toDouble();
    final srcHeight = src.height.toDouble();

    // Scale to fit while maintaining aspect ratio.
    final scale = math.min(size.width / srcWidth, size.height / srcHeight);
    final dstWidth = srcWidth * scale;
    final dstHeight = srcHeight * scale;
    final dstLeft = (size.width - dstWidth) / 2;
    final dstTop = (size.height - dstHeight) / 2;

    canvas.drawImageRect(
      src,
      Rect.fromLTWH(0, 0, srcWidth, srcHeight),
      Rect.fromLTWH(dstLeft, dstTop, dstWidth, dstHeight),
      Paint(),
    );
  }

  /// Releases the underlying [ui.Image] resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _image?.dispose();
    _image = null;
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('ImageRenderer has been disposed');
    }
  }

  Future<Uint8List> _loadFromUrl(String url) async {
    final httpClient = HttpClient();
    try {
      final uri = Uri.parse(url);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to load image from $url, status: ${response.statusCode}',
          uri: uri,
        );
      }
      return await response.fold<Uint8List>(
        Uint8List(0),
        (prev, chunk) {
          final combined = Uint8List(prev.length + chunk.length);
          combined.setRange(0, prev.length, prev);
          combined.setRange(prev.length, combined.length, chunk);
          return combined;
        },
      );
    } finally {
      httpClient.close();
    }
  }

  Future<Uint8List> _loadFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('Image file not found', path);
    }
    return await file.readAsBytes();
  }
}
