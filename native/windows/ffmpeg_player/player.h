// player.h — FFmpeg-based media player for wallpaper video playback
//
// Supports MP4, WebM, GIF, and MOV formats. Wraps FFmpeg decoding
// and Direct3D rendering into a simple playback interface.

#pragma once

#include <windows.h>
#include <string>
#include <functional>

namespace ai_weather_wallpaper {

/// Callback type: receives decoded video frames as raw RGBA data.
using VideoFrameCallback = std::function<void(const uint8_t* data,
                                               int width,
                                               int height,
                                               int stride)>;

/// Playback state machine.
enum class PlaybackState {
  Stopped,
  Playing,
  Paused,
  Buffering,
  Error
};

/// Media format supported by the player.
enum class MediaFormat {
  MP4,
  WebM,
  GIF,
  MOV
};

/// High-level media player for wallpaper video/animations.
class MediaPlayer {
 public:
  MediaPlayer();
  ~MediaPlayer();

  /// Open a media file from [path].
  /// Returns true if the file was opened successfully.
  bool Open(const std::wstring& path);

  /// Start or resume playback.
  void Play();

  /// Pause playback (frame held).
  void Pause();

  /// Stop playback and seek to beginning.
  void Stop();

  /// Seek to a specific time position (in seconds).
  void Seek(double seconds);

  /// Set volume (0.0 = mute, 1.0 = original).
  void SetVolume(double volume);

  /// Set loop mode (default: true for wallpapers).
  void SetLoop(bool loop);

  /// Returns the current playback state.
  PlaybackState state() const { return state_; }

  /// Register a callback for decoded video frames.
  void SetVideoFrameCallback(VideoFrameCallback callback);

  /// Returns the native media format detected.
  MediaFormat format() const { return format_; }

 private:
  std::wstring file_path_;
  PlaybackState state_;
  MediaFormat format_;
  double volume_;
  bool loop_;
  VideoFrameCallback frame_callback_;

  // FFmpeg context (forward declare — actual data lives in .cpp)
  struct FFmpegContext;
  std::unique_ptr<FFmpegContext> ffmpeg_;

  /// Detect media format from file extension.
  MediaFormat DetectFormat(const std::wstring& path);

  /// Internal decode loop (runs on a background thread).
  void DecodeLoop();
};

}  // namespace ai_weather_wallpaper
