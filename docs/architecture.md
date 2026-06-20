# Architecture Document — AI Weather Wallpaper

## Overview

AI Weather Wallpaper is a dynamic desktop wallpaper application for Windows that
displays weather-responsive animated wallpapers. It follows a monorepo structure
with a Flutter desktop frontend, native C++ Windows backend, and modular Dart
packages for separation of concerns.

## High-Level Architecture

```
┌──────────────────────────────┐
│      Flutter Desktop UI       │  ← apps/desktop_app
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│      Wallpaper Engine         │  ← packages/wallpaper_core
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│      Desktop Bridge           │  ← packages/desktop_bridge
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│      Windows Native Layer     │  ← native/windows/
│  (WorkerW / WallpaperHost)    │
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│      Windows Desktop          │
└──────────────────────────────┘
```

## Module Dependency Graph

```
desktop_app
  ├── weather_core ─── local_storage
  ├── wallpaper_core ─ local_storage
  ├── ai_engine ────── local_storage
  ├── desktop_bridge
  ├── audio_engine
  └── common_ui
```

## Layer Descriptions

### Presentation Layer (apps/desktop_app)
Flutter desktop application that provides the user interface for wallpaper
selection, weather settings, system tray integration, and configuration.

### Domain Layer (packages/)
- **weather_core** — Weather data models, API providers, repository pattern
- **wallpaper_core** — Wallpaper engine, renderers (image/video/lottie/shader), scene management
- **ai_engine** — AI image/video generation, prompt templates, LLM integration
- **audio_engine** — Ambient audio playback, mixing, effects
- **local_storage** — SQLite, Hive, and cache management
- **common_ui** — Shared UI components and theming
- **desktop_bridge** — Flutter↔Windows communication (MethodChannel + FFI)

### Native Layer (native/windows/)
- **workerw** — Finds and manages WorkerW/Progman for desktop embedding
- **wallpaper_host** — Multi-monitor wallpaper window lifecycle
- **ffmpeg_player** — Video decoding and rendering via FFmpeg + D3D11
- **tray_manager** — System tray icon and context menu

## Data Flow

1. Weather data is fetched via weather_core providers
2. Weather conditions are mapped to wallpaper scenes
3. Wallpaper engine selects and renders the appropriate wallpaper
4. Desktop bridge communicates with native layer to embed the window
5. Audio engine plays matching ambient sounds

## Key Design Decisions

- **Monorepo** — Single repository for all components simplifies development
- **Modular packages** — Each domain is a self-contained Flutter package
- **Provider pattern** — Weather providers are interchangeable (OpenWeather / QWeather)
- **Repository pattern** — Abstracts data sources behind a uniform interface
- **Native via FFI** — Performance-critical operations use direct Win32 API calls
