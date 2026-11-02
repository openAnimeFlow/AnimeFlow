import 'package:anime_flow/features/app_update/application/apply_updates_controller.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// macOS 平台更新实现
class ApplyUpdatesMacOSController implements ApplyUpdatesController {
  @override
  bool get supportsInAppDownload => false;

  @override
  Future<List<DownloadInfo>> prioritizeDownloads(
          List<DownloadInfo> downloads) =>
      Future.value(downloads);

  @override
  Future<void> openDownloadedPackage(String filePath) async {
    throw UnsupportedError('macOS 不支持此操作');
  }

  @override
  Future<UpdateDownloadResult?> applyUpdates({
    required DownloadInfo downloadInfo,
    void Function(int received, int total)? onProgress,
  }) async {
    final downloadUrl = Uri.parse(downloadInfo.url);
    if (!await launchUrl(downloadUrl, mode: LaunchMode.externalApplication)) {
      LiggLogger().e('无法打开下载链接:$downloadUrl');
      throw StateError('无法打开下载链接');
    }
    return null;
  }

  @override
  void cancelDownload() {
    // TODO: 实现 macOS 平台取消下载逻辑
  }
}
