import 'dart:typed_data';
import 'dart:ui' as ui;

/// A service for upscaling (super-resolution) of generated images using
/// nearest-neighbour interpolation.
///
/// This can be used to increase the resolution of AI-generated images that
/// may be produced at lower resolutions (e.g., 1024×1024) when higher
/// resolutions are desired for wallpaper use (e.g., 4K displays).
///
/// The implementation uses [dart:ui] to decode the image, draw it at a larger
/// size with nearest-neighbour (point) sampling to preserve hard edges, and
/// re-encode as PNG.
class ImageUpscaler {
  /// The default upscaling factor.
  final int scaleFactor;

  /// Creates an [ImageUpscaler] with the given [scaleFactor] (2 or 4).
  ///
  /// Throws [UnsupportedError] if [scaleFactor] is not 2 or 4.
  ImageUpscaler({this.scaleFactor = 2}) {
    if (scaleFactor != 2 && scaleFactor != 4) {
      throw UnsupportedError(
        'ImageUpscaler only supports scale factors of 2 or 4, got $scaleFactor.',
      );
    }
  }

  /// Upscales the image provided as [imageData] (raw PNG/JPEG bytes).
  ///
  /// Returns the upscaled image bytes as PNG.
  ///
  /// Internally decodes the image, scales it up by repeating pixels
  /// (nearest-neighbour interpolation), and encodes the result as PNG.
  ///
  /// Throws [UnsupportedError] if [scaleFactor] is not 2 or 4.
  Future<Uint8List> upscale(Uint8List imageData, {int scaleFactor = 2}) async {
    if (scaleFactor != 2 && scaleFactor != 4) {
      throw UnsupportedError(
        'ImageUpscaler only supports scale factors of 2 or 4, got $scaleFactor.',
      );
    }

    // Decode the original image using dart:ui codec.
    final codec = await ui.instantiateImageCodec(
      imageData,
      targetWidth: null, // decode at original size
      targetHeight: null,
    );
    final frameInfo = await codec.getNextFrame();
    final originalImage = frameInfo.image;
    await codec.dispose();

    final origWidth = originalImage.width;
    final origHeight = originalImage.height;
    final newWidth = origWidth * scaleFactor;
    final newHeight = origHeight * scaleFactor;

    // Create a canvas at the new size.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Paint with nearest-neighbour filtering to avoid blurriness.
    final paint = Paint()
      ..filterQuality = ui.FilterQuality.none;

    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(0, 0, origWidth.toDouble(), origHeight.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final scaledImage = await picture.toImage(newWidth, newHeight);
    await picture.dispose();
    originalImage.dispose();

    // Encode as PNG bytes.
    final byteData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
    scaledImage.dispose();

    if (byteData == null) {
      throw Exception('Failed to encode upscaled image as PNG.');
    }

    return byteData.buffer.asUint8List();
  }

  /// Returns the estimated output dimensions after upscaling [originalWidth]
  /// × [originalHeight] by this upscaler's [scaleFactor].
  (int width, int height) getOutputSize(int originalWidth, int originalHeight) {
    return (originalWidth * scaleFactor, originalHeight * scaleFactor);
  }
}
