import 'dart:async';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:webview_windows/webview_windows.dart';

class WebviewWindowsItemControllerImpel
    extends WebviewItemController<WebviewController> {
  final List<StreamSubscription> subscriptions = [];

  @override
  Future<void> init() async {
    initEventController.add(true);
  }
  
  Future<void> _ensureInitialized() async {
    if (webviewController != null) {
      return;
    }
    
    webviewController = WebviewController();
    await webviewController!.initialize();
    await webviewController!
        .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
  }

  @override
  Future<void> loadUrl(String url, bool useNativePlayer, bool useLegacyParser,
      {int offset = 0}) async {
    await _ensureInitialized();
    
    await unloadPage();
    count = 0;
    this.offset = offset;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    subscriptions.add(webviewController!.onM3USourceLoaded.listen((data) {
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
      _destroyWindowAfterDelay();
    }));
    subscriptions.add(webviewController!.onVideoSourceLoaded.listen((data) {
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
      _destroyWindowAfterDelay();
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
    if (webviewController != null) {
      await redirect2Blank();
    }
  }

  @override
  void dispose() {
    subscriptions.forEach((s) {
      try {
        s.cancel();
      } catch (_) {}
    });
    if (webviewController != null) {
      webviewController!.dispose();
      webviewController = null;
    }
  }

  // The webview_windows package does not have a method to unload the current page. 
  // The loadUrl method opens a new tab, which can lead to memory leaks. 
  // Directly disposing of the webview controller would require reinitialization when switching episodes, which is costly. 
  // Therefore, this method is used to redirect to a blank page instead.
  Future<void> redirect2Blank() async {
    if (webviewController == null) {
      return;
    }
    try {
      await webviewController!.executeScript('''
        window.location.href = 'about:blank';
      ''');
    } catch (e) {
      // 忽略错误，可能窗口已经被销毁
    }
  }

  void _destroyWindowAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (webviewController != null && isVideoSourceLoaded) {
        try {
          webviewController!.dispose();
          webviewController = null;
          logEventController.add('WebView 窗口已销毁，释放桌面资源');
        } catch (e) {
          // 忽略错误
        }
      }
    });
  }
}
