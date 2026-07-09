import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';

/// About screen — shows app info, credits, and tech stack.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App icon + name
          const Center(
            child: Column(
              children: [
                Icon(Icons.cloud, size: 72, color: AppTheme.primary),
                SizedBox(height: 12),
                Text(
                  'AI Weather Wallpaper',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('v1.0.0', style: TextStyle(color: Color(0xFFB0B0C0))),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Description
          const _SectionHeader(title: 'About'),
          const Text(
            'AI Weather Wallpaper turns your Windows desktop into a living canvas '
            'that responds to real weather conditions. Rain, snow, sunshine, or '
            'starlit nights — your wallpaper adapts automatically, backed by AI '
            'generation and rich particle effects.',
            style: TextStyle(height: 1.5),
          ),
          const Divider(height: 32),

          // Tech stack
          const _SectionHeader(title: 'Powered By'),
          _TechItem('Flutter', 'Cross-platform UI framework'),
          _TechItem('OpenWeather / QWeather', 'Real-time weather data'),
          _TechItem('OpenAI DALL·E / Stable Diffusion', 'AI wallpaper generation'),
          _TechItem('Audioplayers', 'Ambient sound playback'),
          _TechItem('Hive + SQLite', 'Local persistence'),
          const Divider(height: 32),

          // Features
          const _SectionHeader(title: 'Features'),
          _FeatureItem('🌦️ Real-time weather sync'),
          _FeatureItem('🖼️ Image / Video / Lottie / Shader wallpapers'),
          _FeatureItem('🌧️ Rain, snow, cloud, aurora particle effects'),
          _FeatureItem('🔊 Ambient audio (rain, ocean, forest, white noise)'),
          _FeatureItem('🤖 AI-generated wallpaper from weather prompts'),
          _FeatureItem('🌸 24 Chinese solar terms auto-switching'),
          const Divider(height: 32),

          const Center(
            child: Text(
              'Made with ❤️ for beautiful desktops.',
              style: TextStyle(color: Color(0xFFB0B0C0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _TechItem extends StatelessWidget {
  final String name;
  final String description;
  const _TechItem(this.name, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' — $description'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
    );
  }
}
