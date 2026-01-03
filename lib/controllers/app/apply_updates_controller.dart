import 'dart:io';
import 'package:anime_flow/controllers/app/apply_updates_impl/apply_updates_android_controller_impl.dart';
import 'package:anime_flow/controllers/app/apply_updates_impl/apply_updates_ios_controller_impl.dart';
import 'package:anime_flow/controllers/app/apply_updates_impl/apply_updates_linux_controller_impl.dart';
import 'apply_updates_impl/apply_updates_macos_controller_impl.dart';
import 'apply_updates_impl/apply_updates_windows_controller_impl.dart';

abstract class ApplyUpdatesController {
  ///应用更新
  /// [downloadUrl] 下载地址
  /// [onProgress] 下载进度回调，参数为 (已下载字节数, 总字节数)
  Future<void> applyUpdates(
    String downloadUrl, {
        String? fileName,
    void Function(int received, int total)? onProgress,
  });

  ///取消下载
  void cancelDownload();
}

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
