import 'dart:io';
import 'video_webview_controller.dart';

import 'package:anime_flow/core/utils/utils.dart';

import 'impl/video_webview_android_impl.dart';
import 'impl/video_webview_apple_impl.dart';
import 'impl/video_webview_impl.dart';
import 'impl/video_webview_linux_impl.dart';
import 'impl/video_webview_windows_impl.dart';

class VideoWebviewControllerFactory {
  static VideoWebviewController getController() {
    if (Platform.isWindows) {
      return VideoWebviewWindowsImpl();
    }
    if (Platform.isLinux) {
      return VideoWebviewLinuxImpl();
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return VideoWebviewAppleImpl();
    }
    if (Platform.isAndroid && Utils.isDocumentStartScriptSupported) {
      return VideoWebviewAndroidImpl();
    }
    return VideoWebviewImpl();
  }
}
