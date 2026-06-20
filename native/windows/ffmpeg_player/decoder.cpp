// decoder.cpp — FFmpeg video decoding utilities
//
// Low-level decoding helpers that wrap FFmpeg's libavcodec and
// libavformat for video frame extraction.

#include "player.h"

namespace ai_weather_wallpaper {

// TODO: Implement when FFmpeg is linked into the project.
//
// Key functions to implement:
//
// AVFormatContext* OpenFormatContext(const wchar_t* path) {
//     AVFormatContext* ctx = nullptr;
//     avformat_open_input(&ctx, path, nullptr, nullptr);
//     avformat_find_stream_info(ctx, nullptr);
//     return ctx;
// }
//
// int FindVideoStream(AVFormatContext* ctx) {
//     for (int i = 0; i < ctx->nb_streams; i++) {
//         if (ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO)
//             return i;
//     }
//     return -1;
// }
//
// AVCodecContext* OpenDecoder(AVCodecParameters* params) {
//     const AVCodec* codec = avcodec_find_decoder(params->codec_id);
//     AVCodecContext* ctx = avcodec_alloc_context3(codec);
//     avcodec_parameters_to_context(ctx, params);
//     avcodec_open2(ctx, codec, nullptr);
//     return ctx;
// }

}  // namespace ai_weather_wallpaper
