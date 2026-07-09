import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';

/// 关于页面 — 应用信息与技术栈
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.cloud, size: 72, color: AppTheme.primary),
                SizedBox(height: 12),
                Text(
                  'AI 天气壁纸',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('v1.0.0', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF888888))),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const _SectionHeader(title: '简介'),
          const Text(
            'AI 天气壁纸将你的 Windows 桌面变成一幅活的画布，'
            '根据真实天气实时变化。下雨、下雪、晴朗或星空——'
            '你的壁纸会自动适配，配合 AI 生成和丰富的粒子特效。',
            style: TextStyle(height: 1.5),
          ),
          const Divider(height: 32),

          const _SectionHeader(title: '技术栈'),
          _TechItem('Flutter', '跨平台 UI 框架'),
          _TechItem('OpenWeather / 和风天气', '实时天气数据'),
          _TechItem('OpenAI DALL·E / Stable Diffusion', 'AI 壁纸生成'),
          _TechItem('Audioplayers', '环境音效播放'),
          _TechItem('Hive + SQLite', '本地持久化存储'),
          const Divider(height: 32),

          const _SectionHeader(title: '功能特性'),
          _FeatureItem('🌦️ 实时天气同步'),
          _FeatureItem('🖼️ 图片 / 视频 / Lottie / Shader 壁纸'),
          _FeatureItem('🌧️ 雨、雪、云、极光粒子特效'),
          _FeatureItem('🔊 环境音效（雨声、海浪、森林、白噪音）'),
          _FeatureItem('🤖 AI 根据天气生成壁纸'),
          _FeatureItem('🌸 二十四节气自动切换'),
          const Divider(height: 32),

          const Center(
            child: Text(
              '用心打造美好的桌面体验 ❤️',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF888888)),
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
