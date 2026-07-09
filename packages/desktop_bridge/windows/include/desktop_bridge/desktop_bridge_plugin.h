#ifndef FLUTTER_PLUGIN_DESKTOP_BRIDGE_PLUGIN_H_
#define FLUTTER_PLUGIN_DESKTOP_BRIDGE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace desktop_bridge {

class DesktopBridgePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DesktopBridgePlugin();

  virtual ~DesktopBridgePlugin();

  // Disallow copy and assign.
  DesktopBridgePlugin(const DesktopBridgePlugin&) = delete;
  DesktopBridgePlugin& operator=(const DesktopBridgePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace desktop_bridge

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

FLUTTER_PLUGIN_EXPORT void DesktopBridgePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#endif  // FLUTTER_PLUGIN_DESKTOP_BRIDGE_PLUGIN_H_
