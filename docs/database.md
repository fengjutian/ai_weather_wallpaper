# Database Schema — AI Weather Wallpaper

## Overview

The local storage layer uses SQLite (via sqflite) for structured data and
Hive for lightweight key-value storage and caching.

## SQLite Tables

### `weather_cache`

Cached weather data to reduce API calls.

```sql
CREATE TABLE weather_cache (
    city_id     TEXT PRIMARY KEY,
    weather     TEXT NOT NULL,
    temp        REAL NOT NULL,
    humidity    INTEGER NOT NULL,
    forecast    TEXT,           -- JSON-encoded forecast list
    fetched_at  TEXT NOT NULL,  -- ISO 8601 timestamp
    expires_at  TEXT NOT NULL   -- Cache expiry timestamp
);
```

**Index**: `CREATE INDEX idx_weather_expires ON weather_cache(expires_at);`

### `scene_cache`

Cached wallpaper scene data and metadata.

```sql
CREATE TABLE scene_cache (
    scene_id    TEXT PRIMARY KEY,
    scene_type  TEXT NOT NULL,  -- 'image', 'video', 'lottie', 'shader'
    source_url  TEXT,
    local_path  TEXT,
    thumbnail   BLOB,
    metadata    TEXT,           -- JSON-encoded scene parameters
    created_at  TEXT NOT NULL,
    expires_at  TEXT
);
```

### `ai_images`

Generated AI wallpaper images.

```sql
CREATE TABLE ai_images (
    image_id    TEXT PRIMARY KEY,
    prompt      TEXT NOT NULL,
    model       TEXT NOT NULL,  -- 'openai', 'sd', 'flux'
    source_url  TEXT,
    local_path  TEXT,
    width       INTEGER,
    height      INTEGER,
    seed        INTEGER,
    metadata    TEXT,           -- JSON-encoded generation parameters
    created_at  TEXT NOT NULL,
    is_favorite INTEGER DEFAULT 0
);
```

**Index**: `CREATE INDEX idx_ai_images_fav ON ai_images(is_favorite);`

### `settings`

Application settings key-value store.

```sql
CREATE TABLE settings (
    key         TEXT PRIMARY KEY,
    value       TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);
```

### `favorites`

User's favourite wallpapers.

```sql
CREATE TABLE favorites (
    favorite_id  TEXT PRIMARY KEY,
    scene_id     TEXT NOT NULL,
    scene_type   TEXT NOT NULL,
    added_at     TEXT NOT NULL,
    sort_order   INTEGER DEFAULT 0
);
```

**Index**: `CREATE INDEX idx_favorites_sort ON favorites(sort_order);`

## Hive Storage

| Box Name        | Purpose                        |
|-----------------|--------------------------------|
| `settings`      | Quick-read app preferences     |
| `weather_cache` | Lightweight weather snapshots  |
| `session`       | Current session state          |

## Cache Strategy

| Data          | TTL (Time-To-Live) | Eviction Policy    |
|---------------|--------------------|--------------------|
| Current Weather | 30 minutes        | Time-based expiry  |
| Forecast      | 2 hours            | Time-based expiry  |
| AI Images     | 7 days             | LRU + time-based   |
| Scenes        | 24 hours           | Time-based expiry  |
