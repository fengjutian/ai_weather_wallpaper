import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:local_storage/local_storage.dart';

/// General application settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HiveHelper _hive = HiveHelper.instance;
  bool _startMinimized = false;
  bool _autoStart = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final startMin = _hive.get('settings', 'startMinimized',
        defaultValue: false);
    final autoStart =
        _hive.get('settings', 'autoStart', defaultValue: false);
    setState(() {
      _startMinimized = startMin;
      _autoStart = autoStart;
    });
  }

  Future<void> _saveStartMinimized(bool v) async {
    await _hive.put('settings', 'startMinimized', v);
    setState(() => _startMinimized = v);
  }

  Future<void> _saveAutoStart(bool v) async {
    await _hive.put('settings', 'autoStart', v);
    setState(() => _autoStart = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- General ---
          _SectionHeader(title: 'General'),
          SwitchListTile(
            title: const Text('Start minimised to tray'),
            subtitle: const Text('Launch silently in the system tray'),
            value: _startMinimized,
            onChanged: _saveStartMinimized,
          ),
          SwitchListTile(
            title: const Text('Launch on startup'),
            subtitle: const Text('Run automatically when Windows starts'),
            value: _autoStart,
            onChanged: _saveAutoStart,
          ),
          const Divider(height: 32),

          // --- Weather ---
          _SectionHeader(title: 'Weather'),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Weather Settings'),
            subtitle: const Text('City, provider, API key'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/weather-settings'),
          ),
          const Divider(height: 32),

          // --- Wallpaper ---
          _SectionHeader(title: 'Wallpaper'),
          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: const Text('Wallpaper Picker'),
            subtitle: const Text('Choose and preview wallpapers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/wallpaper-picker'),
          ),
          const Divider(height: 32),

          // --- About ---
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/about'),
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
