import 'package:anime_flow/core/exception/storage_exception.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 截取当前播放画面。
///
/// 截图成功后立即在播放器右下角弹出缩略图（自动隐藏、可点击预览），
/// 同时把图片保存到相册/下载目录。
Future<void> capturePlayerScreenshot(
  BuildContext context,
  WidgetRef ref, {
  bool notify = true,
}) async {
  final playController = ref.read(playSessionProvider);
  final videoUi = ref.read(videoUiProvider.notifier);

  void notifyUser(String message) {
    if (!notify || !context.mounted) return;
    NotificationToast.show(
      message,
      title: '提示',
      align: Alignment.topCenter,
      maxWidth: 500,
    );
  }

  try {
    final bytes = await playController.takeScreenshot();
    if (bytes == null) {
      notifyUser('截图失败，无法获取截图数据');
      return;
    }

    // 先展示缩略图，避免保存权限弹窗延迟预览。
    videoUi.showScreenshotPreview(bytes);

    final message = await SystemUtil.saveImageBytes(
      bytes,
      name: 'video_screenshot',
    );
    notifyUser(message);
  } on StoragePermissionDeniedException catch (e) {
    LiggLogger().e(e);
    notifyUser(e.message);
  } catch (e) {
    LiggLogger().e(e);
    notifyUser('截图失败: $e');
  }
}
