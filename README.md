# 🌤️ AI Weather Wallpaper

> A dynamic desktop wallpaper application for Windows — weather-responsive,
> AI-powered, and beautifully animated.

## Overview

AI Weather Wallpaper transforms your Windows desktop into a living canvas that
responds to real-time weather conditions. Rain outside? Watch raindrops on your
desktop. Snowing? Let snowflakes fall across your screen. Clear night? A starry
sky with drifting clouds.

## Project Structure

```
ai_weather_wallpaper/
├── apps/
│   ├── desktop_app/        # Flutter desktop client (main UI)
│   └── admin_panel/        # Future: cloud admin panel
│
├── packages/
│   ├── weather_core/       # Weather data models & API providers
│   ├── wallpaper_core/     # Wallpaper engine & renderers
│   ├── ai_engine/          # AI image/video generation & prompts
│   ├── audio_engine/       # Ambient audio playback & mixing
│   ├── desktop_bridge/     # Flutter ↔ Windows bridge
│   ├── local_storage/      # SQLite, Hive, cache layer
│   └── common_ui/          # Shared UI components & theming
│
├── native/windows/
│   ├── workerw/            # Desktop window embedding
│   ├── wallpaper_host/     # Multi-monitor wallpaper management
│   ├── ffmpeg_player/      # Video decoding & rendering
│   └── tray_manager/       # System tray integration
│
├── assets/                 # Resources: images, videos, shaders, sounds
├── docs/                   # Architecture & API documentation
├── scripts/                # Build & release automation
└── backend/                # Future: cloud services
```

## Quick Start

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Windows 10/11 (x64)
- Visual Studio 2022 with C++ workload

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd ai_weather_wallpaper

# Install Melos for monorepo management
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run the desktop app
cd apps/desktop_app
flutter run -d windows
```

### Build Release

```powershell
# Using the build script
.\scripts\build.ps1

# Or manually
cd apps\desktop_app
flutter build windows --release
```

## Development Phases

| Phase | Duration | Features |
|-------|----------|----------|
| 1 | 2 weeks | WorkerW embedding, Flutter UI, Weather API, wallpaper switching |
| 2 | 2 weeks | Particle effects (rain/snow), ambient audio, system tray |
| 3 | 1 month | AI image generation, seasonal themes, auto scene switching |
| 4 | Future | AI video, desktop pet, multi-monitor, membership system |

## Architecture

See [docs/architecture.md](docs/architecture.md) for the full architecture
documentation.

## License

Proprietary — All rights reserved.
