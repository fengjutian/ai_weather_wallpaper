import 'dart:io';

import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:wallpaper_core/wallpaper_core.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:file_selector/file_selector.dart';

/// The main home screen — pick a local image to set as wallpaper.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WallpaperEngine _engine = WallpaperEngine.instance;
  String? _currentWallpaper;
  bool _wallpaperActive = false;

  // Audio
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _engine.stateNotifier.addListener(_onEngineStateChanged);
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _engine.stateNotifier.removeListener(_onEngineStateChanged);
    super.dispose();
  }

  void _onEngineStateChanged() {
    if (!mounted) return;
    setState(() {
      _wallpaperActive = _engine.state == WallpaperState.playing;
    });
  }

  // ─── Wallpaper ──────────────────────────────────────────────────────────

  Future<void> _pickAndSetWallpaper() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['png', 'jpg', 'jpeg', 'bmp', 'webp', 'gif'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return; // user cancelled

      final path = file.path;
      await _engine.start(path);
      setState(() => _currentWallpaper = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置壁纸失败: $e')),
        );
      }
    }
  }

  Future<void> _stopWallpaper() async {
    _engine.stop();
    setState(() {
      _currentWallpaper = null;
      _wallpaperActive = false;
    });
  }

  // ─── Audio ──────────────────────────────────────────────────────────────

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

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasWallpaper = _currentWallpaper != null;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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

                  // Main area
                  Expanded(
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasWallpaper
                                    ? Icons.wallpaper
                                    : Icons.add_photo_alternate,
                                size: 64,
                                color: hasWallpaper
                                    ? AppTheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hasWallpaper
                                    ? 'Wallpaper Active'
                                    : 'No Wallpaper Selected',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              if (hasWallpaper) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _currentWallpaper!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB0B0C0),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GlassButton(
                                    label: '📁 Browse...',
                                    onPressed: _pickAndSetWallpaper,
                                  ),
                                  if (hasWallpaper) ...[
                                    const SizedBox(width: 12),
                                    GlassButton(
                                      label: '⏹ Stop',
                                      onPressed: _stopWallpaper,
                                      color: AppTheme.error,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
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
