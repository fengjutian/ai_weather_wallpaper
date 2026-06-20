// workerw.h — WorkerW window management for wallpaper embedding
//
// This module finds the Windows Progman / WorkerW window and
// embeds the Flutter wallpaper surface as a child of the desktop
// icon layer, enabling dynamic wallpapers behind desktop icons.
//
// Architecture:
//   Progman (desktop)
//     └── WorkerW (SHELLDLL_DefView)
//           └── Our wallaper window (via SetParent)

#pragma once

#include <windows.h>

namespace ai_weather_wallpaper {

/// Manages the WorkerW / Progman window for desktop wallpaper embedding.
class WorkerWManager {
 public:
  WorkerWManager();
  ~WorkerWManager();

  /// Initialise and locate the desktop worker window.
  /// Returns true on success, false on failure.
  bool Initialize();

  /// Embed an external window (our Flutter surface) into the desktop layer.
  /// @param child_window_handle Handle to the Flutter window to embed.
  /// @return true if the window was successfully embedded.
  bool EmbedWindow(HWND child_window_handle);

  /// Restore the original desktop state (remove embedded window).
  void Restore();

  /// Returns the handle to the found WorkerW window.
  HWND workerw_handle() const { return workerw_handle_; }

  /// Returns the handle to the Progman window.
  HWND progman_handle() const { return progman_handle_; }

 private:
  HWND progman_handle_;
  HWND workerw_handle_;
  bool initialized_;

  /// Find the WorkerW window that contains the SHELLDLL_DefView.
  BOOL FindWorkerW();
};

}  // namespace ai_weather_wallpaper
