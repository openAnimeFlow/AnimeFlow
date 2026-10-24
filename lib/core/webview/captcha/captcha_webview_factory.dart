import 'dart:io';
import 'captcha_webview_controller.dart';
import 'impl/captcha_webview_inappwebview_impl.dart';
import 'impl/captcha_webview_linux_impl.dart';
import 'impl/captcha_webview_windows_impl.dart';

class CaptchaWebviewControllerFactory {
  static CaptchaWebviewController getController() {
    if (Platform.isWindows) {
      return CaptchaWebviewWindowsImpl();
    }
    if (Platform.isLinux) {
      return CaptchaWebviewLinuxImpl();
    }
    // Android, iOS, macOS
    return CaptchaWebviewInAppWebviewImpl();
  }
}
