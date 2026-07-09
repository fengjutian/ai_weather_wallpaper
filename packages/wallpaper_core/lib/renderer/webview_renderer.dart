import 'package:flutter/material.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart';

/// Renders a live web page as wallpaper using Microsoft Edge WebView2.
class WebViewRenderer {
  final WebviewController _controller = WebviewController();
  bool _initialized = false;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> init() async {
    if (_initialized) return;
    await _controller.initialize();
    _initialized = true;
  }

  Future<void> loadUrl(String url) async {
    await init();
    await _controller.loadUrl(url);
    _loaded = true;
  }

  Widget buildView() {
    if (!_initialized) return const SizedBox.shrink();
    return Webview(_controller);
  }

  void dispose() {
    _controller.dispose();
    _initialized = false;
    _loaded = false;
  }
}
