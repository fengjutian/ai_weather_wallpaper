import 'package:flutter/material.dart';
import 'package:common_ui/common_ui.dart';
import 'package:wallpaper_core/wallpaper_core.dart';
import 'package:file_selector/file_selector.dart';

import '../bootstrap.dart';

/// 浏览本地文件并设为壁纸
class WallpaperPickerScreen extends StatefulWidget {
  const WallpaperPickerScreen({super.key});

  @override
  State<WallpaperPickerScreen> createState() => _WallpaperPickerScreenState();
}

class _WallpaperPickerScreenState extends State<WallpaperPickerScreen> {
  final WallpaperEngine _engine = WallpaperEngine.instance;
  final List<String> _history = [];
  String? _current;

  Future<void> _browseFile() async {
    try {
      const typeGroup = XTypeGroup(
        label: '图片和视频',
        extensions: [
          'png', 'jpg', 'jpeg', 'bmp', 'webp',
          'mp4', 'webm', 'mov', 'gif',
        ],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      await _apply(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: $e')),
        );
      }
    }
  }

  Future<void> _apply(String path) async {
    try {
      await _engine.start(path);
      // Set as actual Windows desktop wallpaper
      try {
        win32.setDesktopWallpaper(path);
      } catch (e) {
        debugPrint('setDesktopWallpaper failed: $e');
      }
      setState(() {
        _current = path;
        if (!_history.contains(path)) {
          _history.insert(0, path);
          if (_history.length > 20) _history.removeLast();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('壁纸选择'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _browseFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('浏览本地文件...'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          if (_history.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('最近使用',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child: Text(
                      '暂无壁纸。\n点击"浏览"选择图片或视频。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF888888)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final path = _history[index];
                      final name = path.split(RegExp(r'[\\/]')).last;
                      final isActive = path == _current;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isActive
                              ? const BorderSide(
                                  color: AppTheme.primary, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          leading: Icon(
                            _isVideo(name) ? Icons.movie : Icons.image,
                            color: isActive
                                ? AppTheme.primary
                                : Colors.grey,
                          ),
                          title: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11)),
                          trailing: isActive
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.primary)
                              : TextButton(
                                  onPressed: () => _apply(path),
                                  child: const Text('设置'),
                                ),
                          onTap: () => _apply(path),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isVideo(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'webm', 'mov', 'gif', 'avi', 'mkv'].contains(ext);
  }
}
