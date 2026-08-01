import 'package:anime_flow/core/apply_update/apply_updates_controller.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// macOS 平台更新实现
class ApplyUpdatesMacOSController implements ApplyUpdatesController {
  @override
  Future<void> applyUpdates({
    required DownloadInfo downloadInfo,
    void Function(int received, int total)? onProgress,
  }) async {
    final authUrl = Uri.parse(downloadInfo.htmlUrl);
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
    } else {
      LiggLogger().e('无法打开链接:$authUrl');
      throw 'Could not launch ';
    }
  }

  @override
  void cancelDownload() {
    // TODO: 实现 macOS 平台取消下载逻辑
  }
}
