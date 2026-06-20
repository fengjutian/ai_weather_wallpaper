# API Reference — AI Weather Wallpaper

## Weather APIs

### OpenWeatherMap (Primary)

| Endpoint | Purpose | Docs |
|----------|---------|------|
| `/data/2.5/weather` | Current weather | https://openweathermap.org/current |
| `/data/2.5/forecast` | 5-day forecast | https://openweathermap.org/forecast5 |
| `/geo/1.0/direct` | City geocoding | https://openweathermap.org/api/geocoding-api |

**Auth**: API key via query parameter `?appid=YOUR_KEY`
**Units**: `metric` for Celsius

### QWeather / 和风天气 (Fallback for China)

| Endpoint | Purpose | Docs |
|----------|---------|------|
| `/v7/weather/now` | Real-time weather | https://dev.qweather.com/docs/api/weather/weather-now/ |
| `/v7/weather/3d` | 3-day forecast | https://dev.qweather.com/docs/api/weather/weather-3d/ |

**Auth**: API key via `X-QW-Api-Key` header
**Geo**: Use QWeather city ID lookup

## AI APIs

### Image Generation

| Service | Type | Endpoint |
|---------|------|----------|
| OpenAI DALL·E 3 | Text-to-image | `POST https://api.openai.com/v1/images/generations` |
| Stable Diffusion | Text-to-image | Local / self-hosted |
| Flux | Text-to-image | via Replicate / fal.ai |

### Video Generation (Future)

| Service | Status | Endpoint |
|---------|--------|----------|
| OpenAI Sora | Future | TBD |
| Runway Gen-3 | Future | TBD |
| Pika | Future | TBD |
| Kling (快手) | Future | TBD |

### LLM Prompt Optimization

| Service | Purpose | Endpoint |
|---------|---------|----------|
| OpenAI GPT-4o | Prompt translation & enhancement | `POST https://api.openai.com/v1/chat/completions` |

## Flutter Platform Channels

### `ai_weather_wallpaper/workerw`

| Method | Parameters | Description |
|--------|------------|-------------|
| `initialize` | — | Find WorkerW and prepare embedding |
| `embedWindow` | `{handle: int}` | Embed Flutter window into desktop |
| `restore` | — | Restore original desktop state |

### `ai_weather_wallpaper/tray`

| Method | Parameters | Description |
|--------|------------|-------------|
| `showNotification` | `{title, message}` | Show balloon notification |

## Internal Package APIs

Each package exposes its public API via a barrel file (`<package>.dart`).
See package-level documentation for detailed API references.
