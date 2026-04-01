import 'dart:async';
import 'dart:io';

import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/play/episode_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/controllers/video/source/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/http/requests/damaku_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
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
  late VideoUiStateController videoUiStateController;
  late VideoStateController videoStateController;
  late EpisodeController episodeController;
  late EpisodesState episodesState;
  late PlaySubjectState subjectState;
  late UserInfoStore userInfoStore;
  late bool _episodesProgress;
  final logger = Logger();
  final _danmuKey = GlobalKey();
  final setting = Storage.setting;

  // 弹幕加载状态
  bool _isLoadingDanmaku = false;
  bool _hasDanmakuLoaded = false;

  //剧集相关
  int _lastEpisodeIndex = 0;

  //视频相关
  Timer? _saveProgressTimer;

  @override
  void initState() {
    super.initState();
    videoStateController = Get.find<VideoStateController>();
    videoUiStateController = Get.find<VideoUiStateController>();
    episodesState = Get.find<EpisodesState>();
    episodeController = Get.find<EpisodeController>();
    subjectState = Get.find<PlaySubjectState>();
    userInfoStore = Get.find<UserInfoStore>();
    _episodesProgress =
        setting.get(PlaybackKey.episodesProgress, defaultValue: true);

    // 监听集数变化
    ever(episodesState.episodeIndex, (int episode) {
      if (episode > 0) {
        if (episode != _lastEpisodeIndex) {
          _hasDanmakuLoaded = false;
          ref.read(videoSourceController.notifier).setUserManuallySelected(false);
          videoStateController.player.stop();
          ref.read(playController.notifier).clearPlaybackSource();
          _parsingState(true);
          _selectResourceAfterInit();
        }
      }
    });

    // 监听视频播放完成
    videoStateController.player.stream.completed.listen((completed) {
      if (completed) {
        _autoSwitchToNextEpisode();
        PlayRepository.deletePlayHistoryByPosition(subjectState.subject.value.id);
      }
    });

    // 监听缓冲状态
    videoStateController.player.stream.buffering.listen((buffering) {
      _updateBufferingState(buffering);
    });

    // 监听窗口状态变化，
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      ref.read(playController.notifier).checkDesktopFullscreen();
    }
  }


  @override
  void dispose() {
    _saveProgressTimer?.cancel();
    _savePlayHistory();
    // 移除窗口监听器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }


  /// 使用 [PlayController] 下发的真实地址驱动 [Player]（解析在 [VideoSourceController.loadVideoPage] 内完成）。
  Future<void> _openAndPlayFromResolvedUrl(String url, int offset) async {
    if (!mounted || url.isEmpty) return;
    try {
      await videoStateController.player.open(Media(url), play: false);
      await videoStateController.player.stream.duration.firstWhere(
        (d) => d > Duration.zero,
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await videoStateController.player.seek(Duration(seconds: offset));
      await videoStateController.player.play();
      _parsingState(false);
      await _loadDanmaku();
      _startProgressTracking();
    } catch (e, st) {
      logger.e('播放启动失败', error: e, stackTrace: st);
      if (mounted) {
        _parsingState(false, failureReason: e.toString());
      }
    }
  }

  //解析状态
  void _parsingState(bool parsing, {String? failureReason}) {
    if (!mounted) return;

    if (parsing) {
      // 开始解析
      videoUiStateController.setParsingTitle('正在解析视频资源...');
      videoUiStateController
          .updateMainAxisAlignmentType(MainAxisAlignment.center);
      videoUiStateController
          .updateIndicatorType(VideoControlsIndicatorType.parsingIndicator);
      videoUiStateController.showIndicator();
    } else if (failureReason != null) {
      // 解析失败
      logger.e('视频解析失败: $failureReason');

      videoUiStateController.setParsingTitle('解析失败：$failureReason');

      // Get.snackbar(
      //   '解析失败',
      //   failureReason,
      //   duration: const Duration(seconds: 3),
      //   backgroundColor: Colors.red.shade100,
      //   colorText: Colors.red.shade900,
      // );

      // 延迟隐藏指示器
      // Future.delayed(const Duration(seconds: 2), () {
      //   if (!mounted) return;
      //   videoUiStateController.hideIndicator();
      //   videoUiStateController
      //       .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
      //   videoUiStateController
      //       .updateMainAxisAlignmentType(MainAxisAlignment.start);
      // });
    } else {
      // 解析成功
      videoUiStateController.setParsingTitle('视频资源解析成功');
      // Future.delayed(const Duration(seconds: 2), () {
      //   if (!mounted) return;
      //   videoUiStateController.hideIndicator();
      //   videoUiStateController
      //       .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
      //   videoUiStateController
      //       .updateMainAxisAlignmentType(MainAxisAlignment.start);
      // });
    }
  }

  /// 加载弹幕
  Future<void> _loadDanmaku() async {
    if (_hasDanmakuLoaded || _isLoadingDanmaku) {
      return;
    }

    _isLoadingDanmaku = true;

    try {
      int episode = episodesState.episodeIndex.value;
      if (episode == 0) {
        _isLoadingDanmaku = false;
        return;
      }

      final bgmBangumiId =
      await DanmakuRequest.getDanDanBangumiIDByBgmBangumiID(
          subjectState.subject.value.id);
      final danmaku = await DanmakuRequest.getDanDanmaku(bgmBangumiId, episode);
      ref.read(playController.notifier).addDanmaku(danmaku);
      logger.i('弹幕数量为：${danmaku.length}');

      // 标记弹幕已加载
      _hasDanmakuLoaded = true;
    } catch (e) {
      logger.e('加载弹幕失败: $e');
    } finally {
      _isLoadingDanmaku = false;
    }
  }

  ///更新缓冲状态
  void _updateBufferingState(bool buffering) {
    if (buffering) {
      videoUiStateController
          .updateIndicatorType(VideoControlsIndicatorType.bufferingIndicator);
      videoUiStateController
          .updateMainAxisAlignmentType(MainAxisAlignment.center);
      videoUiStateController.showIndicator();
    } else {
      if (videoUiStateController.indicatorType.value ==
          VideoControlsIndicatorType.bufferingIndicator) {
        videoUiStateController.hideIndicator();
        videoUiStateController
            .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
      }
    }
  }

  /// 等待资源初始化完成后选择资源
  Future<void> _selectResourceAfterInit() async {
    if (!ref.read(videoSourceController).isLoading) {
      await _waitForResourcesLoaded();
    }

    final resources = ref.read(videoSourceController).videoResources;
    ref.read(videoSourceController.notifier).autoSelectFirstResource(
          resources,
          force: true,
        );
  }

  /// 等待资源加载完成（[VideoSourceState.isLoading] 为 true 表示各站列表已就绪）
  Future<void> _waitForResourcesLoaded() async {
    if (ref.read(videoSourceController).isLoading) {
      return;
    }
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (mounted && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (ref.read(videoSourceController).isLoading) {
        return;
      }
    }
    logger.w('等待资源加载超时');
  }

  /// 播放记录保存和章节进度更新
  void _startProgressTracking() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = null;
    try {
      // 播放时，每5秒保存一次，使用实时获取的进度值
      _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _savePlayHistory();
        /// 播放进度大于90% && collection != null，更新章节进度
        if (_episodesProgress) {
          final position = videoStateController.position.value;
          final duration = videoStateController.duration.value;
          final episodeIndex = episodesState.episodeIndex.value;
          final episodeId = episodesState.episodeId.value;
          if(userInfoStore.userInfo.value != null) {
            final progressPercent = position.inSeconds / duration.inSeconds * 100;
            if (progressPercent > 90) {
              final currentIndex = episodeIndex - 1;
              final episodes = episodesState.episodes.value;
              if (episodes != null &&
                  currentIndex >= 0 &&
                  currentIndex < episodes.data.length &&
                  episodes.data[currentIndex].collection == null) {
                // TODO需要只有登录后才更新
                UserRequest.updateEpisodeProgressService(episodeId,
                    batch: true, type: 2);
                // TODO 同时更新本地剧集进度数据
                logger.i('章节进度已更新: episodeId=$episodeId');
              }
            }
          }
        }
      });
    } catch (e) {
      logger.e('保存播放进度失败: $e');
    }
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
    final position = videoStateController.position.value;
    final duration = videoStateController.duration.value;
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

  /// 窗口恢复时处理
  @override
  void onWindowRestore() {
    ref.read(playController.notifier).checkDesktopFullscreen();
  }

  /// 窗口进入全屏时处理
  @override
  void onWindowEnterFullScreen() {
    ref.read(playController.notifier).updateIsWideScreen(true);
  }

  /// 窗口退出全屏时处理
  @override
  void onWindowLeaveFullScreen() {
    ref.read(playController.notifier).updateIsWideScreen(false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playController, (previous, next) {
      final url = next.videoUrl;
      if (url.isEmpty) return;
      if (previous != null &&
          previous.videoUrl == next.videoUrl &&
          previous.offset == next.offset) {
        return;
      }
      unawaited(_openAndPlayFromResolvedUrl(url, next.offset));
    });

    return Stack(
      children: [
        Video(
          controller: videoStateController.videoController,
          controls: NoVideoControls,
        ),

        /// 弹幕层
        Positioned.fill(
          child: DanmakuView(key: _danmuKey),
        ),

        const Positioned.fill(child: VideoUi()),
      ],
    );
  }
}
