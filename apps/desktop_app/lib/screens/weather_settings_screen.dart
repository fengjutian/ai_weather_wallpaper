import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:local_storage/local_storage.dart';

/// Weather provider and city configuration.
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
    'Beijing',
    'Shanghai',
    'Tokyo',
    'New York',
    'London',
    'Paris',
    'Sydney',
    'Moscow',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final city = _hive.get('session', 'city', defaultValue: 'Beijing');
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
        const SnackBar(content: Text('Weather settings saved.')),
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
        title: const Text('Weather Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Provider ---
          const _SectionHeader(title: 'Weather Provider'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'openweathermap', label: Text('OpenWeather')),
              ButtonSegment(value: 'qweather', label: Text('QWeather')),
            ],
            selected: {_provider},
            onSelectionChanged: (v) => setState(() => _provider = v.first),
          ),
          const SizedBox(height: 20),

          // --- API Key ---
          const _SectionHeader(title: 'API Key'),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter your API key...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // --- City ---
          const _SectionHeader(title: 'Default City'),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: 'City name...',
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

          // --- Save ---
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
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
