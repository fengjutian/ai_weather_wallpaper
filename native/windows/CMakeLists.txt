# Windows native modules CMake configuration
#
# This CMakeLists.txt sits under native/windows/ and builds each
# native C++ module as a static library consumed by the Flutter
# Windows plugin system.

cmake_minimum_required(VERSION 3.14)
project(ai_weather_wallpaper_native VERSION 1.0.0 LANGUAGES CXX)

# C++17 for std::filesystem, optional, clamp, etc.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---- WorkerW ----
add_library(workerw STATIC
    workerw/workerw.cpp
    workerw/workerw_plugin.cpp
)
target_include_directories(workerw PUBLIC workerw)
target_link_libraries(workerw PRIVATE flutter)

# ---- Wallpaper Host ----
add_library(wallpaper_host STATIC
    wallpaper_host/wallpaper_host.cpp
)
target_include_directories(wallpaper_host PUBLIC wallpaper_host)

# ---- FFmpeg Player ----
add_library(ffmpeg_player STATIC
    ffmpeg_player/player.cpp
    ffmpeg_player/decoder.cpp
    ffmpeg_player/renderer.cpp
)
target_include_directories(ffmpeg_player PUBLIC ffmpeg_player)

# ---- Tray Manager ----
add_library(tray_manager STATIC
    tray_manager/tray_manager.cpp
)
target_include_directories(tray_manager PUBLIC tray_manager)
target_link_libraries(tray_manager PRIVATE shell32)
