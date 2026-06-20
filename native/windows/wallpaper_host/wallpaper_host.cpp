// wallpaper_host.cpp — Wallpaper host window management implementation

#include "wallpaper_host.h"
#include <iostream>

namespace ai_weather_wallpaper {

// Monitor enumeration callback
BOOL CALLBACK MonitorEnumProc(HMONITOR monitor, HDC, LPRECT rect, LPARAM lparam) {
    auto* instances = reinterpret_cast<std::vector<WallpaperInstance>*>(lparam);

    MONITORINFOEXW mi;
    mi.cbSize = sizeof(mi);
    if (GetMonitorInfoW(monitor, &mi)) {
        WallpaperInstance inst;
        inst.monitor_rect = *rect;
        inst.monitor_name = mi.szDevice;
        inst.window_handle = nullptr;
        inst.is_active = false;
        instances->push_back(inst);
    }
    return TRUE;
}

WallpaperHost::WallpaperHost() : initialized_(false) {}

WallpaperHost::~WallpaperHost() {
    DestroyAll();
}

bool WallpaperHost::Initialize() {
    EnumerateMonitors();
    initialized_ = true;
    std::cout << "[WallpaperHost] Initialized with "
              << instances_.size() << " monitor(s)." << std::endl;
    return true;
}

int WallpaperHost::CreateWallpaperWindows() {
    int count = 0;
    for (auto& inst : instances_) {
        std::wstring title = L"AIWeatherWallpaper_" +
                             inst.monitor_name.substr(0, inst.monitor_name.find(L'\\'));
        inst.window_handle = CreateWallpaperWindow(inst.monitor_rect, title);
        if (inst.window_handle) {
            inst.is_active = true;
            count++;
        }
    }
    return count;
}

bool WallpaperHost::SetWallpaper(int monitor_index,
                                  const std::wstring& wallpaper_path) {
    if (monitor_index < 0 || monitor_index >= static_cast<int>(instances_.size())) {
        return false;
    }
    // TODO: Load and display the wallpaper on the target monitor window
    return true;
}

void WallpaperHost::PauseAll() {
    for (auto& inst : instances_) {
        if (inst.window_handle) {
            // TODO: Send pause message to the wallpaper renderer
        }
    }
}

void WallpaperHost::ResumeAll() {
    for (auto& inst : instances_) {
        if (inst.window_handle) {
            // TODO: Send resume message to the wallpaper renderer
        }
    }
}

void WallpaperHost::DestroyAll() {
    for (auto& inst : instances_) {
        if (inst.window_handle) {
            DestroyWindow(inst.window_handle);
            inst.window_handle = nullptr;
        }
        inst.is_active = false;
    }
    instances_.clear();
}

void WallpaperHost::EnumerateMonitors() {
    instances_.clear();
    EnumDisplayMonitors(nullptr, nullptr, MonitorEnumProc,
                        reinterpret_cast<LPARAM>(&instances_));
}

HWND WallpaperHost::CreateWallpaperWindow(const RECT& rect,
                                           const std::wstring& title) {
    // Register window class if not yet registered
    static const wchar_t kClassName[] = L"AIWeatherWallpaperClass";
    static bool class_registered = false;

    if (!class_registered) {
        WNDCLASSW wc = {};
        wc.lpfnWndProc = DefWindowProcW;
        wc.hInstance = GetModuleHandleW(nullptr);
        wc.lpszClassName = kClassName;
        wc.hbrBackground = CreateSolidBrush(RGB(0, 0, 0));
        RegisterClassW(&wc);
        class_registered = true;
    }

    HWND hwnd = CreateWindowExW(
        WS_EX_NOACTIVATE | WS_EX_LAYERED | WS_EX_TRANSPARENT,
        kClassName,
        title.c_str(),
        WS_CHILD | WS_VISIBLE,
        rect.left, rect.top,
        rect.right - rect.left,
        rect.bottom - rect.top,
        nullptr,  // Parent set later by WorkerW embedding
        nullptr,
        GetModuleHandleW(nullptr),
        nullptr);

    return hwnd;
}

}  // namespace ai_weather_wallpaper
