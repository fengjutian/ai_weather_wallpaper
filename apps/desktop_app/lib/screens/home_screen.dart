import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:wallpaper_core/wallpaper_core.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:file_selector/file_selector.dart';
import 'package:local_storage/local_storage.dart';

import '../bootstrap.dart';
import '../app.dart';

/// 主页面 — macOS 风格侧边栏 + 磨玻璃内容区
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WallpaperEngine _engine = WallpaperEngine.instance;
  final HiveHelper _hive = HiveHelper.instance;

  List<WallpaperEntry> _wallpapers = [];
  WallpaperEntry? _selected;
  String? _activePath;
  AudioPlayer? _audioPlayer;
  int _sidebarIndex = 0;
  bool _sidebarHovered = true;

  static const _sidebarItems = [
    _SidebarItem(Icons.photo_library_outlined, '壁纸库'),
    _SidebarItem(Icons.favorite_border, '收藏夹'),
    _SidebarItem(Icons.settings_outlined, '设置'),
    _SidebarItem(Icons.info_outline, '关于'),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _engine.stateNotifier.addListener(_onStateChange);
    themeModeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _engine.stateNotifier.removeListener(_onStateChange);
    themeModeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onStateChange() { if (mounted) setState(() {}); }
  void _onThemeChange() { if (mounted) setState(() {}); }

  void _loadHistory() {
    final raw = _hive.get('session', 'wallpaperHistory', defaultValue: <dynamic>[]);
    if (raw is List) {
      setState(() {
        _wallpapers = raw.whereType<String>().map(_buildEntry).toList();
        _wallpapers.removeWhere((e) => !e.exists);
      });
    }
  }

  void _saveHistory() {
    _hive.put('session', 'wallpaperHistory', _wallpapers.map((e) => e.path).toList());
  }

  WallpaperEntry _buildEntry(String path) {
    final file = File(path);
    final exists = file.existsSync();
    final stat = exists ? file.statSync() : null;
    return WallpaperEntry(
      path: path, name: path.split(RegExp(r'[\\/]')).last,
      exists: exists, size: stat?.size ?? 0, modified: stat?.modified,
    );
  }

  Future<void> _browseAndAdd() async {
    try {
      const tg = XTypeGroup(label: '图片', extensions: ['png', 'jpg', 'jpeg', 'bmp', 'webp', 'gif']);
      final file = await openFile(acceptedTypeGroups: [tg]);
      if (file == null) return;
      final entry = _buildEntry(file.path);
      setState(() {
        _wallpapers.removeWhere((e) => e.path == entry.path);
        _wallpapers.insert(0, entry);
        _selected = entry;
      });
      _saveHistory();
      await _apply(entry);
    } catch (e) { _showError('选择失败: $e'); }
  }

  Future<void> _apply(WallpaperEntry entry) async {
    try {
      if (!entry.exists) { _showError('文件不存在'); return; }
      await _engine.start(entry.path);
      win32.setDesktopWallpaper(entry.path);
      setState(() => _activePath = entry.path);
    } catch (e) { _showError('设置失败: $e'); }
  }

  void _removeEntry(WallpaperEntry entry) {
    setState(() {
      _wallpapers.removeWhere((e) => e.path == entry.path);
      if (_selected?.path == entry.path) _selected = null;
    });
    _saveHistory();
  }

  void _showDeleteConfirm(WallpaperEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('文件不存在'),
        content: Text('"${entry.name}" 已不存在，移除？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _removeEntry(entry); },
            child: const Text('移除', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _stopWallpaper() { _engine.stop(); setState(() => _activePath = null); }

  Future<void> _toggleRain() async {
    if (_audioPlayer != null) { await _audioPlayer!.dispose(); _audioPlayer = null; }
    else { _audioPlayer = AudioPlayer(config: Rain.config); await _audioPlayer!.play(); }
    setState(() {});
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Theme helpers ────────────────────────────────────────────────────
  Color get _text => Theme.of(context).brightness == Brightness.dark
      ? Colors.white : Colors.black87;
  Color get _muted => Theme.of(context).brightness == Brightness.dark
      ? Colors.white70 : Colors.black54;
  Color get _subtle => Theme.of(context).brightness == Brightness.dark
      ? Colors.white38 : Colors.black38;
  Color get _faint => Theme.of(context).brightness == Brightness.dark
      ? Colors.white12 : Colors.black12;
  Color get _dividerColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white10 : Colors.black12;

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: _activePath != null
                ? Image.file(File(_activePath!), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackBg())
                : _fallbackBg(),
          ),
          // Dim overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.15),
                    Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.65 : 0.3),
                  ],
                ),
              ),
            ),
          ),

          // ── Layout: Sidebar + Content ──
          Row(
            children: [
              // ── Frosted Sidebar ──
              _buildSidebar(),

              // ── Content Area ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sidebar ──────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    final expanded = _sidebarHovered;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.3);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);
    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarHovered = true),
      onExit: (_) => setState(() => _sidebarHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: expanded ? 180 : 72,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // App icon
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF64FFDA), Color(0xFF48B0D5)],
                              ),
                            ),
                            child: const Icon(Icons.cloud, color: Colors.black87, size: 22),
                          ),
                          if (expanded) ...[
                            const SizedBox(width: 12),
                            Text('AI 天气壁纸',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Separator
                    if (expanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08), height: 1),
                      ),
                    const SizedBox(height: 8),
                    // Nav items
                    ..._sidebarItems.asMap().entries.map((e) => _sidebarBtn(
                      item: e.value, isActive: e.key == _sidebarIndex, expanded: expanded,
                      onTap: () => setState(() => _sidebarIndex = e.key),
                    )),
                    const Spacer(),
                    // Separator
                    if (expanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08), height: 1),
                      ),
                    const SizedBox(height: 4),
                    // Bottom buttons
                    _sidebarBtn(
                      item: const _SidebarItem(Icons.add_rounded, '添加壁纸'), expanded: expanded,
                      onTap: _browseAndAdd,
                    ),
                    const SizedBox(height: 2),
                    _sidebarBtn(
                      item: _SidebarItem(
                        _audioPlayer != null ? Icons.volume_up : Icons.volume_off, '雨声音效',
                      ),
                      isActive: _audioPlayer != null, expanded: expanded,
                      onTap: _toggleRain,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Content Pages ────────────────────────────────────────────────────

  Widget _buildContent() {
    switch (_sidebarIndex) {
      case 0: return _buildWallpaperLibrary();
      case 1: return _buildFavorites();
      case 2: return _buildSettings();
      case 3: return _buildAbout();
      default: return _buildWallpaperLibrary();
    }
  }

  // ── Wallpaper Library ──

  Widget _buildWallpaperLibrary() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('壁纸库', '${_wallpapers.length} 张'),
          const SizedBox(height: 12),
          Expanded(
            child: _wallpapers.isEmpty
                ? _emptyPlaceholder('还没有壁纸', '点击左侧 + 添加', () => _browseAndAdd())
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 10,
                            mainAxisSpacing: 10, childAspectRatio: 1.05,
                          ),
                          itemCount: _wallpapers.length,
                          itemBuilder: (_, i) {
                            final e = _wallpapers[i];
                            return _WallpaperTile(
                              entry: e,
                              isActive: e.path == _activePath,
                              isSelected: e.path == _selected?.path,
                              onTap: () => setState(() => _selected = e),
                              onApply: () => _apply(e),
                              onDelete: () => e.exists ? _removeEntry(e) : _showDeleteConfirm(e),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Detail panel
                      SizedBox(
                        width: 280,
                        child: _selected != null
                            ? _buildDetailPanel(_selected!)
                            : _glassPanel(Center(
                                child: Text('选择一张壁纸查看详情',
                                    style: TextStyle(color: _subtle))))),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(WallpaperEntry e) {
    final active = e.path == _activePath;
    return _glassPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: e.exists
                  ? Image.file(File(e.path), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _brokenPreview())
                  : _brokenPreview(),
            ),
          ),
          const SizedBox(height: 16),
          Text(e.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          _infoRow('状态', e.exists ? '✅ 存在' : '❌ 不存在'),
          if (e.exists) ...[
            _infoRow('大小', _fmtSize(e.size)),
            if (e.modified != null) _infoRow('时间', _fmtDate(e.modified!)),
          ],
          const SizedBox(height: 12),
          Text(e.path, style: const TextStyle(fontSize: 10, color: Colors.white38), maxLines: 2),
          const SizedBox(height: 20),
          if (!e.exists)
            GlassButton(label: '🗑 移除', onPressed: () => _showDeleteConfirm(e), color: AppTheme.error)
          else ...[
            Row(
              children: [
                Expanded(
                  child: active
                      ? GlassButton(label: '⏹ 停止', onPressed: _stopWallpaper, color: AppTheme.error)
                      : GlassButton(label: '✅ 设为壁纸', onPressed: () => _apply(e), color: AppTheme.primary),
                ),
                if (e.exists) ...[
                  const SizedBox(width: 8),
                  GlassButton(label: '🗑', onPressed: () => _removeEntry(e)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Favorites ──

  Widget _buildFavorites() {
    return _emptyPlaceholder('收藏夹', '即将推出', null);
  }

  // ── Settings ──

  Widget _buildSettings() {
    bool startMin = false, autoStart = false;
    // load once
    startMin = _hive.get('settings', 'startMinimized', defaultValue: false);
    autoStart = _hive.get('settings', 'autoStart', defaultValue: false);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('设置', ''),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _glassPanel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('通用'),
                      _macSwitch('启动时最小化到托盘', startMin,
                          (v) {
                            _hive.put('settings', 'startMinimized', v);
                            setState(() => startMin = v);
                            if (v) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('下次启动时将自动最小化到托盘')));
                            }
                          }),
                      Divider(color: _dividerColor),
                      _macSwitch('开机自启动', autoStart,
                          (v) {
                            _hive.put('settings', 'autoStart', v);
                            setState(() => autoStart = v);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(v ? '已开启开机自启动（重启后生效）' : '已关闭开机自启动')));
                          }),
                      Divider(color: _dividerColor),
                      _macSwitch('浅色模式',
                          themeModeNotifier.value == ThemeMode.light,
                          (v) {
                            themeModeNotifier.value = v ? ThemeMode.light : ThemeMode.dark;
                            _hive.put('settings', 'themeMode', v ? 'light' : 'dark');
                          }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassPanel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('关于'),
                      InkWell(
                        onTap: () => setState(() => _sidebarIndex = 3),
                        child: _macListTile(Icons.info_outline, '关于 AI 天气壁纸', '版本 1.0.0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── About ──

  Widget _buildAbout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _sectionHeader('AI 天气壁纸', 'v1.0.0'),
          const SizedBox(height: 20),
          _glassPanel(
            Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [Color(0xFF64FFDA), Color(0xFF48B0D5)]),
                  ),
                  child: const Icon(Icons.cloud, color: Colors.black87, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('AI 天气壁纸', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('将 Windows 桌面变成活的画布', style: TextStyle(color: _muted)),
                const SizedBox(height: 20),
                const _FeatureRow(Icons.wallpaper, '本地图片设为桌面壁纸'),
                const _FeatureRow(Icons.blur_on, '磨玻璃 macOS 风格界面'),
                const _FeatureRow(Icons.audiotrack, '环境音效（雨声）'),
                const _FeatureRow(Icons.auto_awesome, 'AI 天气生成（即将推出）'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text('用心打造美好的桌面体验 ❤️', style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────────────────────

  Widget _fallbackBg() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: isDark
          ? const [Color(0xFF0D0D1A), Color(0xFF1A1A3E), Color(0xFF0A0A20)]
          : const [Color(0xFFF0F0F5), Color(0xFFE8E8F0), Color(0xFFFAFAFF)]),
    ),
  );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _text)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(subtitle, style: TextStyle(fontSize: 13, color: _subtle)),
        ],
      ],
    );
  }

  Widget _emptyPlaceholder(String title, String subtitle, VoidCallback? onAction) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 48, color: _faint),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, color: _muted)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: _subtle)),
        if (onAction != null) ...[
          const SizedBox(height: 20),
          GlassButton(label: '📁 浏览文件...', onPressed: onAction),
        ],
      ]),
    );
  }

  Widget _glassPanel(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _brokenPreview() => Container(
    color: Colors.white.withOpacity(0.03),
    child: const Center(child: Icon(Icons.broken_image, size: 40, color: AppTheme.error)),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 12, color: _subtle)),
      Text(value, style: TextStyle(fontSize: 12, color: _muted)),
    ]),
  );

  Widget _macSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: _muted))),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: value, onChanged: onChanged,
              activeColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macListTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13, color: _muted)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: _subtle)),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.white12),
        ],
      ),
    );
  }

  String _fmtSize(int b) => b < 1024 ? '$b B' : b < 1048576 ? '${(b / 1024).toStringAsFixed(1)} KB' : '${(b / 1048576).toStringAsFixed(1)} MB';
  String _fmtDate(DateTime d) => '${d.year}-${_p(d.month)}-${_p(d.day)} ${_p(d.hour)}:${_p(d.minute)}';
  String _p(int n) => n.toString().padLeft(2, '0');
}

// ─── Data ───────────────────────────────────────────────────────────────

class WallpaperEntry {
  final String path, name;
  final bool exists;
  final int size;
  final DateTime? modified;
  const WallpaperEntry({required this.path, required this.name, required this.exists, required this.size, this.modified});
}

class _SidebarItem { final IconData icon; final String label; const _SidebarItem(this.icon, this.label); }

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 0.5)),
  );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.primary.withOpacity(0.7)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white60))),
    ]),
  );
}

// ─── Sidebar Button ────────────────────────────────────────────────────

class _sidebarBtn extends StatelessWidget {
  final _SidebarItem item;
  final bool isActive;
  final bool expanded;
  final VoidCallback onTap;

  const _sidebarBtn({required this.item, this.isActive = false, this.expanded = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.primary;
    final inactiveColor = isDark ? Colors.white.withOpacity(0.45) : Colors.black.withOpacity(0.45);
    final bgColor = isActive
        ? (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08))
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 6, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: bgColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 20, color: isActive ? activeColor : inactiveColor),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive ? activeColor : inactiveColor,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Wallpaper Tile ─────────────────────────────────────────────────────

class _WallpaperTile extends StatelessWidget {
  final WallpaperEntry entry;
  final bool isActive, isSelected;
  final VoidCallback onTap, onApply, onDelete;

  const _WallpaperTile({
    required this.entry, required this.isActive, required this.isSelected,
    required this.onTap, required this.onApply, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: (isActive ? AppTheme.primary : Colors.white).withOpacity(isActive ? 0.12 : 0.04),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? AppTheme.primary.withOpacity(0.3) : Colors.white.withOpacity(0.06),
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: entry.exists
                          ? Icon(isActive ? Icons.wallpaper : Icons.image, size: 28,
                              color: isActive ? AppTheme.primary : Colors.white30)
                          : const Icon(Icons.broken_image, size: 28, color: AppTheme.error),
                    ),
                  ),
                  Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54)),
                  if (entry.exists && entry.size > 0)
                    Text(_fmtSizeCompact(entry.size), style: TextStyle(fontSize: 9, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtSizeCompact(int b) => b < 1024 ? '$b B' : '${(b ~/ 1024)} KB';
}
