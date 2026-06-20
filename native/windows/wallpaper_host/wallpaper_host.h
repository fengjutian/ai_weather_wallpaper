// wallpaper_host.h — Wallpaper host window management
//
// Manages the lifecycle of wallpaper windows, including creation,
// positioning, multi-monitor support, and cleanup.

#pragma once

#include <windows.h>
#include <string>
#include <vector>

namespace ai_weather_wallpaper {

/// Represents a single wallpaper instance on one monitor.
struct WallpaperInstance {
  HWND window_handle;
  std::wstring monitor_name;
  RECT monitor_rect;
  bool is_active;
};

/// Manages wallpaper window lifecycle across multiple monitors.
class WallpaperHost {
 public:
  WallpaperHost();
  ~WallpaperHost();

  /// Initialise the wallpaper host system.
  bool Initialize();

  /// Create a wallpaper window for each detected monitor.
  /// Returns the number of windows created.
  int CreateWallpaperWindows();

  /// Set the wallpaper for a specific monitor (by index).
  bool SetWallpaper(int monitor_index, const std::wstring& wallpaper_path);

  /// Pause / resume all wallpaper animations.
  void PauseAll();
  void ResumeAll();

  /// Clean up all wallpaper windows.
  void DestroyAll();

  /// Returns the list of wallpaper instances.
  const std::vector<WallpaperInstance>& instances() const { return instances_; }

  /// Returns the number of detected monitors.
  int monitor_count() const { return static_cast<int>(instances_.size()); }

 private:
  std::vector<WallpaperInstance> instances_;
  bool initialized_;

  /// Enumerate all monitors and populate instances_.
  void EnumerateMonitors();

  /// Create a single wallpaper window for the given monitor rect.
  HWND CreateWallpaperWindow(const RECT& rect, const std::wstring& title);
};

}  // namespace ai_weather_wallpaper
