import 'dart:async';
import 'dart:io';

import 'package:anime_flow/controllers/play/episode_controller.dart';
import 'package:anime_flow/models/play/play_history.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/controllers/video/source/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/danmaku/danmaku_view.dart';
import 'ui/index.dart';

class VideoView extends StatefulWidget {
  const VideoView({super.key});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> with WindowListener {
  final VideoUiStateController videoUiStateController = Get.find<VideoUiStateController>();
  final VideoSourceController videoSourceController = Get.find<VideoSourceController>();
  final EpisodeController episodeController = Get.find<EpisodeController>();
  final PlayController playController = Get.find<PlayController>();
  final EpisodesState episodesState = Get.find<EpisodesState>();
  final PlaySubjectState subjectState = Get.find<PlaySubjectState>();
  final UserInfoStore userInfoStore = Get.find<UserInfoStore>();
  final logger = Logger();
  final _danmuKey = GlobalKey();
  final setting = Storage.setting;

  /// 解析结果
  StreamSubscription<(String, int)>? _videoURLSubscription;

  StreamSubscription<bool>? _videoLoadingSubscription;
  StreamSubscription<String>? _logSubscription;
  StreamSubscription<bool>? _initSubscription;

  Timer? _parseTimeoutTimer;

  //剧集相关
  int _lastEpisodeIndex = 0;

  //视频相关
  Timer? _saveProgressTimer;

  @override
  void initState() {
    super.initState();

    // 监听集数变化
    ever(episodesState.episodeIndex, (int episode) {
      if (episode > 0) {
        if (episode != _lastEpisodeIndex) {
          videoSourceController.userManuallySelected = false;
          playController.player.stop();
          _selectResourceAfterInit();
        }
      }
    });

    // 监听视频播放完成
    playController.player.stream.completed.listen((completed) {
      if (completed) {
        _autoSwitchToNextEpisode();
        PlayRepository.deletePlayHistoryByPosition(subjectState.subject.value.id);
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
        _lastEpisodeIndex = episodesState.episodeIndex.value;
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

    final subjectId = subjectState.subject.value.id;
    final episodeId = episodesState.episodeId.value;
    if (subjectId <= 0 || episodeId <= 0) return;

    final playHistory = PlayHistory(
      subjectId: subjectId,
      subjectName: subjectState.subject.value.name,
      episodeId: episodeId,
      episodeSort: episodesState.episodeIndex.value,
      cover: subjectState.subject.value.image,
      updateAt: DateTime.now(),
      position: position.inSeconds,
      duration: duration.inSeconds,
    );
    PlayRepository.savePlayHistory(playHistory);
  }

  @override
  void dispose() {
    _parseTimeoutTimer?.cancel();
    _videoURLSubscription?.cancel();
    _videoLoadingSubscription?.cancel();
    _logSubscription?.cancel();
    _saveProgressTimer?.cancel();
    _initSubscription?.cancel();
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
