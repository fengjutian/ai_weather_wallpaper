// tray_manager.h — System tray icon and context menu management
//
// Manages the Windows system tray icon for the wallpaper application,
// providing quick access to pause, switch wallpapers, settings, and quit.

#pragma once

#include <windows.h>
#include <functional>
#include <string>

namespace ai_weather_wallpaper {

/// Callback types for tray menu actions.
using TrayCallback = std::function<void()>;

/// Manages the system tray icon and its context menu.
class TrayManager {
 public:
  TrayManager();
  ~TrayManager();

  /// Create the tray icon and register it with the system.
  /// @param hwnd The main application window handle.
  /// @param icon_resource_id Resource ID of the tray icon.
  bool Create(HWND hwnd, int icon_resource_id);

  /// Remove the tray icon from the system.
  void Remove();

  /// Show a balloon notification.
  /// @param title Notification title.
  /// @param message Notification body text.
  void ShowNotification(const std::wstring& title,
                        const std::wstring& message);

  /// Set callback for the "Show/Open" menu item.
  void SetOnOpen(TrayCallback callback);

  /// Set callback for the "Pause Wallpaper" menu item.
  void SetOnPause(TrayCallback callback);

  /// Set callback for the "Switch Wallpaper" menu item.
  void SetOnSwitchWallpaper(TrayCallback callback);

  /// Set callback for the "Settings" menu item.
  void SetOnSettings(TrayCallback callback);

  /// Set callback for "Quit".
  void SetOnQuit(TrayCallback callback);

  /// Handle a window message (should be called from the main
  /// window procedure for WM_APP messages).
  bool HandleMessage(UINT message, WPARAM wparam, LPARAM lparam);

 private:
  HWND hwnd_;
  HICON icon_;
  bool created_;
  UINT taskbar_created_msg_;

  TrayCallback on_open_;
  TrayCallback on_pause_;
  TrayCallback on_switch_wallpaper_;
  TrayCallback on_settings_;
  TrayCallback on_quit_;

  /// Show the context menu at the cursor position.
  void ShowContextMenu();

  /// Internal window procedure for tray notifications.
  static LRESULT CALLBACK TrayWndProc(HWND hwnd, UINT msg,
                                       WPARAM wparam, LPARAM lparam);
};

}  // namespace ai_weather_wallpaper
