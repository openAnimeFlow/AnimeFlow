import 'dart:async';
import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/models/play/play_history.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/utils/vibrate.dart';
import 'package:anime_flow/widget/windows_title_bar.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'play_controller.g.dart';

@Riverpod(
  keepAlive: true,
  dependencies: [
    shadersDirectory,
    PlayStateController,
    VideoUiStateController,
    playExtra,
  ],
)
PlayController playController(Ref ref) {
  ref.watch(playExtraProvider);
  final controller = PlayController(
    shadersDirectory: ref.watch(shadersDirectoryProvider).requireValue,
    playStateActions: ref.watch(playStateControllerProvider.notifier),
    videoUiStateActions: ref.watch(videoUiStateControllerProvider.notifier),
  )..init();

  ref.listen<PlayControllerState>(
    playStateControllerProvider,
    (previous, next) => controller.handlePlayStateChanged(next),
  );
  ref.onDispose(controller.dispose);

  return controller;
}

@Riverpod(keepAlive: true, dependencies: [playExtra])
class PlayStateController extends _$PlayStateController {
  @override
  PlayControllerState build() {
    ref.watch(playExtraProvider);
    return PlayControllerState(
      danmakuOn: Storage.setting.get(DanmakuKey.danmakuOn, defaultValue: true),
      hiddenPlatforms: _loadHiddenPlatformsFromStorage(),
    );
  }

  PlayControllerState get value => state;

  void setSuperResolutionType(int value) {
    state = state.copyWith(superResolutionType: value);
  }

  void setIsWideScreen(bool value) {
    if (state.isWideScreen == value) return;
    state = state.copyWith(isWideScreen: value);
  }

  void toggleContentExpanded() {
    state = state.copyWith(isContentExpanded: !state.isContentExpanded);
  }

  void setIsFullscreen(bool value) {
    state = state.copyWith(isFullscreen: value);
  }

  void setVideoFit(BoxFit value) {
    if (state.videoFit == value) return;
    state = state.copyWith(videoFit: value);
  }

  void setIsParsing(bool value) {
    state = state.copyWith(isParsing: value);
  }

  void setParseResult(String value) {
    state = state.copyWith(parseResult: value);
  }

  void setDanDanmakus(Map<int, List<Danmaku>> value) {
    state = state.copyWith(danDanmakus: value);
  }

  void clearDanDanmakus() {
    state = state.copyWith(danDanmakus: const {});
  }

  void toggleDanmakuOn() {
    state = state.copyWith(danmakuOn: !state.danmakuOn);
  }

  void setHiddenPlatforms(Set<String> value) {
    state = state.copyWith(hiddenPlatforms: value);
  }

  void toggleHiddenPlatform(String platform) {
    final nextHiddenPlatforms = {...state.hiddenPlatforms};
    if (nextHiddenPlatforms.contains(platform)) {
      nextHiddenPlatforms.remove(platform);
    } else {
      nextHiddenPlatforms.add(platform);
    }
    state = state.copyWith(hiddenPlatforms: nextHiddenPlatforms);
  }

  void setPlaying(bool value) {
    state = state.copyWith(playing: value);
  }

  void setPosition(Duration value) {
    state = state.copyWith(position: value);
  }

  void setDuration(Duration value) {
    state = state.copyWith(duration: value);
  }

  void setBuffered(Duration value) {
    state = state.copyWith(buffered: value);
  }

  void setVolume(double value) {
    state = state.copyWith(volume: value);
  }

  void setIsVerticalDragging(bool value) {
    state = state.copyWith(isVerticalDragging: value);
  }

  void setRate(double value) {
    state = state.copyWith(rate: value);
  }

  void setBuffering(bool value) {
    state = state.copyWith(buffering: value);
  }

  void setScheduledStopDuration(int value) {
    state = state.copyWith(scheduledStopDuration: value);
  }
}

Set<String> _loadHiddenPlatformsFromStorage() {
  final setting = Storage.setting;
  final platformBilibili =
      setting.get(DanmakuKey.danmakuPlatformBilibili, defaultValue: true);
  final platformGamer =
      setting.get(DanmakuKey.danmakuPlatformGamer, defaultValue: true);
  final platformDanDanPlay =
      setting.get(DanmakuKey.danmakuPlatformDanDanPlay, defaultValue: true);

  const platformNameBilibili = 'BiliBili';
  const platformNameGamer = 'Gamer';
  const platformNameDanDanPlay = '弹弹Play';

  return {
    if (!platformBilibili) platformNameBilibili,
    if (!platformGamer) platformNameGamer,
    if (!platformDanDanPlay) platformNameDanDanPlay,
  };
}

class PlayControllerState {
  final int superResolutionType;
  final bool isWideScreen;
  final bool isContentExpanded;
  final bool isFullscreen;
  final BoxFit videoFit;
  final bool isParsing;
  final String parseResult;
  final Map<int, List<Danmaku>> danDanmakus;
  final bool danmakuOn;
  final Set<String> hiddenPlatforms;
  final bool playing;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final double volume;
  final bool isVerticalDragging;
  final double rate;
  final bool buffering;
  final int scheduledStopDuration;

  const PlayControllerState({
    this.superResolutionType = 0,
    this.isWideScreen = false,
    this.isContentExpanded = true,
    this.isFullscreen = false,
    this.videoFit = BoxFit.contain,
    this.isParsing = false,
    this.parseResult = '',
    this.danDanmakus = const {},
    this.danmakuOn = true,
    this.hiddenPlatforms = const {},
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.volume = 100.0,
    this.isVerticalDragging = false,
    this.rate = 1.0,
    this.buffering = false,
    this.scheduledStopDuration = 0,
  });

  PlayControllerState copyWith({
    int? superResolutionType,
    bool? isWideScreen,
    bool? isContentExpanded,
    bool? isFullscreen,
    BoxFit? videoFit,
    bool? isParsing,
    String? parseResult,
    Map<int, List<Danmaku>>? danDanmakus,
    bool? danmakuOn,
    Set<String>? hiddenPlatforms,
    bool? playing,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    double? volume,
    bool? isVerticalDragging,
    double? rate,
    bool? buffering,
    int? scheduledStopDuration,
  }) {
    return PlayControllerState(
      superResolutionType: superResolutionType ?? this.superResolutionType,
      isWideScreen: isWideScreen ?? this.isWideScreen,
      isContentExpanded: isContentExpanded ?? this.isContentExpanded,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      videoFit: videoFit ?? this.videoFit,
      isParsing: isParsing ?? this.isParsing,
      parseResult: parseResult ?? this.parseResult,
      danDanmakus: danDanmakus ?? this.danDanmakus,
      danmakuOn: danmakuOn ?? this.danmakuOn,
      hiddenPlatforms: hiddenPlatforms ?? this.hiddenPlatforms,
      playing: playing ?? this.playing,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      volume: volume ?? this.volume,
      isVerticalDragging: isVerticalDragging ?? this.isVerticalDragging,
      rate: rate ?? this.rate,
      buffering: buffering ?? this.buffering,
      scheduledStopDuration:
          scheduledStopDuration ?? this.scheduledStopDuration,
    );
  }
}

class PlayState {
  /// 播放地址
  final String videoUrl;

  /// 播放偏移
  final int offset;

  /// 番剧id
  final int subjectId;

  ///番剧名称
  final String subjectName;

  ///番剧封面
  final String subjectCover;

  /// 别名
  final List<String> alias;

  /// 集数
  final int episodeIndex;

  ///剧集id
  final int episodeId;

  const PlayState({
    required this.videoUrl,
    required this.offset,
    required this.subjectId,
    required this.episodeIndex,
    required this.episodeId,
    required this.subjectName,
    required this.subjectCover,
    required this.alias,
  });
}

class PlayController {
  PlayController({
    required this.shadersDirectory,
    required PlayStateController playStateActions,
    required VideoUiStateActions videoUiStateActions,
  })  : _playStateActions = playStateActions,
        _videoUiStateActions = videoUiStateActions;

  late Player player;
  late VideoController videoController;
  final PlayStateController _playStateActions;
  final VideoUiStateActions _videoUiStateActions;
  final setting = Storage.setting;

  /// 着色器所在目录（由 [shadersDirectoryProvider] 在启动时准备）
  final Directory shadersDirectory;

  /// 视频地址
  String? videoUrl;

  /// 番剧名称
  String? animeTitle;

  /// 视频偏移
  int offset = 0;

  /// 番剧id
  int subjectId = 0;

  String? subjectCover;

  List<String> alias = [];

  String? subjectName;

  /// 当前集数索引
  int episode = 0;

  ///剧集id
  int episodeId = 0;

  ///弹幕相关
  late DanmakuController danmakuController;
  Timer? _saveSettingsTimer;

  /// 记录原始倍速
  double _originalSpeed = 1.0;

  /// 垂直拖动相关
  double _dragStartVolume = 100.0;

  /// 定时停止播放的计时器
  Timer? _stopTimer;

  /// 弹幕相关
  bool _isLoadingDanmaku = false;

  int? _lastSavedPositionSeconds;
  bool _isSavingPlayHistory = false;

  final List<StreamSubscription<Object?>> _playerSubscriptions = [];

  void init() {
    final adBlocker = setting.get(PlaybackKey.adBlocker, defaultValue: false);
    player = Player(configuration: PlayerConfiguration(adBlocker: adBlocker));
    videoController = VideoController(player);

    _playerSubscriptions.addAll([
      player.stream.playing.listen((playing) {
        _playStateActions.setPlaying(playing);
        _syncDanmakuPauseWithPlayback(playing);
      }),
      player.stream.volume.listen((vol) {
        _playStateActions.setVolume(vol);
      }),
      player.stream.buffer.listen((buffered) {
        _playStateActions.setBuffered(buffered);
      }),
      player.stream.buffering.listen((buffering) {
        _playStateActions.setBuffering(buffering);
        _updateBufferingState(buffering);
      }),
      player.stream.rate.listen((r) {
        _playStateActions.setRate(r);
      }),
      player.stream.position.listen((pos) {
        _playStateActions.setPosition(pos);
      }),
      player.stream.duration.listen((dur) {
        _playStateActions.setDuration(dur);
      }),
      player.stream.completed.listen((completed) {
        if (completed && subjectId > 0) {
          unawaited(PlayRepository.deletePlayHistoryByPosition(subjectId));
        }
      }),
    ]);
  }

  void _syncDanmakuPauseWithPlayback(bool playing) {
    try {
      if (playing) {
        danmakuController.resume();
      } else {
        danmakuController.pause();
      }
    } catch (_) {}
  }

  /// 选中集与当前播放集不一致时清空弹幕数据与画布（切换集过程中）
  void clearDanmakuIfEpisodeMismatch(int selectedIndex) {
    if (selectedIndex != episode) {
      try {
        removeDanmaku();
      } catch (_) {}
    }
  }

  void dispose() {
    if (Platform.isWindows) {
      WindowsTitleBarVisibility.reset();
    }
    _saveSettingsTimer?.cancel();
    _stopTimer?.cancel();
    for (final subscription in _playerSubscriptions) {
      subscription.cancel();
    }
    _playerSubscriptions.clear();
    _clearDanmakuCanvas();
    player.dispose();
  }

  /// 初始化播放状态
  Future<void> initPlayState(PlayState state) async {
    removeDanmaku();
    videoUrl = state.videoUrl;
    offset = state.offset;
    subjectId = state.subjectId;
    episode = state.episodeIndex;
    episodeId = state.episodeId;
    subjectName = state.subjectName;
    subjectCover = state.subjectCover;
    alias = state.alias;
    _lastSavedPositionSeconds = null;
    if (state.videoUrl.isEmpty) return;
    await player.open(Media(state.videoUrl), play: false);
    await player.stream.duration.firstWhere((d) => d > Duration.zero);
    await Future.delayed(const Duration(milliseconds: 800), () {
      player.seek(Duration(seconds: offset));
    });
    await player.play();
    final logger = LiggLogger();

    ///加载弹幕
    try {
      if (!_isLoadingDanmaku && episode != 0) {
        _isLoadingDanmaku = true;
        final bgmBangumiId =
            await FlowRequest.getDanDanBangumiIDByBgmBangumiID(subjectId);
        if (bgmBangumiId != null) {
          final danmaku =
              await FlowRequest.getDanDanmaku(bgmBangumiId, episode);
          addDanmakuAll(danmaku);
          _isLoadingDanmaku = false;
        }
      }
    } catch (e) {
      logger.e(e);
    }
  }

  void handlePlayStateChanged(PlayControllerState state) {
    if (!state.playing) return;
    if (state.position <= const Duration(seconds: 5)) return;
    if (state.duration <= Duration.zero) return;
    if (subjectId <= 0 || episodeId <= 0) return;
    if (subjectName == null || subjectCover == null) return;

    final positionSeconds = state.position.inSeconds;
    final lastSavedPositionSeconds = _lastSavedPositionSeconds;
    if (lastSavedPositionSeconds != null &&
        positionSeconds >= lastSavedPositionSeconds &&
        positionSeconds - lastSavedPositionSeconds < 5) {
      return;
    }

    _lastSavedPositionSeconds = positionSeconds;
    unawaited(_savePlayHistory(state));
  }

  Future<void> _savePlayHistory(PlayControllerState state) async {
    if (_isSavingPlayHistory) return;
    _isSavingPlayHistory = true;
    try {
      final playHistory = PlayHistory(
        subjectId: subjectId,
        subjectName: subjectName!,
        episodeId: episodeId,
        episodeSort: episode,
        cover: subjectCover!,
        updateAt: DateTime.now(),
        position: state.position.inSeconds,
        duration: state.duration.inSeconds,
        alias: alias,
      );
      await PlayRepository.savePlayHistory(playHistory);
    } catch (e) {
      LiggLogger().e('保存播放进度失败: $e');
    } finally {
      _isSavingPlayHistory = false;
    }
  }

  ///更新缓冲状态
  void _updateBufferingState(bool buffering) {
    final videoUiStateController = _videoUiStateActions;
    if (buffering) {
      videoUiStateController
          .updateIndicatorType(VideoControlsIndicatorType.bufferingIndicator);
      videoUiStateController
          .updateMainAxisAlignmentType(MainAxisAlignment.center);
      videoUiStateController.showIndicator();
    } else {
      if (videoUiStateController.currentIndicatorType ==
          VideoControlsIndicatorType.bufferingIndicator) {
        videoUiStateController.hideIndicator();
        videoUiStateController
            .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
      }
    }
  }

  /// 从存储同步平台显示/隐藏状态
  void syncPlatformVisibilityFromStorage() {
    _playStateActions.setHiddenPlatforms(_loadHiddenPlatformsFromStorage());

    // 同步后清空屏幕弹幕，让新设置生效
    try {
      danmakuController.clear();
    } catch (_) {}
  }

  void updateIsWideScreen(bool value) {
    _playStateActions.setIsWideScreen(value);
  }

  // 切换内容区域展开状态
  void toggleContentExpanded() {
    _playStateActions.toggleContentExpanded();
  }

  /// 进入全屏
  void enterFullScreen() {
    _playStateActions.setIsFullscreen(true);
    if (Platform.isWindows) {
      WindowsTitleBarVisibility.setForceHidden(true);
    }
    // 移动端全屏时自动横屏
    SystemUtil.enterFullScreen();
  }

  /// 退出全屏
  void exitFullScreen() {
    _playStateActions.setIsFullscreen(false);
    if (Platform.isWindows) {
      unawaited(_exitWindowsFullScreen());
    } else {
      SystemUtil.exitFullScreen();
    }
  }

  /// 先退出窗口全屏再恢复标题栏，避免 forceHidden 已 false 但 _windowFullScreen 仍为 true。
  Future<void> _exitWindowsFullScreen() async {
    await SystemUtil.exitFullScreen();
    WindowsTitleBarVisibility.setForceHidden(false);
  }

  /// 切换全屏状态
  void toggleFullScreen() {
    if (_playStateActions.value.isFullscreen) {
      exitFullScreen();
    } else {
      enterFullScreen();
    }
  }

  /// 检测桌面端全屏状态
  Future<void> checkDesktopFullscreen() async {
    if (SystemUtil.isDesktop) {
      final fullScreen = await windowManager.isFullScreen();
      _playStateActions.setIsFullscreen(fullScreen);
      if (Platform.isWindows) {
        WindowsTitleBarVisibility.setForceHidden(fullScreen);
      }
    }
  }

  /// 处理全屏变化
  /// 在全屏切换时清空弹幕
  void handleFullscreenChange() {
    try {
      danmakuController.clear();
    } catch (_) {
      // 如果控制器未初始化，忽略错误
    }
  }

  void addDanmakuAll(List<Danmaku> danmaku) {
    // 按时间分组
    final groupedDanmakus = <int, List<Danmaku>>{};
    for (var item in danmaku) {
      int second = item.time.toInt();
      groupedDanmakus.putIfAbsent(second, () => []).add(item);
    }
    _playStateActions.setDanDanmakus(groupedDanmakus);
  }

  /// 发送弹幕
  /// [type]：1 滚动、4 底部、5 顶部。
  Future<bool> sendDanmaku(
    String message, {
    required int bgmUserId,
    Color? color,
    int type = 1,
  }) async {
    final bgmBangumiId =
        await FlowRequest.getDanDanBangumiIDByBgmBangumiID(subjectId);
    if (bgmBangumiId == null) return false;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return false;
    final playState = _playStateActions.value;
    if (playState.duration == Duration.zero &&
        playState.position == Duration.zero &&
        episode <= 0) {
      return false;
    }
    final time =
        playState.position.inMicroseconds / Duration.microsecondsPerSecond;

    final item = Danmaku(
      message: trimmed,
      time: time,
      type: type,
      color: color ?? Colors.white,
      bgmUserId: bgmUserId,
      source: 'AnimeFlow',
    );
    addDanDanmaku(item, bgmUserId);
    await FlowRequest.sendDanmaku(bgmBangumiId, episode,
        message: item.message,
        time: item.time,
        type: item.type,
        color: item.color);
    return true;
  }

  /// 添加弹幕到画布
  /// [bgmUserId] 当前登录用户的 Bangumi id；未登录时为 null，此时 [DanmakuContentItem.selfSend] 恒为 false。
  void addDanDanmaku(Danmaku danmaku, int? bgmUserId) {
    final DanmakuItemType itemType;
    if (danmaku.type == 4) {
      itemType = DanmakuItemType.bottom;
    } else if (danmaku.type == 5) {
      itemType = DanmakuItemType.top;
    } else {
      itemType = DanmakuItemType.scroll;
    }
    try {
      danmakuController.addDanmaku(
        DanmakuContentItem(
          danmaku.message,
          color: danmaku.color,
          type: itemType,
          selfSend: danmaku.bgmUserId != null && danmaku.bgmUserId == bgmUserId,
        ),
      );
    } catch (_) {}
  }

  void removeDanmaku() {
    _clearDanmakuCanvas();
    _playStateActions.clearDanDanmakus();
  }

  void _clearDanmakuCanvas() {
    try {
      danmakuController.clear();
    } catch (_) {}
  }

  /// 切换弹幕开关
  void toggleDanmaku() {
    _playStateActions.toggleDanmakuOn();
    final danmakuOn = _playStateActions.value.danmakuOn;
    Storage.setting.put(DanmakuKey.danmakuOn, danmakuOn);
    if (!danmakuOn) {
      try {
        danmakuController.clear();
      } catch (_) {}
    }
  }

  /// 切换视频画面填充模式
  void toggleVideoFit(BoxFit fits) {
    _playStateActions.setVideoFit(fits);
  }

  /// 切换平台显示/隐藏状态
  void togglePlatformVisibility(String platform) {
    _playStateActions.toggleHiddenPlatform(platform);
    // 清空屏幕上的弹幕，新弹幕会按照新的隐藏状态过滤
    try {
      danmakuController.clear();
    } catch (_) {}
  }

  /// 检查平台是否被隐藏
  bool isPlatformHidden(String platform) {
    return _playStateActions.value.hiddenPlatforms.contains(platform);
  }

  ///暂停/播放
  void playOrPauseVideo() {
    _videoUiStateActions.updateMainAxisAlignmentType(MainAxisAlignment.start);
    player.playOrPause();
  }

  ///设置播放倍数
  void startSpeedBoost(double speed) {
    _originalSpeed = _playStateActions.value.rate;
    _playStateActions.setRate(speed);
    player.setRate(speed);
  }

  /// 跳转到指定位置
  void seekTo(Duration pos) {
    player.seek(pos);
  }

  /// 结束速度提升
  void endSpeedBoost() {
    _playStateActions.setRate(_originalSpeed);
    player.setRate(_originalSpeed);
  }

  ///设置视频音量（绝对值）
  void setVolume(double newVolume) {
    double clampedVolume = newVolume.clamp(0.0, 100.0);
    player.setVolume(clampedVolume);
  }

  void startVerticalDrag() {
    _dragStartVolume = _playStateActions.value.volume;
    _playStateActions.setIsVerticalDragging(true);
  }

  void adjustVolumeByWheel(double delta) {
    double newVolume = _playStateActions.value.volume + delta;
    setVolume(newVolume);
  }

  void updateVerticalDrag(double dragDistance, double screenHeight) {
    final volumeChange = -(dragDistance / screenHeight) * 100;
    double newVolume = _dragStartVolume + volumeChange;
    final volume = _playStateActions.value.volume;
    if (newVolume >= 100 && volume < 100) {
      vibrateHeavy();
    } else if (newVolume <= 0 && volume > 0) {
      vibrateHeavy();
    }
    setVolume(newVolume);
  }

  void endVerticalDrag() {
    _playStateActions.setIsVerticalDragging(false);
    Future.delayed(const Duration(seconds: 2), () {
      if (!_playStateActions.value.isVerticalDragging) {}
    });
  }

  /// 开始播放
  Future<void> startPlaying() async {
    try {
      await player.play();
    } catch (_) {
      return;
    }
  }

  ///停止播放
  /// [duration] 可选参数，如果提供则会在指定时间后停止播放
  Future<void> stopPlaying({Duration? duration}) async {
    _stopTimer?.cancel();
    if (duration != null && duration > Duration.zero) {
      final totalSeconds = duration.inSeconds;
      _playStateActions.setScheduledStopDuration(totalSeconds);

      _stopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final scheduledStopDuration =
            _playStateActions.value.scheduledStopDuration;
        if (scheduledStopDuration > 0) {
          _playStateActions.setScheduledStopDuration(
            scheduledStopDuration - 1,
          );
        } else {
          player.pause();
          timer.cancel();
          _stopTimer = null;
        }
      });
    } else {
      _playStateActions.setScheduledStopDuration(0);
      player.pause();
    }
  }

  /// 取消定时停止
  void cancelScheduledStop() {
    _stopTimer?.cancel();
    _stopTimer = null;
    _playStateActions.setScheduledStopDuration(0);
  }

  ///设置超分辨率
  /// type 1 关闭 2 效率档 3 质量档
  Future<void> setShader(int type) async {
    var pp = player.platform as NativePlayer;
    await pp.waitForPlayerInitialization;
    await pp.waitForVideoControllerInitializationIfAttached;
    if (type == 2) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(
            shadersDirectory.path, mpvAnime4KShadersLite),
      ]);
      _playStateActions.setSuperResolutionType(2);
      return;
    }
    if (type == 3) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(
            shadersDirectory.path, mpvAnime4KShaders),
      ]);
      _playStateActions.setSuperResolutionType(3);
      return;
    }
    await pp.command(['change-list', 'glsl-shaders', 'clr', '']);
    _playStateActions.setSuperResolutionType(1);
  }
}
