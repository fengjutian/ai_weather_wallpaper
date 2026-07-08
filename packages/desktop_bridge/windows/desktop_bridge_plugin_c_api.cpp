#include "include/desktop_bridge/desktop_bridge_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "desktop_bridge_plugin.h"

void DesktopBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  desktop_bridge::DesktopBridgePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
