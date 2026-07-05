import 'dart:async';
import 'dart:io';

import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:anime_flow/pages/play/providers/video_source_provider.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/danmaku/danmaku_view.dart';
import 'ui/index.dart';

class VideoView extends ConsumerStatefulWidget {
  const VideoView({super.key});

  @override
  ConsumerState<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends ConsumerState<VideoView> with WindowListener {
  late final PlaySession playController;
  late final PlayStateNotifier playStateController;
  late final VideoUiStateController videoUiStateController;
  late final VideoSourceController videoSourceController;
  int lastEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    playController = ref.read(playSessionProvider);
    playStateController = ref.read(playStateProvider.notifier);
    videoUiStateController = ref.read(videoUiStateControllerProvider.notifier);
    videoSourceController = ref.read(videoSourceControllerProvider.notifier);

    // 监听窗口状态变化，
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      // 检测桌面端全屏状态
      playController.checkDesktopFullscreen();
    }
  }

  @override
  void dispose() {
    // 移除窗口监听器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  /// 窗口恢复时处理
  @override
  void onWindowRestore() {
    playController.checkDesktopFullscreen();
  }

  /// 窗口进入全屏时处理
  @override
  void onWindowEnterFullScreen() {
    playStateController.setIsFullscreen(true);
  }

  /// 窗口退出全屏时处理
  @override
  void onWindowLeaveFullScreen() {
    playStateController.setIsFullscreen(false);
  }

  /// 等待资源初始化完成后选择资源
  Future<void> selectResourceAfterInit() async {
    if (!ref.read(videoSourceControllerProvider).isLoading) {
      await waitForResourcesLoaded();
    }

    final resources = ref.read(videoSourceControllerProvider).videoResources;
    videoSourceController.autoSelectFirstResource(resources, force: true);
    videoUiStateController
        .updateIndicatorType(VideoControlsIndicatorType.parsingIndicator);
    videoUiStateController
        .updateMainAxisAlignmentType(MainAxisAlignment.center);
    videoUiStateController.showIndicator();
  }

  /// 等待资源搜索完成。
  ///
  /// 注意：[VideoSourceController.isLoading] 表示「资源已就绪」（命名历史遗留），
  /// 为 `true` 时表示搜索完成，而非正在加载。
  Future<void> waitForResourcesLoaded() async {
    if (ref.read(videoSourceControllerProvider).isLoading) {
      return;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!ref.read(videoSourceControllerProvider).isLoading) {
      if (DateTime.now().isAfter(deadline)) {
        LiggLogger().w('等待资源加载超时');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听集数变化：首次设置或切换集数时重新选择资源
    ref.listen<int>(
      episodesProvider.select((state) => state.episodeIndex),
      (previous, episode) {
        if (episode <= 0 || episode == lastEpisodeIndex) {
          return;
        }
        lastEpisodeIndex = episode;
        // 首次设置集数时无需停止播放或清弹幕
        if (previous != null && previous > 0) {
          playController.clearDanmakuIfEpisodeMismatch(episode);
          videoSourceController.resetManualSelection();
          playController.player.stop();
        }
        selectResourceAfterInit();
      },
    );
    return Stack(
      children: [
        /// 视频层
        Consumer(
          builder: (context, ref, child) {
            final videoFit = ref.watch(
                playStateProvider.select((state) => state.videoFit));
            return Video(
              controller: playController.videoController,
              fit: videoFit,
              controls: NoVideoControls,
            );
          },
        ),

        /// 弹幕层
        const Positioned.fill(
          child: DanmakuView(),
        ),

        /// UI层
        const Positioned.fill(child: VideoUi()),
      ],
    );
  }
}
