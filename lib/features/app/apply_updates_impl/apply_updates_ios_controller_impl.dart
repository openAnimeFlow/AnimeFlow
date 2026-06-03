import 'package:anime_flow/features/app/apply_updates_controller.dart';
import 'package:anime_flow/models/download_info.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// iOS 平台更新实现
class ApplyUpdatesIOSController implements ApplyUpdatesController {
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
  }
}
