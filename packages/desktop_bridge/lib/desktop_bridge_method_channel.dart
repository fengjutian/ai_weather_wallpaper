import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_bridge_platform_interface.dart';

/// An implementation of [DesktopBridgePlatform] that uses method channels.
class MethodChannelDesktopBridge extends DesktopBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('desktop_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
