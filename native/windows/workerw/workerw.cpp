// workerw.cpp — WorkerW window management implementation
//
// References:
//   - https://devblogs.microsoft.com/oldnewthing/
//   - Windows Shell documentation

#include "workerw.h"
#include <iostream>

namespace ai_weather_wallpaper {

// Forward declaration for EnumWindows callback
BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lparam);

WorkerWManager::WorkerWManager()
    : progman_handle_(nullptr),
      workerw_handle_(nullptr),
      initialized_(false) {}

WorkerWManager::~WorkerWManager() {
  if (initialized_) {
    Restore();
  }
}

bool WorkerWManager::Initialize() {
  // Find the Progman window (the desktop shell window)
  progman_handle_ = FindWindowW(L"Progman", nullptr);
  if (!progman_handle_) {
    std::cerr << "[WorkerW] Failed to find Progman window." << std::endl;
    return false;
  }

  // Send a message to Progman to spawn a WorkerW if needed.
  // 0x052C is the undocumented message that creates the WorkerW.
  SendMessageTimeoutW(progman_handle_, 0x052C, 0, 0, SMTO_NORMAL, 1000, nullptr);

  // Find the WorkerW that contains the SHELLDLL_DefView
  if (!FindWorkerW()) {
    std::cerr << "[WorkerW] Failed to find WorkerW window." << std::endl;
    return false;
  }

  initialized_ = true;
  std::cout << "[WorkerW] Initialization successful." << std::endl;
  return true;
}

bool WorkerWManager::EmbedWindow(HWND child_window_handle) {
  if (!initialized_ || !workerw_handle_) {
    std::cerr << "[WorkerW] Not initialized — cannot embed window." << std::endl;
    return false;
  }

  // Set the Flutter window as a child of the WorkerW
  SetParent(child_window_handle, workerw_handle_);

  // Make the window cover the entire desktop
  SetWindowLongPtrW(child_window_handle, GWL_STYLE,
                    WS_CHILD | WS_VISIBLE);

  // Position the window to fill the desktop area
  RECT desktop_rect;
  GetClientRect(workerw_handle_, &desktop_rect);
  SetWindowPos(child_window_handle, HWND_TOP,
               0, 0,
               desktop_rect.right, desktop_rect.bottom,
               SWP_NOACTIVATE | SWP_SHOWWINDOW);

  return true;
}

void WorkerWManager::Restore() {
  // TODO: Remove embedded window and restore original desktop state
  initialized_ = false;
}

BOOL WorkerWManager::FindWorkerW() {
  // Enumerate all top-level windows and find the WorkerW
  // that has a SHELLDLL_DefView as its first child.
  EnumWindows([](HWND hwnd, LPARAM lparam) -> BOOL {
    auto* self = reinterpret_cast<WorkerWManager*>(lparam);

    // Find windows of class "WorkerW"
    wchar_t class_name[256];
    GetClassNameW(hwnd, class_name, 256);
    if (wcscmp(class_name, L"WorkerW") != 0) {
      return TRUE;  // Continue enumeration
    }

    // Check if this WorkerW has a SHELLDLL_DefView child
    HWND def_view = FindWindowExW(hwnd, nullptr, L"SHELLDLL_DefView", nullptr);
    if (def_view) {
      self->workerw_handle_ = hwnd;
      return FALSE;  // Found it — stop enumeration
    }

    return TRUE;  // Continue
  }, reinterpret_cast<LPARAM>(this));

  return workerw_handle_ != nullptr;
}

}  // namespace ai_weather_wallpaper
