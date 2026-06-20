// player.cpp — FFmpeg media player implementation

#include "player.h"
#include <iostream>
#include <algorithm>

namespace ai_weather_wallpaper {

struct MediaPlayer::FFmpegContext {
  // AVFormatContext* format_ctx;
  // AVCodecContext* codec_ctx;
  // AVStream* video_stream;
  // int video_stream_index;
  // SwsContext* sws_ctx;
  // TODO: Add FFmpeg context pointers when linking FFmpeg
  bool initialized = false;
};

MediaPlayer::MediaPlayer()
    : state_(PlaybackState::Stopped),
      format_(MediaFormat::MP4),
      volume_(1.0),
      loop_(true),
      ffmpeg_(std::make_unique<FFmpegContext>()) {}

MediaPlayer::~MediaPlayer() {
  Stop();
}

bool MediaPlayer::Open(const std::wstring& path) {
  file_path_ = path;
  format_ = DetectFormat(path);

  // TODO: Open file with FFmpeg (avformat_open_input, avformat_find_stream_info)
  // TODO: Find video stream and open decoder

  std::wcout << L"[MediaPlayer] Opened: " << path
             << L" (format: " << static_cast<int>(format_) << L")" << std::endl;

  return true;  // Stub: return true until FFmpeg is linked
}

void MediaPlayer::Play() {
  if (state_ == PlaybackState::Playing) return;
  state_ = PlaybackState::Playing;
  // TODO: Start decode loop thread
  std::cout << "[MediaPlayer] Play" << std::endl;
}

void MediaPlayer::Pause() {
  if (state_ != PlaybackState::Playing) return;
  state_ = PlaybackState::Paused;
  std::cout << "[MediaPlayer] Pause" << std::endl;
}

void MediaPlayer::Stop() {
  state_ = PlaybackState::Stopped;
  // TODO: Join decode thread, seek to 0
  std::cout << "[MediaPlayer] Stop" << std::endl;
}

void MediaPlayer::Seek(double seconds) {
  if (!ffmpeg_->initialized) return;
  // TODO: av_seek_frame
}

void MediaPlayer::SetVolume(double volume) {
  volume_ = std::clamp(volume, 0.0, 1.0);
}

void MediaPlayer::SetLoop(bool loop) {
  loop_ = loop;
}

void MediaPlayer::SetVideoFrameCallback(VideoFrameCallback callback) {
  frame_callback_ = std::move(callback);
}

MediaFormat MediaPlayer::DetectFormat(const std::wstring& path) {
  auto ext = path.substr(path.find_last_of(L'.') + 1);
  std::transform(ext.begin(), ext.end(), ext.begin(), ::towlower);

  if (ext == L"webm") return MediaFormat::WebM;
  if (ext == L"gif")  return MediaFormat::GIF;
  if (ext == L"mov")  return MediaFormat::MOV;
  return MediaFormat::MP4;  // Default
}

void MediaPlayer::DecodeLoop() {
  // TODO: Implement FFmpeg decode loop:
  //   while (state_ == Playing || state_ == Paused) {
  //     av_read_frame -> avcodec_send_packet -> avcodec_receive_frame
  //     -> sws_scale -> frame_callback_(data, w, h, stride)
  //   }
}

}  // namespace ai_weather_wallpaper
