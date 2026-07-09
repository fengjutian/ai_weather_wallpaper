import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:local_storage/local_storage.dart';

/// 通用设置页面
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
    final startMin =
        _hive.get('settings', 'startMinimized', defaultValue: false);
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
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: '通用'),
          SwitchListTile(
            title: const Text('启动时最小化到托盘'),
            subtitle: const Text('静默启动到系统托盘'),
            value: _startMinimized,
            onChanged: _saveStartMinimized,
          ),
          SwitchListTile(
            title: const Text('开机自启动'),
            subtitle: const Text('Windows 启动时自动运行'),
            value: _autoStart,
            onChanged: _saveAutoStart,
          ),
          const Divider(height: 32),

          _SectionHeader(title: '壁纸'),
          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: const Text('壁纸选择'),
            subtitle: const Text('浏览本地文件并设置壁纸'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/wallpaper-picker'),
          ),
          const Divider(height: 32),

          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('版本 1.0.0'),
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
