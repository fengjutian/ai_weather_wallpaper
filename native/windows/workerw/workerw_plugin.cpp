// workerw_plugin.cpp — Flutter plugin glue for WorkerW management
//
// Implements the Flutter platform channel interface that allows
// Dart code to invoke WorkerW operations (initialize, embed, restore).

#include "workerw.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>

namespace ai_weather_wallpaper {

class WorkerWPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  WorkerWPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~WorkerWPlugin();

 private:
  // Handle method calls from Dart
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<WorkerWManager> manager_;
  flutter::PluginRegistrarWindows* registrar_;
};

void WorkerWPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<WorkerWPlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}

WorkerWPlugin::WorkerWPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  manager_ = std::make_unique<WorkerWManager>();

  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "ai_weather_wallpaper/workerw",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        HandleMethodCall(call, std::move(result));
      });
}

WorkerWPlugin::~WorkerWPlugin() {}

void WorkerWPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();

  if (method == "initialize") {
    bool success = manager_->Initialize();
    result->Success(flutter::EncodableValue(success));
  } else if (method == "embedWindow") {
    // TODO: Get window handle from arguments
    HWND hwnd = nullptr;
    bool success = manager_->EmbedWindow(hwnd);
    result->Success(flutter::EncodableValue(success));
  } else if (method == "restore") {
    manager_->Restore();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace ai_weather_wallpaper
