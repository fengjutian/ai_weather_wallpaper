#include "desktop_bridge_plugin.h"

#include <windows.h>
#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>

#define LOG(msg) OutputDebugStringW(L"[desktop_bridge] " L ## msg L"\n")

namespace desktop_bridge {

static void LogWindowInfo(const wchar_t* label, HWND hwnd) {
  wchar_t className[256] = {0};
  GetClassNameW(hwnd, className, 256);
  RECT r;
  GetWindowRect(hwnd, &r);
  wchar_t buf[512];
  swprintf_s(buf, L"[desktop_bridge] %s: HWND=0x%p class='%s' rect=(%d,%d,%d,%d)\n",
             label, hwnd, className, r.left, r.top, r.right, r.bottom);
  OutputDebugStringW(buf);
}

// Find WorkerW by looking for SHELLDLL_DefView first,
// then getting its parent (the real WorkerW).
// This is the approach used by Wallpaper Engine & Lively Wallpaper.
HWND FindWorkerW() {
  HWND progman = FindWindowW(L"Progman", nullptr);
  if (!progman) {
    LOG("FindWorkerW: Progman not found");
    return nullptr;
  }
  LogWindowInfo(L"Progman", progman);

  // Spawn WorkerW via undocumented message
  SendMessageTimeoutW(progman, 0x052C, 0, 0, SMTO_NORMAL, 1000, nullptr);

  HWND workerW = nullptr;

  // Find SHELLDLL_DefView, then get its parent WorkerW
  HWND defView = FindWindowExW(nullptr, nullptr, L"SHELLDLL_DefView", nullptr);
  while (defView) {
    HWND parent = GetParent(defView);
    if (parent) {
      wchar_t cn[256];
      GetClassNameW(parent, cn, 256);
      if (wcscmp(cn, L"WorkerW") == 0) {
        LogWindowInfo(L"WorkerW (parent of DefView)", parent);
        LogWindowInfo(L"SHELLDLL_DefView", defView);
        workerW = parent;
        break;
      }
    }
    defView = FindWindowExW(nullptr, defView, L"SHELLDLL_DefView", nullptr);
  }

  if (workerW) {
    LOG("FindWorkerW: SUCCESS (found via DefView parent)");
  } else {
    LOG("FindWorkerW: FAILED -- no WorkerW parent of DefView");

    // Fallback: enumerate to find any WorkerW
    EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
      HWND* out = reinterpret_cast<HWND*>(lParam);
      wchar_t className[256];
      if (GetClassNameW(hwnd, className, 256) == 0) return TRUE;
      if (wcscmp(className, L"WorkerW") == 0) {
        LogWindowInfo(L"WorkerW (fallback enum)", hwnd);
        *out = hwnd;
        return FALSE;
      }
      return TRUE;
    }, reinterpret_cast<LPARAM>(&workerW));
  }

  return workerW;
}

// --- Plugin ---

void DesktopBridgePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "desktop_bridge",
          &flutter::StandardMethodCodec::GetInstance());
  auto plugin = std::make_unique<DesktopBridgePlugin>();
  plugin->flutter_window_ = registrar->GetView()->GetNativeWindow();
  LogWindowInfo(L"Flutter window", plugin->flutter_window_);
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->AddPlugin(std::move(plugin));
}

DesktopBridgePlugin::DesktopBridgePlugin() {}
DesktopBridgePlugin::~DesktopBridgePlugin() {}

void DesktopBridgePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  if (method_call.method_name() == "getPlatformVersion") {
    std::ostringstream vs;
    vs << "Windows ";
    if (IsWindows10OrGreater()) vs << "10+";
    else if (IsWindows8OrGreater()) vs << "8";
    else if (IsWindows7OrGreater()) vs << "7";
    result->Success(flutter::EncodableValue(vs.str()));
    return;
  }

  if (method_call.method_name() == "embedAsWallpaper") {
    LOG("embedAsWallpaper called");

    HWND workerW = FindWorkerW();
    if (!workerW) {
      LOG("embedAsWallpaper FAILED: WorkerW not found");
      result->Error("NOT_FOUND", "WorkerW not found");
      return;
    }
    if (!flutter_window_) {
      LOG("embedAsWallpaper FAILED: flutter_window_ is null");
      result->Error("NO_WINDOW", "Flutter window not available");
      return;
    }

    // Core: SetParent + WS_CHILD (as Wallpaper Engine / Lively do)
    SetParent(flutter_window_, workerW);
    {
      LONG_PTR style = GetWindowLongPtrW(flutter_window_, GWL_STYLE);
      style &= ~WS_OVERLAPPEDWINDOW;
      style |= WS_CHILD | WS_VISIBLE;
      SetWindowLongPtrW(flutter_window_, GWL_STYLE, style);
    }

    // Fill the WorkerW client area
    RECT rect;
    GetClientRect(workerW, &rect);
    SetWindowPos(flutter_window_, nullptr,
                 0, 0, rect.right, rect.bottom,
                 SWP_SHOWWINDOW);

    {
      wchar_t buf[128];
      swprintf_s(buf, L"[desktop_bridge] embedAsWallpaper SUCCESS (%dx%d)\n",
                 rect.right, rect.bottom);
      OutputDebugStringW(buf);
    }
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method_call.method_name() == "restoreWindow") {
    LOG("restoreWindow called");
    if (!flutter_window_) {
      LOG("restoreWindow FAILED: flutter_window_ is null");
      result->Error("NO_WINDOW", "Flutter window not available");
      return;
    }

    SetParent(flutter_window_, nullptr);

    LONG_PTR style = GetWindowLongPtrW(flutter_window_, GWL_STYLE);
    style &= ~WS_CHILD;
    style |= WS_OVERLAPPEDWINDOW | WS_VISIBLE;
    SetWindowLongPtrW(flutter_window_, GWL_STYLE, style);

    SetWindowPos(flutter_window_, HWND_TOPMOST,
                 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
                 SWP_SHOWWINDOW);
    SetWindowPos(flutter_window_, HWND_NOTOPMOST,
                 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);

    LOG("restoreWindow SUCCESS");
    result->Success(flutter::EncodableValue(true));
    return;
  }

  result->NotImplemented();
}

}  // namespace desktop_bridge
