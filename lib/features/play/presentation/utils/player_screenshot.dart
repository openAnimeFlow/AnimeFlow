import 'package:anime_flow/core/exception/storage_exception.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 截取当前播放画面。
///
/// 截图成功后立即在播放器右下角弹出缩略图（自动隐藏、可点击预览），
/// 同时把图片保存到相册/下载目录。
Future<void> capturePlayerScreenshot(
  BuildContext context,
  WidgetRef ref,
) async {
  final playController = ref.read(playSessionProvider);
  final videoUi = ref.read(videoUiProvider.notifier);
  try {
    final bytes = await playController.takeScreenshot();
    if (bytes == null) {
      if (!context.mounted) return;
      NotificationToast.show(
        '截图失败，无法获取截图数据',
        align: Alignment.topCenter,
        title: '提示',
        maxWidth: 500,
      );
      return;
    }

    // 先展示缩略图，避免保存权限弹窗延迟预览。
    videoUi.showScreenshotPreview(bytes);

    final message = await SystemUtil.saveImageBytes(
      bytes,
      name: 'video_screenshot',
    );
    if (!context.mounted) return;
    NotificationToast.show(
      message,
      title: '提示',
      align: Alignment.topCenter,
      maxWidth: 500,
    );
  } on StoragePermissionDeniedException catch (e) {
    LiggLogger().e(e);
    if (!context.mounted) return;
    NotificationToast.show(
      e.message,
      title: '提示',
      align: Alignment.topCenter,
      maxWidth: 500,
    );
  } catch (e) {
    LiggLogger().e(e);
    if (!context.mounted) return;
    NotificationToast.show(
      '截图失败: $e',
      title: '提示',
      align: Alignment.topCenter,
      maxWidth: 500,
    );
  }
}
