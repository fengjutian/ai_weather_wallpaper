import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'desktop_bridge_method_channel.dart';

abstract class DesktopBridgePlatform extends PlatformInterface {
  /// Constructs a DesktopBridgePlatform.
  DesktopBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopBridgePlatform _instance = MethodChannelDesktopBridge();

  /// The default instance of [DesktopBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelDesktopBridge].
  static DesktopBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DesktopBridgePlatform] when
  /// they register themselves.
  static set instance(DesktopBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
