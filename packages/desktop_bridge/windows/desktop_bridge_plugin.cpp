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

// --- WorkerW embedding helpers ---

static void LogWindowInfo(const wchar_t* label, HWND hwnd) {
  wchar_t className[256] = {0};
  wchar_t title[256] = {0};
  GetClassNameW(hwnd, className, 256);
  GetWindowTextW(hwnd, title, 256);
  RECT r;
  GetWindowRect(hwnd, &r);
  wchar_t buf[512];
  swprintf_s(buf, L"[desktop_bridge] %s: HWND=0x%p class='%s' title='%s' rect=(%d,%d,%d,%d)\n",
             label, hwnd, className, title, r.left, r.top, r.right, r.bottom);
  OutputDebugStringW(buf);
}

HWND FindWorkerW() {
  HWND progman = FindWindowW(L"Progman", nullptr);
  if (!progman) {
    LOG("FindWorkerW: Progman not found!");
    return nullptr;
  }
  LogWindowInfo(L"Progman", progman);

  // Count WorkerW windows before sending 0x052C
  int countBefore = 0;
  EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
    int* cnt = reinterpret_cast<int*>(lParam);
    wchar_t cn[256];
    if (GetClassNameW(hwnd, cn, 256) && wcscmp(cn, L"WorkerW") == 0) (*cnt)++;
    return TRUE;
  }, reinterpret_cast<LPARAM>(&countBefore));

  wchar_t buf[128];
  swprintf_s(buf, L"[desktop_bridge] WorkerW count before 0x052C: %d\n", countBefore);
  OutputDebugStringW(buf);

  // Send 0x052C to spawn WorkerW
  DWORD_PTR msgResult = 0;
  LRESULT sent = SendMessageTimeoutW(progman, 0x052C, 0, 0, SMTO_NORMAL, 100, &msgResult);
  swprintf_s(buf, L"[desktop_bridge] SendMessageTimeoutW(0x052C) returned %d, result=%d\n",
             (int)sent, (int)msgResult);
  OutputDebugStringW(buf);

  // Count WorkerW windows after sending
  int countAfter = 0;
  EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
    int* cnt = reinterpret_cast<int*>(lParam);
    wchar_t cn[256];
    if (GetClassNameW(hwnd, cn, 256) && wcscmp(cn, L"WorkerW") == 0) (*cnt)++;
    return TRUE;
  }, reinterpret_cast<LPARAM>(&countAfter));
  swprintf_s(buf, L"[desktop_bridge] WorkerW count after 0x052C: %d\n", countAfter);
  OutputDebugStringW(buf);

  HWND workerW = nullptr;

  // Strategy 1: WorkerW with SHELLDLL_DefView child
  EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
    HWND* out = reinterpret_cast<HWND*>(lParam);
    wchar_t className[256];
    if (GetClassNameW(hwnd, className, 256) == 0) return TRUE;
    if (wcscmp(className, L"WorkerW") != 0) return TRUE;
    HWND defView = FindWindowExW(hwnd, nullptr, L"SHELLDLL_DefView", nullptr);
    if (defView) {
      LogWindowInfo(L"Found WorkerW+DefView", hwnd);
      *out = hwnd;
      return FALSE;
    }
    return TRUE;
  }, reinterpret_cast<LPARAM>(&workerW));

  if (workerW) {
    LOG("FindWorkerW: strategy 1 succeeded (WorkerW+DefView)");
    return workerW;
  }

  LOG("FindWorkerW: strategy 1 failed, trying strategy 2 (any WorkerW)");

  // Strategy 2: Any WorkerW (even without DefView)
  EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
    HWND* out = reinterpret_cast<HWND*>(lParam);
    wchar_t className[256];
    if (GetClassNameW(hwnd, className, 256) == 0) return TRUE;
    if (wcscmp(className, L"WorkerW") == 0) {
      LogWindowInfo(L"Found WorkerW (no DefView)", hwnd);
      *out = hwnd;
      return FALSE;
    }
    return TRUE;
  }, reinterpret_cast<LPARAM>(&workerW));

  if (workerW) {
    LOG("FindWorkerW: strategy 2 succeeded (any WorkerW)");
  } else {
    LOG("FindWorkerW: ALL STRATEGIES FAILED!");
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

    LogWindowInfo(L"WorkerW", workerW);
    HWND defView = FindWindowExW(workerW, nullptr, L"SHELLDLL_DefView", nullptr);
    if (defView) LogWindowInfo(L"SHELLDLL_DefView", defView);

    // Strategy: SetParent WITHOUT changing GWL_STYLE
    // (WS_CHILD would break WebView2 rendering)
    SetParent(flutter_window_, workerW);

    RECT desktopRect;
    if (!GetClientRect(workerW, &desktopRect)) {
      desktopRect.left = 0; desktopRect.top = 0;
      desktopRect.right = GetSystemMetrics(SM_CXSCREEN);
      desktopRect.bottom = GetSystemMetrics(SM_CYSCREEN);
    }

    // Place BETWEEN background and icons: get window just before DefView
    HWND insertAfter;
    if (defView) {
      insertAfter = GetWindow(defView, GW_HWNDPREV);
      if (!insertAfter) insertAfter = HWND_BOTTOM;
    } else {
      insertAfter = HWND_BOTTOM;
    }
    SetWindowPos(flutter_window_, insertAfter,
                 0, 0, desktopRect.right, desktopRect.bottom,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);

    wchar_t buf[128];
    swprintf_s(buf, L"[desktop_bridge] Parented to WorkerW, pos: %dx%d\n",
               desktopRect.right, desktopRect.bottom);
    OutputDebugStringW(buf);

    LOG("embedAsWallpaper SUCCESS");
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
    SetWindowPos(flutter_window_, HWND_TOPMOST,
                 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);
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
