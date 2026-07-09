import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:wallpaper_core/wallpaper_core.dart';

/// Browse and select wallpapers from built-in scenes.
class WallpaperPickerScreen extends StatefulWidget {
  const WallpaperPickerScreen({super.key});

  @override
  State<WallpaperPickerScreen> createState() => _WallpaperPickerScreenState();
}

class _WallpaperPickerScreenState extends State<WallpaperPickerScreen> {
  final WallpaperEngine _engine = WallpaperEngine.instance;
  String? _previewing;

  static const _scenes = <_Scene>[
    _Scene('Clear Sky', 'assets/wallpapers/clear_sky.png', Icons.wb_sunny),
    _Scene('Rainy Day', 'assets/wallpapers/rainy_day.png', Icons.water_drop),
    _Scene('Snowy Peak', 'assets/wallpapers/snowy_peak.png', Icons.ac_unit),
    _Scene('Night Stars', 'assets/wallpapers/night_stars.png',
        Icons.nightlight_round),
    _Scene('Forest Mist', 'assets/wallpapers/forest_mist.png', Icons.forest),
    _Scene('Ocean Waves', 'assets/wallpapers/ocean_waves.png', Icons.waves),
  ];

  Future<void> _preview(String path) async {
    try {
      await _engine.start(path);
      setState(() => _previewing = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview failed: $e')),
        );
      }
    }
  }

  Future<void> _apply(String path) async {
    await _preview(path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper applied!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallpaper Picker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _scenes.length,
        itemBuilder: (context, index) {
          final scene = _scenes[index];
          final isActive = _previewing == scene.path;
          return _SceneCard(
            scene: scene,
            isActive: isActive,
            onPreview: () => _preview(scene.path),
            onApply: () => _apply(scene.path),
          );
        },
      ),
    );
  }
}

class _Scene {
  final String name;
  final String path;
  final IconData icon;
  const _Scene(this.name, this.path, this.icon);
}

class _SceneCard extends StatelessWidget {
  final _Scene scene;
  final bool isActive;
  final VoidCallback onPreview;
  final VoidCallback onApply;

  const _SceneCard({
    required this.scene,
    required this.isActive,
    required this.onPreview,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPreview,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(scene.icon, size: 48, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                scene.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              GlassButton(
                label: 'Apply',
                onPressed: onApply,
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
