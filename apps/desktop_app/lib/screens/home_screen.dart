import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:wallpaper_core/wallpaper_core.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:file_selector/file_selector.dart';
import 'package:local_storage/local_storage.dart';

import '../bootstrap.dart';

/// 主页面 — 磨玻璃风格图片卡片列表 + 右侧详情面板
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _engine.stateNotifier.addListener(_onEngineChanged);
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _engine.stateNotifier.removeListener(_onEngineChanged);
    super.dispose();
  }

  void _onEngineChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // ─── Persistence ──────────────────────────────────────────────────────

  void _loadHistory() {
    final raw = _hive.get('session', 'wallpaperHistory', defaultValue: <dynamic>[]);
    if (raw is List) {
      setState(() {
        _wallpapers = raw
            .whereType<String>()
            .map((p) => _buildEntry(p))
            .toList();
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
      path: path,
      name: path.split(RegExp(r'[\\/]')).last,
      exists: exists,
      size: stat?.size ?? 0,
      modified: stat?.modified,
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────

  Future<void> _browseAndAdd() async {
    try {
      const typeGroup = XTypeGroup(
        label: '图片',
        extensions: ['png', 'jpg', 'jpeg', 'bmp', 'webp', 'gif'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      final entry = _buildEntry(file.path);
      setState(() {
        _wallpapers.removeWhere((e) => e.path == entry.path);
        _wallpapers.insert(0, entry);
        _selected = entry;
      });
      _saveHistory();
      await _apply(entry);
    } catch (e) {
      _showError('选择文件失败: $e');
    }
  }

  Future<void> _apply(WallpaperEntry entry) async {
    try {
      if (!entry.exists) { _showError('文件不存在'); return; }
      await _engine.start(entry.path);
      win32.setDesktopWallpaper(entry.path);
      setState(() => _activePath = entry.path);
    } catch (e) {
      _showError('设置壁纸失败: $e');
    }
  }

  void _showDeleteConfirm(WallpaperEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('文件不存在'),
        content: Text('"${entry.name}" 已不存在，从列表中移除？'),
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

  void _removeEntry(WallpaperEntry entry) {
    setState(() {
      _wallpapers.removeWhere((e) => e.path == entry.path);
      if (_selected?.path == entry.path) _selected = null;
    });
    _saveHistory();
  }

  void _stopWallpaper() {
    _engine.stop();
    setState(() => _activePath = null);
  }

  Future<void> _toggleRain() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    } else {
      _audioPlayer = AudioPlayer(config: Rain.config);
      await _audioPlayer!.play();
    }
    setState(() {});
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Background image with dark overlay ──
          Positioned.fill(
            child: _activePath != null
                ? Image.file(
                    File(_activePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackBg(),
                  )
                : _buildFallbackBg(),
          ),
          // Dark gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Column(
            children: [
              // Glass app bar
              GlassAppBar(
                title: 'AI 天气壁纸',
                actions: [
                  GlassButton(
                    label: _audioPlayer != null ? '🔊 雨声' : '🔇 雨声',
                    onPressed: _toggleRain,
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    label: '⚙',
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),

              // ── Body ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      // Left — glass card grid
                      Expanded(
                        flex: 3,
                        child: _wallpapers.isEmpty
                            ? _buildEmptyState()
                            : _buildCardGrid(),
                      ),
                      const SizedBox(width: 16),
                      // Right — glass detail panel
                      SizedBox(
                        width: 260,
                        child: _selected != null
                            ? _buildGlassDetailPanel(_selected!)
                            : _buildEmptyDetail(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D1A), Color(0xFF1A1A3E), Color(0xFF0A0A20)],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wallpaper, size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            const Text('还没有壁纸',
                style: TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('点击下方按钮添加图片',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 24),
            GlassButton(label: '📁 浏览文件...', onPressed: _browseAndAdd),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('我的壁纸 (${_wallpapers.length})',
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
              GlassButton(label: '📁 添加', onPressed: _browseAndAdd),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemCount: _wallpapers.length,
            itemBuilder: (context, index) {
              final entry = _wallpapers[index];
              final isActive = entry.path == _activePath;
              final isSelected = entry.path == _selected?.path;
              return _GlassWallpaperCard(
                entry: entry,
                isActive: isActive,
                isSelected: isSelected,
                onTap: () => entry.exists
                    ? setState(() => _selected = entry)
                    : _showDeleteConfirm(entry),
                onApply: entry.exists ? () => _apply(entry) : null,
                onDelete: () => _showDeleteConfirm(entry),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDetail() {
    return GlassCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app, size: 40, color: Colors.white30),
            const SizedBox(height: 12),
            Text('点击左侧卡片\n查看详情',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassDetailPanel(WallpaperEntry entry) {
    final isActive = entry.path == _activePath;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 170,
              child: entry.exists
                  ? Image.file(
                      File(entry.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _brokenImage(),
                    )
                  : _brokenImage(),
            ),
          ),
          // Info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildDetailInfo(entry),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokenImage() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: AppTheme.error),
      ),
    );
  }

  Widget _buildDetailInfo(WallpaperEntry entry) {
    final isActive = entry.path == _activePath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(entry.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: const Text('使用中',
                    style: TextStyle(color: AppTheme.primary, fontSize: 11)),
              ),
          ],
        ),
        const Divider(height: 20, color: Colors.white12),
        _detailRow('状态', entry.exists ? '✅ 存在' : '❌ 不存在'),
        if (entry.exists) ...[
          _detailRow('大小', _formatSize(entry.size)),
          if (entry.modified != null)
            _detailRow('时间', _formatDate(entry.modified!)),
        ],
        const SizedBox(height: 12),
        const Text('路径', style: TextStyle(fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(entry.path, style: const TextStyle(fontSize: 10, color: Colors.white54),
            maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),
        if (!entry.exists) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('文件已移动或删除',
                style: TextStyle(color: AppTheme.error, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: '🗑 移除记录',
              onPressed: () => _showDeleteConfirm(entry),
              color: AppTheme.error,
            ),
          ),
        ] else ...[
          GlassButton(
            label: isActive ? '⏹ 停止' : '✅ 设为壁纸',
            onPressed: isActive ? _stopWallpaper : () => _apply(entry),
            color: isActive ? AppTheme.error : AppTheme.primary,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _removeEntry(entry),
              child: const Text('从列表移除',
                  style: TextStyle(color: Colors.white30, fontSize: 12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── Models ──────────────────────────────────────────────────────────────

class WallpaperEntry {
  final String path;
  final String name;
  final bool exists;
  final int size;
  final DateTime? modified;

  const WallpaperEntry({
    required this.path,
    required this.name,
    required this.exists,
    required this.size,
    this.modified,
  });
}

// ─── Glass Wallpaper Card ────────────────────────────────────────────────

class _GlassWallpaperCard extends StatelessWidget {
  final WallpaperEntry entry;
  final bool isActive;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onDelete;

  const _GlassWallpaperCard({
    required this.entry,
    required this.isActive,
    required this.isSelected,
    this.onTap,
    this.onApply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: (isActive
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.white.withOpacity(0.06))
              .withOpacity(isSelected ? 0.4 : 1),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? AppTheme.primary.withOpacity(0.4)
                      : Colors.white.withOpacity(0.08),
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: entry.exists
                          ? (isActive
                              ? const Icon(Icons.wallpaper, size: 32, color: AppTheme.primary)
                              : const Icon(Icons.image, size: 32, color: Colors.white38))
                          : const Icon(Icons.broken_image, size: 32, color: AppTheme.error),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
