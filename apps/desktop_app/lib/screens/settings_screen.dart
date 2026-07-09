import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:local_storage/local_storage.dart';

/// 设置页面 — 磨玻璃风格
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
    final startMin = _hive.get('settings', 'startMinimized', defaultValue: false);
    final autoStart = _hive.get('settings', 'autoStart', defaultValue: false);
    setState(() { _startMinimized = startMin; _autoStart = autoStart; });
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D0D1A), Color(0xFF1A1A3E), Color(0xFF0A0A20)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              GlassAppBar(title: '设置', onBack: () => Navigator.pop(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle('通用'),
                          SwitchListTile(
                            title: const Text('启动时最小化到托盘',
                                style: TextStyle(color: Colors.white70)),
                            subtitle: const Text('静默启动到系统托盘',
                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                            value: _startMinimized,
                            onChanged: _saveStartMinimized,
                            activeColor: AppTheme.primary,
                          ),
                          const Divider(color: Colors.white10),
                          SwitchListTile(
                            title: const Text('开机自启动',
                                style: TextStyle(color: Colors.white70)),
                            subtitle: const Text('Windows 启动时自动运行',
                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                            value: _autoStart,
                            onChanged: _saveAutoStart,
                            activeColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle('壁纸'),
                          ListTile(
                            leading: const Icon(Icons.wallpaper, color: Colors.white54),
                            title: const Text('壁纸选择', style: TextStyle(color: Colors.white70)),
                            subtitle: const Text('浏览本地文件并设置壁纸',
                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                            onTap: () => Navigator.pushNamed(context, '/wallpaper-picker'),
                          ),
                        ],
                      ),
                    ),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle('关于'),
                          ListTile(
                            leading: const Icon(Icons.info_outline, color: Colors.white54),
                            title: const Text('关于', style: TextStyle(color: Colors.white70)),
                            subtitle: const Text('版本 1.0.0',
                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                            onTap: () => Navigator.pushNamed(context, '/about'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title,
          style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }
}
