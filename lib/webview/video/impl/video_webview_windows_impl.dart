import 'dart:async';
import 'package:anime_flow/webview/video/video_webview_controller.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:webview_windows/webview_windows.dart';

class VideoWebviewWindowsImpl
    extends VideoWebviewController<WebviewController> {
  final List<StreamSubscription> subscriptions = [];

  @override
  Future<void> init() async {
    webviewController ??= WebviewController();
    await webviewController!.initialize();
    await webviewController!
        .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    initEventController.add(true);
  }

  @override
  Future<void> loadUrl(String url, bool useLegacyParser,
      {int offset = 0}) async {
    await unloadPage();
    count = 0;
    this.offset = offset;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    subscriptions.add(webviewController!.onM3USourceLoaded.listen((data) {
      if (webviewController == null) return;
      String url = data['url'] ?? '';
      if (url.isEmpty) {
        return;
      }
      unloadPage();
      isIframeLoaded = true;
      isVideoSourceLoaded = true;
      videoLoadingEventController.add(false);
      logEventController.add('Loading m3u8 source: $url');
      videoParserEventController.add((url, offset));
    }));
    subscriptions.add(webviewController!.onVideoSourceLoaded.listen((data) {
      if (webviewController == null) return;
      String url = data['url'] ?? '';
      if (url.isEmpty) {
        return;
      }
      unloadPage();
      isIframeLoaded = true;
      isVideoSourceLoaded = true;
      videoLoadingEventController.add(false);
      logEventController.add('Loading video source: $url');
      videoParserEventController.add((url, offset));
    }));
    await webviewController!.loadUrl(url);
  }

  @override
  Future<void> unloadPage() async {
    subscriptions.forEach((s) {
      try {
        s.cancel();
      } catch (_) {}
    });
    subscriptions.clear();
    await redirect2Blank();
  }

  @override
  void dispose() {
    subscriptions.forEach((s) {
      try {
        s.cancel();
      } catch (_) {}
    });
    subscriptions.clear();
    webviewController?.dispose();
    webviewController = null;
  }

  // The webview_windows package does not have a method to unload the current page.
  // The loadUrl method opens a new tab, which can lead to memory leaks.
  // Directly disposing of the webview controller would require reinitialization when switching episodes, which is costly.
  // Therefore, this method is used to redirect to a blank page instead.
  Future<void> redirect2Blank() async {
    if (webviewController == null) return;
    try {
      await webviewController!.executeScript('''
        window.location.href = 'about:blank';
      ''');
    } catch (e) {
      LiggLogger().d('WebView: redirect2Blank skipped (likely disposed): $e');
    }
  }
}
