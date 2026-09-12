import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/media_cache/domain/hls_snapshot.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/core/exception/storage_exception.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RightAreaControl extends ConsumerWidget {
  const RightAreaControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playController = ref.read(playSessionProvider);
    final isShowControlsUi =
        ref.watch(videoUiProvider.select((state) => state.isShowControlsUi));
    final fullscreen =
        ref.watch(playStateProvider.select((s) => s.isFullscreen));
    final position = ref.watch(playStateProvider.select((s) => s.position));
    final isWideScreen =
        ref.watch(playStateProvider.select((s) => s.isWideScreen));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isShowControlsUi
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                key: ValueKey<bool>(isShowControlsUi),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder<MediaCacheIssue>(
                    valueListenable: playController.cacheStatus,
                    builder: (context, status, _) {
                      if (status == MediaCacheIssue.disabled ||
                          status == MediaCacheIssue.localFile) {
                        return const SizedBox.shrink();
                      }
                      final l10n = AppLocalizations.of(context);
                      final message = switch (status) {
                        MediaCacheIssue.ready => l10n.sharedMediaCacheReady,
                        MediaCacheIssue.preparing =>
                          l10n.sharedMediaCachePreparing,
                        MediaCacheIssue.timelineChanged =>
                          l10n.sharedMediaCacheTimeline,
                        MediaCacheIssue.unsupported =>
                          l10n.sharedMediaCacheUnsupported,
                        MediaCacheIssue.capacity =>
                          l10n.sharedMediaCacheCapacity,
                        MediaCacheIssue.sourceChanged =>
                          l10n.sharedMediaCacheChanged,
                        _ => l10n.sharedMediaCacheUnavailable,
                      };
                      return Tooltip(
                          message: message,
                          triggerMode: TooltipTriggerMode.tap,
                          child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Icon(
                                  status == MediaCacheIssue.ready
                                      ? Icons.storage
                                      : Icons.info_outline,
                                  color: status == MediaCacheIssue.ready
                                      ? Colors.greenAccent
                                      : Colors.white70,
                                  size: 24)));
                    },
                  ),
                  position > Duration.zero && (isWideScreen || fullscreen)
                      ? InkWell(
                          onTap: () async {
                            try {
                              final uint8List =
                                  await playController.takeScreenshot();
                              if (uint8List != null) {
                                final message = await SystemUtil.saveImageBytes(
                                  uint8List,
                                  name: 'video_screenshot',
                                );
                                NotificationToast.show(message,
                                    title: '提示',
                                    align: Alignment.topCenter,
                                    maxWidth: 500);
                              } else {
                                NotificationToast.show('截图失败，无法获取截图数据',
                                    align: Alignment.topCenter,
                                    title: '提示',
                                    maxWidth: 500);
                              }
                            } on StoragePermissionDeniedException catch (e) {
                              LiggLogger().e(e);
                              NotificationToast.show(e.message,
                                  title: '提示',
                                  align: Alignment.topCenter,
                                  maxWidth: 500);
                            } catch (e) {
                              LiggLogger().e(e);
                              NotificationToast.show('截图失败: $e',
                                  title: '提示',
                                  align: Alignment.topCenter,
                                  maxWidth: 500);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1,
                                  color: Colors.white10,
                                )),
                            child: const Icon(Icons.camera_alt_outlined,
                                color: Colors.white70, size: 30),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            )
          : SizedBox.shrink(
              key: ValueKey<bool>(isShowControlsUi),
            ),
    );
  }
}
