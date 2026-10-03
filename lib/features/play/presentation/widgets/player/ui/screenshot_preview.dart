import 'dart:typed_data';

import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 播放器右下角的截图缩略图。
///
/// 截图成功后短暂展示，到期自动隐藏；展示期间点击进入大图预览。
/// 需要作为 [Stack] 的子节点使用（内部返回 [Positioned]）。
class ScreenshotPreviewOverlay extends ConsumerWidget {
  const ScreenshotPreviewOverlay({super.key});

  /// 缩略图最大尺寸。
  static const Size _maxThumbnailSize = Size(160, 90);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(
      videoUiProvider.select((state) => state.screenshotPreviewBytes),
    );
    final isWideScreen =
        ref.watch(playStateProvider.select((state) => state.isWideScreen));
    final fullscreen =
        ref.watch(playStateProvider.select((state) => state.isFullscreen));
    // 抬高到底部控件栏之上；宽屏/全屏多一行进度条，需要更高的偏移。
    final bottomOffset = isWideScreen || fullscreen ? 108.0 : 80.0;

    return Positioned(
      right: 12,
      bottom: bottomOffset,
      child: IgnorePointer(
        ignoring: bytes == null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ),
          child: bytes == null
              ? const SizedBox.shrink(key: ValueKey('screenshot-preview-empty'))
              : _ScreenshotThumbnail(bytes: bytes),
        ),
      ),
    );
  }
}

class _ScreenshotThumbnail extends ConsumerWidget {
  const _ScreenshotThumbnail({required this.bytes});

  final Uint8List bytes;

  void _openPreview(BuildContext context, WidgetRef ref) {
    ref.read(videoUiProvider.notifier).hideScreenshotPreview();
    ImagePreviewRoute.fromArgs(
      ImageViewerRouteArgs.bytes(bytes),
    ).push(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openPreview(context, ref),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white24,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ScreenshotPreviewOverlay._maxThumbnailSize.width,
              maxHeight: ScreenshotPreviewOverlay._maxThumbnailSize.height,
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}
