/// Abstract interface for AI image generation.
///
/// Implementations can connect to various image generation services such as
/// OpenAI DALL·E, Stable Diffusion, Midjourney, etc.
abstract class ImageGenerator {
  /// Generates an image from the given [prompt] and returns the image data
  /// (e.g., bytes of a PNG/JPEG) or a URL where the image can be downloaded.
  ///
  /// [size] defines the desired output dimensions (e.g., "1024x1024").
  /// [n] specifies the number of images to generate.
  Future<ImageGenerationResult> generateImage({
    required String prompt,
    String? size,
    int n = 1,
  });

  /// Validates the current configuration (API keys, endpoints, etc.).
  /// Returns `true` if the generator is ready to be used.
  Future<bool> validateConfig();
}

/// The result of an image generation request.
class ImageGenerationResult {
  /// The generated image data, if available as raw bytes.
  final List<int>? imageBytes;

  /// A URL pointing to the generated image, if provided by the service.
  final String? imageUrl;

  /// The prompt used for generation (may be modified by the service).
  final String prompt;

  const ImageGenerationResult({
    this.imageBytes,
    this.imageUrl,
    required this.prompt,
  });
}

/// A stub implementation of [ImageGenerator] using OpenAI's DALL·E API.
///
/// TODO: Implement actual API calls.
/// - Add HTTP client dependency.
/// - Implement authentication via API key.
/// - Handle rate limiting and error responses.
/// - Support different DALL·E models (dall-e-2, dall-e-3).
/// - Implement response parsing.
class OpenAIImageGenerator implements ImageGenerator {
  /// The API key for OpenAI.
  final String? apiKey;

  /// The model to use (e.g., "dall-e-3").
  final String model;

  const OpenAIImageGenerator({
    this.apiKey,
    this.model = 'dall-e-3',
  });

  @override
  Future<ImageGenerationResult> generateImage({
    required String prompt,
    String? size,
    int n = 1,
  }) async {
    // TODO: Implement actual HTTP POST request to OpenAI Images API.
    // POST https://api.openai.com/v1/images/generations
    // Headers: Authorization: Bearer $apiKey, Content-Type: application/json
    // Body: { "model": model, "prompt": prompt, "n": n, "size": size }
    throw UnimplementedError(
      'OpenAIImageGenerator.generateImage() is not yet implemented.',
    );
  }

  @override
  Future<bool> validateConfig() async {
    // TODO: Check that apiKey is non-null and optionally make a lightweight
    // validation request to the API.
    return apiKey != null && apiKey!.isNotEmpty;
  }
}
