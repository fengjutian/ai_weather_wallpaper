/// Wallpaper Core — a Flutter package for rendering desktop wallpapers.
///
/// This library provides a unified engine that can display
/// static images, video, Lottie animations, and GLSL shaders
/// as the desktop wallpaper. Use [WallpaperEngine] as the
/// entry point for loading and controlling wallpapers.
library wallpaper_core;

export 'engine/wallpaper_engine.dart';
export 'player/media_player.dart';
export 'renderer/image_renderer.dart';
export 'renderer/lottie_renderer.dart';
export 'renderer/shader_renderer.dart';
export 'renderer/video_renderer.dart';
export 'renderer/webview_renderer.dart';
export 'scene/scene_manager.dart';
