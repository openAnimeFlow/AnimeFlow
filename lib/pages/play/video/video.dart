import 'dart:async';
import 'dart:io';

import 'package:anime_flow/models/play/play_history.dart';
import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:anime_flow/pages/play/controller/episode_controller.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_source_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/pages/play/provider/play_subject_provider.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
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
  final videoUiStateController = Get.find<VideoUiStateController>();
  final videoSourceController = Get.find<VideoSourceController>();
  final episodeController = Get.find<EpisodeController>();
  final playController = Get.find<PlayController>();
  final episodesState = Get.find<EpisodesState>();
  final logger = LiggLogger();
  final _danmuKey = GlobalKey();

  Worker? episodeIndexWorker;
  StreamSubscription<bool>? playbackCompletedSubscription;
  int lastEpisodeIndex = 0;
  late final PlayExtra subject;

  @override
  void initState() {
    super.initState();
    subject = ref.read(playSubjectProvider);

    // 监听集数变化
    episodeIndexWorker = ever(episodesState.episodeIndex, (int episode) {
      if (episode > 0 && episode != lastEpisodeIndex) {
        videoSourceController.userManuallySelected = false;
        playController.player.stop();
        _selectResourceAfterInit();
      }
    });

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

  /// 等待资源初始化完成后选择资源
  Future<void> _selectResourceAfterInit() async {
    if (!videoSourceController.isLoading.value) {
      await _waitForResourcesLoaded();
    }

    final resources = videoSourceController.videoResources.toList();
    videoSourceController.autoSelectFirstResource(resources, force: true);
  }

  /// 等待资源加载完成
  Future<void> _waitForResourcesLoaded() async {
    if (videoSourceController.isLoading.value) {
      return;
    }

    final completer = Completer<void>();
    late Worker worker;

    worker = ever(videoSourceController.isLoading, (bool isLoading) {
      if (isLoading) {
        worker.dispose();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    Future.delayed(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        worker.dispose();
        completer.complete();
        logger.w('等待资源加载超时');
      }
    });

    return completer.future;
  }

  /// 自动切换到下一集
  void _autoSwitchToNextEpisode() {
    try {
      // 检查是否有下一集
      if (episodeController.hasNextEpisode(episodesState)) {
        episodeController.switchToNextEpisode(episodesState);
        lastEpisodeIndex = episodesState.episodeIndex.value;
      }
    } catch (e) {
      logger.e('自动切换到下一集失败: $e');
    }
  }

  /// 保存播放记录
  void _savePlayHistory() {
    final position = playController.position.value;
    final duration = playController.duration.value;
    if (position == Duration.zero || duration == Duration.zero) return;

    final subjectId = subject.subjectId;
    final episodeId = episodesState.episodeId.value;
    if (subjectId <= 0 || episodeId <= 0) return;

    final playHistory = PlayHistory(
      subjectId: subjectId,
      subjectName: subject.subjectName,
      episodeId: episodeId,
      alias: subject.subjectAliases,
      episodeSort: episodesState.episodeIndex.value,
      cover: subject.subjectCover,
      updateAt: DateTime.now(),
      position: position.inSeconds,
      duration: duration.inSeconds,
    );
    PlayRepository.savePlayHistory(playHistory);
  }

  @override
  void dispose() {
    episodeIndexWorker?.dispose();
    playbackCompletedSubscription?.cancel();
    videoSourceController.cancelVideoSourceResolution();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 视频层
        Video(
          controller: playController.videoController,
          controls: NoVideoControls,
        ),

        /// 弹幕层
        Positioned.fill(
          child: DanmakuView(key: _danmuKey),
        ),
        /// UI层
        const Positioned.fill(child: VideoUi()),
      ],
    );
  }
}
