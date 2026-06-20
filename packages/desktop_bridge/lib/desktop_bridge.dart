/// Desktop Bridge — Platform channel & FFI bridge for wallpaper operations.
///
/// Provides a unified Dart API for setting the Flutter window as a desktop
/// wallpaper, controlling its visibility (pause / resume), and quitting the
/// application.  On Windows the heavy lifting is done via FFI calls into
/// `user32.dll`; other platforms fall back to their native plugin channels.
///
/// ## Usage
///
/// ```dart
/// import 'package:desktop_bridge/desktop_bridge.dart';
///
/// final bridge = MethodChannelHandler();
/// await bridge.setWallpaper();
/// ```
library desktop_bridge;

export 'channels/method_channel_handler.dart' show MethodChannelHandler, ChannelNames;
export 'ffi/win32_bindings.dart' show Win32Bindings;
