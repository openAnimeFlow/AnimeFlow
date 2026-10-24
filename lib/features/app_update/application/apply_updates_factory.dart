import 'dart:io';
import 'apply_updates_controller.dart';
import 'apply_updates_impl/apply_updates_android_controller_impl.dart';
import 'apply_updates_impl/apply_updates_ios_controller_impl.dart';
import 'apply_updates_impl/apply_updates_linux_controller_impl.dart';
import 'apply_updates_impl/apply_updates_macos_controller_impl.dart';
import 'apply_updates_impl/apply_updates_windows_controller_impl.dart';

/// 更新控制器工厂类
/// 根据当前平台返回对应的实现
class ApplyUpdatesFactory {
  /// 获取当前平台的更新控制器实例
  static ApplyUpdatesController getController() {
    if (Platform.isAndroid) {
      return ApplyUpdatesAndroidController();
    } else if (Platform.isIOS) {
      return ApplyUpdatesIOSController();
    } else if (Platform.isWindows) {
      return ApplyUpdatesWindowsController();
    } else if (Platform.isMacOS) {
      return ApplyUpdatesMacOSController();
    } else if (Platform.isLinux) {
      return ApplyUpdatesLinuxController();
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }
}
