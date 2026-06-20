// tray_manager.cpp — System tray implementation

#include "tray_manager.h"
#include <shellapi.h>
#include <iostream>

namespace ai_weather_wallpaper {

// Unique identifier for our tray icon
constexpr UINT kTrayIconID = 1001;
constexpr UINT kTrayCallbackMsg = WM_APP + 1;

TrayManager::TrayManager()
    : hwnd_(nullptr),
      icon_(nullptr),
      created_(false),
      taskbar_created_msg_(RegisterWindowMessageW(L"TaskbarCreated")) {}

TrayManager::~TrayManager() {
  Remove();
}

bool TrayManager::Create(HWND hwnd, int icon_resource_id) {
  hwnd_ = hwnd;
  icon_ = LoadIconW(GetModuleHandleW(nullptr),
                    MAKEINTRESOURCEW(icon_resource_id));

  if (!icon_) {
    // Fallback: use system icon
    icon_ = LoadIconW(nullptr, IDI_APPLICATION);
  }

  NOTIFYICONDATAW nid = {};
  nid.cbSize = sizeof(NOTIFYICONDATAW);
  nid.hWnd = hwnd_;
  nid.uID = kTrayIconID;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid.uCallbackMessage = kTrayCallbackMsg;
  nid.hIcon = icon_;
  wcscpy_s(nid.szTip, L"AI Weather Wallpaper");

  created_ = Shell_NotifyIconW(NIM_ADD, &nid);
  if (!created_) {
    std::cerr << "[TrayManager] Failed to create tray icon." << std::endl;
    return false;
  }

  std::cout << "[TrayManager] Tray icon created." << std::endl;
  return true;
}

void TrayManager::Remove() {
  if (!created_) return;

  NOTIFYICONDATAW nid = {};
  nid.cbSize = sizeof(NOTIFYICONDATAW);
  nid.hWnd = hwnd_;
  nid.uID = kTrayIconID;

  Shell_NotifyIconW(NIM_DELETE, &nid);
  created_ = false;
  std::cout << "[TrayManager] Tray icon removed." << std::endl;
}

void TrayManager::ShowNotification(const std::wstring& title,
                                    const std::wstring& message) {
  if (!created_) return;

  NOTIFYICONDATAW nid = {};
  nid.cbSize = sizeof(NOTIFYICONDATAW);
  nid.hWnd = hwnd_;
  nid.uID = kTrayIconID;
  nid.uFlags = NIF_INFO;
  nid.dwInfoFlags = NIIF_INFO;
  wcscpy_s(nid.szInfoTitle, title.c_str());
  wcscpy_s(nid.szInfo, message.c_str());

  Shell_NotifyIconW(NIM_MODIFY, &nid);
}

void TrayManager::SetOnOpen(TrayCallback cb) { on_open_ = std::move(cb); }
void TrayManager::SetOnPause(TrayCallback cb) { on_pause_ = std::move(cb); }
void TrayManager::SetOnSwitchWallpaper(TrayCallback cb) { on_switch_wallpaper_ = std::move(cb); }
void TrayManager::SetOnSettings(TrayCallback cb) { on_settings_ = std::move(cb); }
void TrayManager::SetOnQuit(TrayCallback cb) { on_quit_ = std::move(cb); }

bool TrayManager::HandleMessage(UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == taskbar_created_msg_) {
    // Taskbar was recreated (e.g., explorer crash), re-add icon
    NOTIFYICONDATAW nid = {};
    nid.cbSize = sizeof(NOTIFYICONDATAW);
    nid.hWnd = hwnd_;
    nid.uID = kTrayIconID;
    nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    nid.uCallbackMessage = kTrayCallbackMsg;
    nid.hIcon = icon_;
    wcscpy_s(nid.szTip, L"AI Weather Wallpaper");
    Shell_NotifyIconW(NIM_ADD, &nid);
    return true;
  }

  if (message != kTrayCallbackMsg) return false;

  switch (LOWORD(lparam)) {
    case WM_LBUTTONDBLCLK:
      if (on_open_) on_open_();
      break;

    case WM_RBUTTONUP:
      ShowContextMenu();
      break;
  }

  return true;
}

void TrayManager::ShowContextMenu() {
  HMENU menu = CreatePopupMenu();

  AppendMenuW(menu, MF_STRING, 1, L"Open");
  AppendMenuW(menu, MF_STRING, 2, L"Pause Wallpaper");
  AppendMenuW(menu, MF_STRING, 3, L"Switch Wallpaper");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, 4, L"Settings");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, 5, L"Quit");

  // Show menu at cursor position
  POINT pt;
  GetCursorPos(&pt);
  SetForegroundWindow(hwnd_);

  int cmd = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_NONOTIFY,
                           pt.x, pt.y, 0, hwnd_, nullptr);

  switch (cmd) {
    case 1: if (on_open_) on_open_(); break;
    case 2: if (on_pause_) on_pause_(); break;
    case 3: if (on_switch_wallpaper_) on_switch_wallpaper_(); break;
    case 4: if (on_settings_) on_settings_(); break;
    case 5: if (on_quit_) on_quit_(); break;
  }

  DestroyMenu(menu);
}

}  // namespace ai_weather_wallpaper
