import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:weather_core/weather_core.dart';
import 'package:wallpaper_core/wallpaper_core.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:local_storage/local_storage.dart';

/// The main home screen — displays weather, wallpaper controls, and audio.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherRepository _weatherRepo = WeatherRepository(
    primaryProvider: OpenWeatherProvider(apiKey: _apiKey()),
  );
  final CacheManager<String> _cache =
      CacheManager<String>(defaultTtl: const Duration(minutes: 30));

  WeatherModel? _weather;
  bool _loading = true;
  String? _error;
  String _city = 'Beijing';

  // Wallpaper
  final WallpaperEngine _engine = WallpaperEngine.instance;
  bool _wallpaperPlaying = false;

  // Audio
  AudioPlayer? _audioPlayer;

  static String _apiKey() {
    const key = String.fromEnvironment('OPENWEATHER_API_KEY');
    return key.isEmpty ? 'DEMO_KEY' : key;
  }

  @override
  void initState() {
    super.initState();
    _loadCachedCity();
    _listenEngine();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _listenEngine() {
    _engine.stateNotifier.addListener(() {
      if (!mounted) return;
      setState(() {
        _wallpaperPlaying = _engine.state == WallpaperState.playing;
      });
    });
  }

  Future<void> _loadCachedCity() async {
    final hive = HiveHelper.instance;
    final cityName = hive.get('session', 'city', defaultValue: 'Beijing');
    _city = cityName;
    await _fetchWeather(cityName);
  }

  Future<void> _fetchWeather(String cityName) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final city = City(name: cityName, latitude: 39.9, longitude: 116.4);
      final weather = await _weatherRepo.getCurrentWeather(city);
      if (mounted) {
        setState(() {
          _weather = weather;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _playDefaultWallpaper() async {
    try {
      const path = 'assets/wallpapers/default_weather.png';
      await _engine.start(path);
      setState(() => {});
    } catch (e) {
      debugPrint('Home: wallpaper start failed: $e');
    }
  }

  Future<void> _stopWallpaper() async {
    _engine.stop();
    setState(() {
      _wallpaperPlaying = false;
    });
  }

  Future<void> _toggleRainSound() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    } else {
      _audioPlayer = AudioPlayer(config: Rain.config);
      await _audioPlayer!.play();
    }
    setState(() {});
  }

  IconData _weatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.foggy;
      default:
        return Icons.cloud_queue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final condition = _weather?.weather ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // --- Background gradient ---
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D0D1A),
                    Color(0xFF1A1A3E),
                    Color(0xFF0A0A20),
                  ],
                ),
              ),
            ),
          ),

          // --- Content ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI Weather Wallpaper',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          GlassButton(
                            label: _audioPlayer != null ? '🔊 Rain' : '🔇 Rain',
                            onPressed: _toggleRainSound,
                          ),
                          const SizedBox(width: 8),
                          GlassButton(
                            label: '⚙',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Weather Card ---
                  if (_loading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppTheme.error),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: AppTheme.error)),
                            const SizedBox(height: 12),
                            GlassButton(
                              label: 'Retry',
                              onPressed: _loadCachedCity,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            WeatherCard(
                              city: _city,
                              temperature:
                                  '${_weather!.temp.toStringAsFixed(0)}°C',
                              condition: _weatherIcon(condition),
                              conditionLabel: condition,
                              humidity: '${_weather!.humidity}%',
                              windSpeed: _weather!.windSpeed != null
                                  ? '${_weather!.windSpeed!.toStringAsFixed(1)} m/s'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // --- Wallpaper controls ---
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Wallpaper',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GlassButton(
                                            label: _wallpaperPlaying
                                                ? '⏸ Stop'
                                                : '▶ Play',
                                            onPressed: _wallpaperPlaying
                                                ? _stopWallpaper
                                                : _playDefaultWallpaper,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GlassButton(
                                          label: '🖼 Pick',
                                          onPressed: () => Navigator.pushNamed(
                                              context, '/wallpaper-picker'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
