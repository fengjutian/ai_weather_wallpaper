import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_bridge/desktop_bridge.dart';
import 'package:desktop_bridge/desktop_bridge_platform_interface.dart';
import 'package:desktop_bridge/desktop_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopBridgePlatform
    with MockPlatformInterfaceMixin
    implements DesktopBridgePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DesktopBridgePlatform initialPlatform = DesktopBridgePlatform.instance;

  test('$MethodChannelDesktopBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopBridge>());
  });

  test('getPlatformVersion', () async {
    DesktopBridge desktopBridgePlugin = DesktopBridge();
    MockDesktopBridgePlatform fakePlatform = MockDesktopBridgePlatform();
    DesktopBridgePlatform.instance = fakePlatform;

    expect(await desktopBridgePlugin.getPlatformVersion(), '42');
  });
}
