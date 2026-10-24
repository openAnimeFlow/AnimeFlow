import 'package:anime_flow/shared/models/download_info.dart';

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
  Future<List<DownloadInfo>> prioritizeDownloads(List<DownloadInfo> downloads);

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
