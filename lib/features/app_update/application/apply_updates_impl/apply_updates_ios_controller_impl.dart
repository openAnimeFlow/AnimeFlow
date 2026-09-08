import 'package:anime_flow/features/app_update/application/apply_updates_controller.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// iOS 平台更新实现
class ApplyUpdatesIOSController implements ApplyUpdatesController {
  @override
  bool get supportsInAppDownload => false;

  @override
  List<DownloadInfo> prioritizeDownloads(List<DownloadInfo> downloads) =>
      downloads;

  @override
  Future<void> openDownloadedPackage(String filePath) async {
    throw UnsupportedError('iOS 不支持此操作');
  }

  @override
  Future<UpdateDownloadResult?> applyUpdates({
    required DownloadInfo downloadInfo,
    void Function(int received, int total)? onProgress,
  }) async {
    final authUrl = Uri.parse(downloadInfo.htmlUrl);
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
      return null;
    } else {
      LiggLogger().e('无法打开链接:$authUrl');
      throw 'Could not launch ';
    }
  }

  @override
  void cancelDownload() {}
}
