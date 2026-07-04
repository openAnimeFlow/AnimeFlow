import 'dart:async';
import 'dart:io';

import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/models/play/play_history.dart';
import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/pages/play/controller/video_source_controller.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
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
  late final PlayController playController;
  late final VideoUiStateController videoUiStateController;
  late final VideoSourceController videoSourceController;

  StreamSubscription<bool>? playbackCompletedSubscription;
  int lastEpisodeIndex = 0;
  late final PlayExtra subject;

  EpisodesData episodesSnapshot = const EpisodesData();

  @override
  void initState() {
    super.initState();
    playController = ref.read(playControllerProvider);
    videoUiStateController = ref.read(videoUiStateControllerProvider.notifier);
    videoSourceController = ref.read(videoSourceControllerProvider.notifier);
    subject = ref.read(playExtraProvider).playExtra;
    episodesSnapshot = ref.read(episodesProvider);

    // 监听视频播放完成
    playbackCompletedSubscription =
        playController.player.stream.completed.listen((completed) {
      if (completed) {
        _autoSwitchToNextEpisode();
        PlayRepository.deletePlayHistoryByPosition(
          subject.subjectId,
        );
      }
    });

    // 监听窗口状态变化，
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      // 检测桌面端全屏状态
      playController.checkDesktopFullscreen();
    }
  }

  @override
  void dispose() {
    playbackCompletedSubscription?.cancel();
    _savePlayHistory();
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
    playController.isFullscreen.value = true;
  }

  /// 窗口退出全屏时处理
  @override
  void onWindowLeaveFullScreen() {
    playController.isFullscreen.value = false;
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

  /// 自动切换到下一集
  void _autoSwitchToNextEpisode() {
    try {
      final episodesNotifier = ref.read(episodesProvider.notifier);
      // 检查是否有下一集
      if (episodesNotifier.hasNextEpisode) {
        episodesNotifier.switchToNextEpisode();
        lastEpisodeIndex = ref.read(episodesProvider).episodeIndex;
      }
    } catch (e) {
      LiggLogger().e('自动切换到下一集失败: $e');
    }
  }

  /// 保存播放记录
  void _savePlayHistory() {
    final position = playController.position.value;
    final duration = playController.duration.value;
    if (position == Duration.zero || duration == Duration.zero) return;

    final subjectId = subject.subjectId;
    final episodesState = episodesSnapshot;
    final episodeId = episodesState.episodeId;
    if (subjectId <= 0 || episodeId <= 0) return;

    final playHistory = PlayHistory(
      subjectId: subjectId,
      subjectName: subject.subjectName,
      episodeId: episodeId,
      alias: subject.subjectAliases,
      episodeSort: episodesState.episodeIndex,
      cover: subject.subjectCover,
      updateAt: DateTime.now(),
      position: position.inSeconds,
      duration: duration.inSeconds,
    );
    PlayRepository.savePlayHistory(playHistory);
  }

  @override
  Widget build(BuildContext context) {
    // 缓存最新剧集状态，供 dispose 中安全使用
    ref.listen<EpisodesData>(
      episodesProvider,
      (previous, next) => episodesSnapshot = next,
    );
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
        ValueListenableBuilder<BoxFit>(
          valueListenable: playController.videoFit,
          builder: (context, videoFit, _) => Video(
            controller: playController.videoController,
            fit: videoFit,
            controls: NoVideoControls,
          ),
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
