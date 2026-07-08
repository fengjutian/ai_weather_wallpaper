import 'dart:convert';
import 'dart:io';

import '../image/image_generator.dart' show AiApiException;

/// A service for optimizing and refining prompts using OpenAI's chat
/// completions API.
///
/// This service can be used to:
/// - Enhance raw weather descriptions into detailed image generation prompts.
/// - Translate natural-language requests into structured prompt text.
/// - Have general conversations with the LLM with optional history.
///
/// All API calls use dart:io [HttpClient] (no external HTTP package).
class LLMService {
  final String apiKey;
  final String? baseUrl;
  final String _model;

  /// Creates an [LLMService] with the given OpenAI [apiKey].
  ///
  /// [apiKey] is required.  [baseUrl] can override the default endpoint
  /// (useful for proxies or compatible services).  [model] sets the model
  /// identifier (default `gpt-4o`).
  LLMService({
    required this.apiKey,
    this.baseUrl,
    String model = 'gpt-4o',
  }) : _model = model;

  String get _apiBase =>
      (baseUrl ?? 'https://api.openai.com').replaceAll(RegExp(r'/+$'), '');

  /// Optimises a weather [prompt] into a vivid, detailed image generation prompt.
  ///
  /// Sends a chat completion request with a system message instructing the
  /// model to act as a wallpaper prompt expert.
  ///
  /// Returns the LLM's enhanced prompt text.
  Future<String> optimizePrompt(String prompt) async {
    return _chatCompletion(
      systemMessage:
          'You are a wallpaper prompt expert. Enhance this weather wallpaper '
          'prompt with vivid details.',
      userMessage: prompt,
    );
  }

  /// Translates [text] into an English image-generation prompt.
  ///
  /// [targetLang] defaults to `'en'`.  The model is instructed to translate
  /// the text and enhance it as an image generation prompt.
  Future<String> translateToPrompt(String text, {String targetLang = 'en'}) async {
    final langName = _languageName(targetLang);
    return _chatCompletion(
      systemMessage:
          'Translate the following text to $langName and enhance it as an '
          'image generation prompt.',
      userMessage: text,
    );
  }

  /// Sends a general chat message to the LLM with optional conversation [history].
  ///
  /// [history] is a list of `{'role': '...', 'content': '...'}` maps in the
  /// standard OpenAI messages format.  The [message] is appended as the latest
  /// user message.
  ///
  /// Returns the assistant's reply.
  Future<String> chat(
    String message, {
    List<Map<String, String>>? history,
  }) async {
    final messages = <Map<String, String>>[
      if (history != null) ...history,
      {'role': 'user', 'content': message},
    ];

    return _chatCompletionWithMessages(messages);
  }

  // ─── Internal helpers ──────────────────────────────────────────────────────

  /// Performs a simple two-message (system + user) chat completion.
  Future<String> _chatCompletion({
    required String systemMessage,
    required String userMessage,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemMessage},
      {'role': 'user', 'content': userMessage},
    ];
    return _chatCompletionWithMessages(messages);
  }

  /// Sends a chat completion request with a full [messages] list.
  Future<String> _chatCompletionWithMessages(
    List<Map<String, String>> messages,
  ) async {
    final uri = Uri.parse('$_apiBase/v1/chat/completions');
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $apiKey');

      final body = jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.7,
      });

      request.add(utf8.encode(body));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        _parseAndThrowError(responseBody, response.statusCode);
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>;
      if (choices.isEmpty) {
        throw const AiApiException('No choices returned by chat completions API.');
      }

      final message = choices[0]['message'] as Map<String, dynamic>;
      final content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw const AiApiException('Empty response from chat completions API.');
      }

      return content.trim();
    } finally {
      client.close();
    }
  }

  /// Maps a language code to a human-readable language name.
  String _languageName(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return 'English';
      case 'zh':
      case 'zh-cn':
      case 'zh-hans':
        return 'Chinese';
      case 'zh-tw':
      case 'zh-hk':
      case 'zh-hant':
        return 'Traditional Chinese';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'es':
        return 'Spanish';
      default:
        return code;
    }
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
