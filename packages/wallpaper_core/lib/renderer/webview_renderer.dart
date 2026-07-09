import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders a live web page as wallpaper using an embedded WebView.
///
/// On Windows, this uses Microsoft Edge WebView2 under the hood.
class WebViewRenderer {
  WebViewController? _controller;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Creates and loads a WebView for [url].
  /// Returns a [Widget] for embedding in the wallpaper layer.
  Future<Widget> load(String url) async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(url));
    _loaded = true;
    return WebViewWidget(controller: _controller!);
  }

  Widget? buildView() {
    if (_controller == null) return null;
    return WebViewWidget(controller: _controller!);
  }

  void dispose() {
    _controller = null;
    _loaded = false;
  }
}
