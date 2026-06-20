import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Exception thrown when an AI API call fails.
class AiApiException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// The HTTP status code returned by the API, if applicable.
  final int? statusCode;

  /// Creates a new [AiApiException] with the given [message] and optional [statusCode].
  const AiApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'AiApiException($statusCode): $message';
    }
    return 'AiApiException: $message';
  }
}

/// Abstract interface for AI image generation.
///
/// Implementations connect to various image generation services such as
/// OpenAI DALL·E, Stable Diffusion, etc.
abstract class ImageGenerator {
  /// The human-readable name of this provider (e.g. "OpenAI DALL·E 3").
  String get providerName;

  /// Generates an image from the given [prompt] and returns the raw image bytes.
  ///
  /// [width] and [height] optionally specify the desired output dimensions.
  /// [seed] allows reproducible results when the provider supports it.
  ///
  /// Throws [AiApiException] on API errors.
  Future<Uint8List> generateImage(
    String prompt, {
    int? width,
    int? height,
    int? seed,
  });
}

/// An [ImageGenerator] that uses OpenAI's DALL·E 3 API via dart:io [HttpClient].
///
/// Requires an [apiKey] from OpenAI. An optional [baseUrl] can be provided for
/// proxy or compatible endpoints.
///
/// Example:
/// ```dart
/// final generator = OpenAIImageGenerator(apiKey: 'sk-...');
/// final bytes = await generator.generateImage('A serene mountain lake');
/// ```
class OpenAIImageGenerator implements ImageGenerator {
  final String apiKey;
  final String? baseUrl;
  final String _model;

  /// Creates a new [OpenAIImageGenerator].
  ///
  /// [apiKey] is required (OpenAI API key).
  /// [baseUrl] overrides the default API endpoint (defaults to
  /// `https://api.openai.com`).
  /// [model] sets the DALL·E model version (default `dall-e-3`).
  OpenAIImageGenerator({
    required this.apiKey,
    this.baseUrl,
    String model = 'dall-e-3',
  }) : _model = model;

  @override
  String get providerName => 'OpenAI DALL·E 3';

  String get _apiBase => (baseUrl ?? 'https://api.openai.com').replaceAll(RegExp(r'/+$'), '');

  @override
  Future<Uint8List> generateImage(
    String prompt, {
    int? width,
    int? height,
    int? seed,
  }) async {
    // Determine size string. DALL·E 3 supports: '1024x1024', '1792x1024', '1024x1792'
    final sizeStr = _resolveSize(width, height);

    final uri = Uri.parse('$_apiBase/v1/images/generations');
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $apiKey');

      final body = <String, dynamic>{
        'model': _model,
        'prompt': prompt,
        'n': 1,
        'size': sizeStr,
      };
      if (seed != null) {
        body['seed'] = seed;
      }

      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        _parseAndThrowError(responseBody, response.statusCode);
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>;
      if (data.isEmpty) {
        throw const AiApiException('No image data in API response.');
      }
      final imageUrl = data[0]['url'] as String;

      // Download the image data from the URL
      return await _downloadImage(imageUrl);
    } finally {
      client.close();
    }
  }

  /// Downloads raw image bytes from [url] using dart:io [HttpClient].
  Future<Uint8List> _downloadImage(String url) async {
    final uri = Uri.parse(url);
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw AiApiException(
          'Failed to download generated image (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } finally {
      client.close();
    }
  }

  /// Resolves the DALL·E size string from optional [width] and [height].
  ///
  /// Defaults to `'1792x1024'` (landscape) when no dimensions are given.
  String _resolveSize(int? width, int? height) {
    if (width != null && height != null) {
      // Clamp to supported sizes for DALL·E 3
      if (width == height) return '1024x1024';
      if (width > height) return '1792x1024';
      return '1024x1792';
    }
    if (width != null) {
      return width >= 1024 ? '1792x1024' : '1024x1024';
    }
    if (height != null) {
      return height >= 1024 ? '1024x1792' : '1024x1024';
    }
    return '1792x1024';
  }

  /// Parses an error response body and throws [AiApiException].
  void _parseAndThrowError(String responseBody, int statusCode) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? responseBody;
      throw AiApiException(message, statusCode: statusCode);
    } catch (_) {
      if (_ is AiApiException) rethrow;
      throw AiApiException(responseBody, statusCode: statusCode);
    }
  }
}

/// An [ImageGenerator] for Stable Diffusion–compatible APIs.
///
/// This is a basic implementation that sends a POST request to a configurable
/// [apiUrl]. The expected request/response format follows the Automatic1111
/// Stable Diffusion WebUI API.
///
/// Currently a stub — can be extended to support the full SD API.
class StableDiffusionGenerator implements ImageGenerator {
  /// The endpoint URL of the Stable Diffusion API (e.g. `http://localhost:7860/sdapi/v1/txt2img`).
  final String apiUrl;

  /// Optional API key for authenticated endpoints.
  final String? apiKey;

  /// Creates a new [StableDiffusionGenerator].
  ///
  /// [apiUrl] is the endpoint URL (required).
  /// [apiKey] is optional authentication token.
  StableDiffusionGenerator({required this.apiUrl, this.apiKey});

  @override
  String get providerName => 'Stable Diffusion';

  @override
  Future<Uint8List> generateImage(
    String prompt, {
    int? width,
    int? height,
    int? seed,
  }) async {
    final uri = Uri.parse(apiUrl);
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      if (apiKey != null && apiKey!.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $apiKey');
      }

      final body = <String, dynamic>{
        'prompt': prompt,
        'steps': 20,
        'cfg_scale': 7,
        'width': width ?? 1024,
        'height': height ?? 768,
      };
      if (seed != null) {
        body['seed'] = seed;
      }

      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw AiApiException(
          'Stable Diffusion API returned HTTP ${response.statusCode}: $responseBody',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final images = decoded['images'] as List<dynamic>?;

      if (images == null || images.isEmpty) {
        throw const AiApiException('No images returned by Stable Diffusion API.');
      }

      // SD API returns base64-encoded PNG data
      final base64Data = images[0] as String;
      return Uint8List.fromList(base64Decode(base64Data));
    } finally {
      client.close();
    }
  }
}
