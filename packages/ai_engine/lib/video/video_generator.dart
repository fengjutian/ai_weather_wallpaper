/// Supported AI video generation providers.
///
/// These represent services that can generate video from text prompts.
/// Actual integration is planned for future releases.
enum VideoProvider {
  /// OpenAI Sora — text-to-video model.
  sora,

  /// Runway Gen-2 / Gen-3.
  runway,

  /// Pika Labs.
  pika,

  /// Kling (Kuaishou).
  kling,
}

/// A service for generating videos using AI video generation models.
///
/// This is currently a stub that indicates video generation is not yet
/// available.  It serves as a placeholder for future integration with
/// services like OpenAI Sora, Runway, Pika, and Kling.
class VideoGenerator {
  /// Generates a video from the given [prompt].
  ///
  /// [provider] selects which backend to use (default: [VideoProvider.sora]).
  ///
  /// Returns a placeholder URL string when video generation becomes available,
  /// or `null` as a stub value for now.
  Future<String?> generateVideo(
    String prompt, {
    VideoProvider provider = VideoProvider.sora,
  }) async {
    // Stub: video generation is not yet implemented.
    // When ready, this will:
    //   1. Route to the appropriate provider's API.
    //   2. Submit the generation job.
    //   3. Poll for completion (or use a webhook).
    //   4. Return the URL of the generated video.
    return null;
  }

  /// Returns `true` if the given [provider] is currently available for use.
  ///
  /// All providers return `false` until video generation is implemented.
  bool isAvailable(VideoProvider provider) => false;
}
