import 'dart:io';
import 'package:anime_flow/shared/models/download_info.dart';

import 'apply_updates_impl/apply_updates_android_controller_impl.dart';
import 'apply_updates_impl/apply_updates_ios_controller_impl.dart';
import 'apply_updates_impl/apply_updates_linux_controller_impl.dart';
import 'apply_updates_impl/apply_updates_macos_controller_impl.dart';
import 'apply_updates_impl/apply_updates_windows_controller_impl.dart';

enum DownloadedPackageAction { runInstaller, openFolder }

class UpdateDownloadResult {
  final String filePath;
  final DownloadedPackageAction action;

  const UpdateDownloadResult({required this.filePath, required this.action});
}

abstract class ApplyUpdatesController {
  /// 是否在应用内执行下载并展示进度。
  bool get supportsInAppDownload;

  /// 按平台策略排列可用的下载包。
  List<DownloadInfo> prioritizeDownloads(List<DownloadInfo> downloads);

  /// 处理下载完成后的平台动作，例如运行安装包或打开所在目录。
  Future<void> openDownloadedPackage(String filePath);

  ///应用更新
  /// [downloadUrl] 下载地址
  /// [onProgress] 下载进度回调，参数为 (已下载字节数, 总字节数)
  /// 执行更新。Windows 下载完成后返回安装包路径，其他平台返回 null。
  Future<UpdateDownloadResult?> applyUpdates({
    required DownloadInfo downloadInfo,
    void Function(int received, int total)? onProgress,
  });

  ///取消下载
  void cancelDownload();
}

class UpdateDownloadCancelledException implements Exception {
  const UpdateDownloadCancelledException();

  @override
  String toString() => '下载已取消';
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
