import 'dart:async';
import 'dart:io';

import 'package:anime_flow/controllers/play/episode_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/webview/webview_item.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/stores/subject_state.dart';
import 'package:anime_flow/controllers/video/data/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/http/requests/damaku.dart';
import 'package:anime_flow/widget/video/ui/danmaku/danmaku_view.dart';
import 'package:anime_flow/widget/video/ui/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class VideoView extends StatefulWidget {
  const VideoView({super.key});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> with WindowListener {
  late final player = Player();
  late final controller = VideoController(player);
  late VideoUiStateController videoUiStateController;
  late VideoSourceController videoSourceController;
  late PlayController playController;
  late EpisodesState episodesState;
  late EpisodeController episodeController;
  late SubjectState subjectState;
  late VideoStateController videoStateController;
  final webviewItemController = Get.find<WebviewItemController>();
  final logger = Logger();
  final _danmuKey = GlobalKey();

  // 弹幕加载状态
  bool _isLoadingDanmaku = false;
  bool _hasDanmakuLoaded = false;

  StreamSubscription<bool>? _initSubscription;
  StreamSubscription<(String, int)>? _videoURLSubscription;
  StreamSubscription<bool>? _videoLoadingSubscription;
  StreamSubscription<String>? _logSubscription;

  // 解析状态跟踪
  bool _isParsing = false;
  bool _hasReceivedVideoUrl = false;
  Timer? _parseTimeoutTimer;

  //剧集相关
  int _lastEpisodeIndex = 0;

  //视频相关
  Timer? _saveProgressTimer;

  @override
  void initState() {
    super.initState();
    videoStateController = Get.put(VideoStateController(player));
    videoSourceController = Get.find<VideoSourceController>();
    videoUiStateController = Get.put(VideoUiStateController(player));
    playController = Get.find<PlayController>();
    episodesState = Get.find<EpisodesState>();
    episodeController = Get.find<EpisodeController>();
    subjectState = Get.find<SubjectState>();
    // 初始化屏幕亮度
    videoUiStateController.initializeBrightness();

    // 监听集数变化
    ever(episodesState.episodeIndex, (int episode) {
      if (episode > 0) {
        _hasDanmakuLoaded = false;
        // 清空之前的弹幕
        playController.removeDanmaku();
        if (episode != _lastEpisodeIndex) {
           player.stop();
          _selectResourceAfterInit();
        }
      }
    });

    // 监听视频播放完成
    player.stream.completed.listen((completed) {
      if (completed) {
        _autoSwitchToNextEpisode();
        PlayRepository.deletePlayPosition(
            '${subjectState.id}${episodesState.episodeId.value}');
      }
    });

    // 监听缓冲状态
    player.stream.buffering.listen((buffering) {
      _updateBufferingState(buffering);
    });

    // 初始化 WebView 并监听视频URL解析结果
    _initWebview();

    // 监听窗口状态变化，
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      // 检测桌面端全屏状态
      playController.checkDesktopFullscreen();
    }
  }

  Future<void> _initWebview() async {
    // 监听解析结果
    _videoURLSubscription =
        webviewItemController.onVideoURLParser.listen((result) async {
      final (url, offset) = result;
      logger.i('WebView解析到视频URL: $url, 偏移: $offset');

      // 标记已收到视频URL
      _hasReceivedVideoUrl = true;
      _parseTimeoutTimer?.cancel();

      if (url.isNotEmpty) {
        await player.open(
          Media(url, start: Duration(seconds: offset)),
        );
      }
    });

    // 监听视频解析状态
    _videoLoadingSubscription =
        webviewItemController.onVideoLoading.listen((loading) {
      _isParsing = loading;

      if (loading) {
        // 开始解析，重置状态并启动超时计时器
        _hasReceivedVideoUrl = false;
        _parseTimeoutTimer?.cancel();
        _parseTimeoutTimer = Timer(const Duration(seconds: 16), () {
          // 16秒超时（比WebView内部的15秒稍长，确保能收到日志）
          if (!_hasReceivedVideoUrl && _isParsing) {
            _parsingState(false, failureReason: '解析超时');
          }
        });
      } else {
        // 解析结束，取消超时计时器
        _parseTimeoutTimer?.cancel();

        // 如果解析结束但没有收到视频URL，说明解析失败
        if (!_hasReceivedVideoUrl && _isParsing) {
          _parsingState(false, failureReason: '未获取到有效的视频URL');
        } else {
          // 解析成功
          _parsingState(false);
          // 视频解析成功后加载弹幕
          _loadDanmaku();
          // 保存进度
          _savePlaybackProgress();
        }
      }

      // 只在开始解析时调用，结束时的处理在上面已经完成
      if (loading) {
        _parsingState(true);
      }
    });

    // 监听日志消息（检测解析超时）
    _logSubscription = webviewItemController.onLog.listen((logMessage) {
      // 检测解析超时消息
      if (logMessage.contains('解析视频资源超时')) {
        _parsingState(false, failureReason: '解析超时：$logMessage');
      } else if (logMessage.contains('请切换到其他播放列表或视频源')) {
        logger.w('解析失败提示: $logMessage');
      }
    });
    // 如果webview尚未初始化，则初始化
    if (webviewItemController.webviewController == null) {
      _initSubscription =
          webviewItemController.onInitialized.listen((initialized) {
        if (initialized) {
          logger.i('WebView初始化完成');
        }
      });
      await webviewItemController.init();
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

      // 显示错误提示
      Get.snackbar(
        '解析失败',
        failureReason,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );

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
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        videoUiStateController.hideIndicator();
        videoUiStateController
            .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
        videoUiStateController
            .updateMainAxisAlignmentType(MainAxisAlignment.start);
      });
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
              subjectState.subjectId.value);
      final danmaku = await DanmakuRequest.getDanDanmaku(bgmBangumiId, episode);
      playController.addDanmaku(danmaku);
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
    Get.log('缓冲状态: $buffering');
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

  ///保存播放进度
  void _savePlaybackProgress() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = null;
    final subjectId = subjectState.id;
    final episodeId = episodesState.episodeId.value;
    try {
      // 播放时，每5秒保存一次，使用实时获取的进度值
      _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final position = videoStateController.position.value;
        final duration = videoStateController.duration.value;
        if (position == Duration.zero || duration == Duration.zero) {
          return;
        }
        if (subjectId <= 0 || episodeId <= 0) return;
        final playId = '$subjectId$episodeId';
        PlayRepository.savePlayPosition(playId, position, duration);

        // 播放进度大于90% && collection != null，更新章节进度
        final progressPercent = position.inSeconds / duration.inSeconds * 100;
        if (progressPercent > 90) {
          final currentIndex = episodesState.episodeIndex.value - 1;
          final episodes = episodesState.episodes.value;
          if (episodes != null &&
              currentIndex >= 0 &&
              currentIndex < episodes.data.length &&
              episodes.data[currentIndex].collection == null) {
             UserRequest.updateEpisodeProgressService(episodeId,
                batch: true, type: 2);
             // TODO 同时更新本地剧集进度数据
            logger.i('章节进度已更新: episodeId=$episodeId');
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

  @override
  void dispose() {
    _parseTimeoutTimer?.cancel();
    _initSubscription?.cancel();
    _videoURLSubscription?.cancel();
    _videoLoadingSubscription?.cancel();
    _logSubscription?.cancel();
    _saveProgressTimer?.cancel();
    // 移除窗口监听器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    _savePlaybackProgress();
    Get.delete<VideoUiStateController>();
    Get.delete<VideoStateController>();
    player.dispose();
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
        Video(
          controller: controller,
          controls: NoVideoControls,
        ),

        /// 弹幕层
        Positioned.fill(
          child: DanmakuView(key: _danmuKey),
        ),

        const Positioned.fill(child: VideoUi()),

        /// webview_windows 的窗口必须嵌入到 Widget 树中才能被控制
        /// 通过 SizedBox 的 height 为 0 来隐藏它，但保持其在 Widget 树中(Kazumi)
        if (Platform.isWindows || Platform.isLinux)
          const Positioned(
            child: SizedBox(
              height: 0,
              child: WebviewItem(),
            ),
          ),
      ],
    );
  }
}
