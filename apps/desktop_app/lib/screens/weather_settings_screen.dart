import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:local_storage/local_storage.dart';

/// 天气设置 — 城市与 API Key 配置
class WeatherSettingsScreen extends StatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  State<WeatherSettingsScreen> createState() => _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends State<WeatherSettingsScreen> {
  final HiveHelper _hive = HiveHelper.instance;
  final _cityController = TextEditingController();
  final _apiKeyController = TextEditingController();
  String _provider = 'openweathermap';

  static const _cities = [
    '北京',
    '上海',
    '东京',
    '纽约',
    '伦敦',
    '巴黎',
    '悉尼',
    '莫斯科',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final city = _hive.get('session', 'city', defaultValue: '北京');
    final apiKey =
        _hive.get('settings', 'openweatherApiKey', defaultValue: '');
    final provider =
        _hive.get('settings', 'weatherProvider', defaultValue: 'openweathermap');
    _cityController.text = city;
    _apiKeyController.text = apiKey;
    _provider = provider;
  }

  Future<void> _save() async {
    await _hive.put('session', 'city', _cityController.text.trim());
    await _hive.put('settings', 'openweatherApiKey', _apiKeyController.text.trim());
    await _hive.put('settings', 'weatherProvider', _provider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('天气设置已保存。')),
      );
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('天气设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeader(title: '天气服务商'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'openweathermap', label: Text('OpenWeather')),
              ButtonSegment(value: 'qweather', label: Text('和风天气')),
            ],
            selected: {_provider},
            onSelectionChanged: (v) => setState(() => _provider = v.first),
          ),
          const SizedBox(height: 20),

          const _SectionHeader(title: 'API Key'),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: '输入 API Key...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          const _SectionHeader(title: '默认城市'),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: '城市名称...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _cities.map((c) {
              return ActionChip(
                label: Text(c),
                onPressed: () => _cityController.text = c,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存设置'),
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
