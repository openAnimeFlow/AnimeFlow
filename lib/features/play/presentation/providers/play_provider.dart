import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/core/utils/vibrate.dart';
import 'package:anime_flow/shared/widgets/windows_title_bar.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/player_snapshot.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'play_provider.g.dart';

@Riverpod(
  keepAlive: true,
  dependencies: [
    shadersDirectory,
    PlayStateNotifier,
    VideoUiNotifier,
    Episodes,
    playExtra,
  ],
)
PlaySession playSession(Ref ref) {
  ref.watch(playExtraProvider);
  // 模式变化由下方 ref.listen 处理，不能 watch 重建整个播放会话。
  final initialDanmakuChineseMode = ref.read(danmakuChineseModeProvider);
  final controller = PlaySession(
    shadersDirectory: ref.watch(shadersDirectoryProvider).requireValue,
    playStateActions: ref.watch(playStateProvider.notifier),
    videoUiStateActions: ref.watch(videoUiProvider.notifier),
    episodesActions: ref.watch(episodesProvider.notifier),
    danmakuChineseConverter: ref.watch(danmakuChineseConverterProvider),
    engineFactory: const PlayerEngineFactory(),
    initialDanmakuChineseMode: initialDanmakuChineseMode,
    setEpisodeWatched: ({
      required subjectId,
      required episodeId,
      required watched,
    }) {
      ref.read(subjectEpisodesProvider(subjectId).notifier).setEpisodeWatched(
            episodeId: episodeId,
            watched: watched,
          );
    },
  )..init();

  ref.listen<DanmakuChineseMode>(
    danmakuChineseModeProvider,
    (previous, next) {
      if (previous != next) {
        unawaited(controller.applyDanmakuChineseMode(next));
      }
    },
  );

  ref.listen<PlayState>(
    playStateProvider,
    (previous, next) {
      controller._handlePlayStateChanged(next);
      controller._handleParseResultChanged(
        previous?.parseResult,
        next.parseResult,
      );
    },
  );
  ref.onDispose(controller.dispose);

  return controller;
}

@Riverpod(keepAlive: true, dependencies: [playExtra])
class PlayStateNotifier extends _$PlayStateNotifier {
  @override
  PlayState build() {
    ref.watch(playExtraProvider);
    return PlayState(
      danmakuOn: Storage.setting.get(DanmakuKey.danmakuOn, defaultValue: true),
      hiddenPlatforms: _loadHiddenPlatformsFromStorage(),
    );
  }

  PlayState get value => state;

  void setKernel(PlayerKernel value) {
    if (state.kernel == value) return;
    state = state.copyWith(kernel: value);
  }

  void setSwitchingKernel(bool value) {
    if (state.switchingKernel == value) return;
    state = state.copyWith(switchingKernel: value);
  }

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

  void incrementDanmakuEpoch() {
    state = state.copyWith(danmakuEpoch: state.danmakuEpoch + 1);
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

class PlayState {
  final PlayerKernel kernel;
  final bool switchingKernel;
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
  final int danmakuEpoch;

  const PlayState({
    this.kernel = PlayerKernel.mediaKit,
    this.switchingKernel = false,
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
    this.danmakuEpoch = 0,
  });

  PlayState copyWith({
    PlayerKernel? kernel,
    bool? switchingKernel,
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
    int? danmakuEpoch,
  }) {
    return PlayState(
      kernel: kernel ?? this.kernel,
      switchingKernel: switchingKernel ?? this.switchingKernel,
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
      danmakuEpoch: danmakuEpoch ?? this.danmakuEpoch,
    );
  }
}

class PlayRequest {
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

  /// Bangumi 剧集 sort
  final int episodeSort;

  ///剧集id
  final int episodeId;

  final String? localDanmakuPath;

  final bool isLocalPlayback;

  const PlayRequest({
    required this.videoUrl,
    required this.offset,
    required this.subjectId,
    required this.episodeIndex,
    required this.episodeSort,
    required this.episodeId,
    required this.subjectName,
    required this.subjectCover,
    required this.alias,
    this.localDanmakuPath,
    this.isLocalPlayback = false,
  });
}

class PlaySession {
  static const _parseSuccessResult = '视频解析成功';
  static const _watchedProgressThreshold = 0.90;

  PlaySession({
    required this.shadersDirectory,
    required PlayStateNotifier playStateActions,
    required VideoUiStateActions videoUiStateActions,
    required Episodes episodesActions,
    required this.danmakuChineseConverter,
    required this.engineFactory,
    required DanmakuChineseMode initialDanmakuChineseMode,
    required void Function({
      required int subjectId,
      required int episodeId,
      required bool watched,
    }) setEpisodeWatched,
  })  : _playStateActions = playStateActions,
        _videoUiStateActions = videoUiStateActions,
        _episodesActions = episodesActions,
        _setEpisodeWatched = setEpisodeWatched,
        _danmakuChineseMode = initialDanmakuChineseMode;

  late PlayerEngine engine;
  final PlayerEngineFactory engineFactory;
  final PlayStateNotifier _playStateActions;
  final VideoUiStateActions _videoUiStateActions;
  final Episodes _episodesActions;
  final DanmakuChineseConverter danmakuChineseConverter;
  DanmakuChineseMode _danmakuChineseMode;
  int _danmakuChineseModeRevision = 0;
  final void Function({
    required int subjectId,
    required int episodeId,
    required bool watched,
  }) _setEpisodeWatched;
  PlayState _latestPlayState = const PlayState();
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

  /// 当前 Bangumi 剧集 sort
  int episodeSort = 0;

  ///剧集id
  int episodeId = 0;

  bool isLocalPlayback = false;

  String? localDanmakuPath;

  /// 当前播放会话使用的统一播放源，用于重新加载和播放器内核切换时恢复上下文。
  PlaybackSource? _currentSource;

  ///弹幕相关
  DanmakuController? danmakuController;
  Timer? _saveSettingsTimer;

  /// 记录原始倍速
  double? _speedBeforeBoost;
  bool _isSpeedBoosting = false;

  /// 垂直拖动相关
  double _dragStartVolume = 100.0;

  Timer? _systemVolumeSyncTimer;
  double? _pendingSystemVolume;
  double? _lastKnownSystemVolume;
  DateTime? _ignoreSystemVolumeEventsUntil;

  static const Duration _systemVolumeSyncInterval = Duration(milliseconds: 80);

  /// 定时停止播放的计时器
  Timer? _stopTimer;

  bool _isLoadingDanmaku = false;
  bool _isPlayerBuffering = false;
  bool _lastPlayerPlaying = false;
  DateTime? _lastPausePlayHistorySavedAt;

  Future<void> _playHistorySaveQueue = Future<void>.value();
  final Set<int> _autoWatchedEpisodeIds = {};
  final Set<int> _autoWatchedEpisodeUpdatesInFlight = {};

  StreamSubscription<PlayerEvent>? _playerSubscription;
  bool _isDisposed = false;

  static const Duration _bufferingPositionTolerance =
      Duration(milliseconds: 500);
  static const Duration _pausePlayHistoryThrottle = Duration(seconds: 1);

  void init() {
    _latestPlayState = _playStateActions.value;
    final adBlocker = setting.get(PlaybackKey.adBlocker, defaultValue: false);
    engine = engineFactory.create(
      PlayerKernel.mediaKit,
      adBlocker: adBlocker,
    );
    unawaited(engine.initialize());
    _listenToEngine();
    unawaited(_initSystemVolumeSync());
  }

  void _listenToEngine() {
    _playerSubscription = engine.events.listen(_handlePlayerEvent);
  }

  /// 在保持播放上下文的前提下切换播放器内核。
  Future<void> switchKernel(PlayerKernel target) async {
    if (_isDisposed || _playStateActions.value.switchingKernel) return;
    if (engine.kernel == target) return;

    final source = _currentSource;
    if (source == null) return;

    final current = engine;
    final state = _playStateActions.value;
    final snapshot = PlayerSnapshot(
      source: source,
      position: state.position,
      volume: state.volume,
      rate: state.rate,
      wasPlaying: state.playing,
      fit: state.videoFit,
    );
    final adBlocker = setting.get(PlaybackKey.adBlocker, defaultValue: false);
    PlayerEngine? next;

    _playStateActions.setSwitchingKernel(true);
    try {
      await current.pause();
      await _playerSubscription?.cancel();
      _playerSubscription = null;

      next = engineFactory.create(target, adBlocker: adBlocker);
      await next.initialize();
      await next.open(
        snapshot.source,
        startPosition: snapshot.position,
        autoPlay: false,
      );
      await next.setVolume(snapshot.volume);
      await next.setRate(snapshot.rate);

      engine = next;
      _listenToEngine();
      _playStateActions.setKernel(target);
      _playStateActions.setSwitchingKernel(false);

      await current.dispose();
      if (snapshot.wasPlaying) await engine.play();
    } catch (error, stackTrace) {
      LiggLogger()
          .e('切换播放器内核失败: $target', error: error, stackTrace: stackTrace);
      await next?.dispose();
      engine = current;
      _listenToEngine();
      _playStateActions.setSwitchingKernel(false);
      if (snapshot.wasPlaying) unawaited(current.play());
    }
  }

  void _handlePlayerEvent(PlayerEvent event) {
    if (event is PlayerPlayingChanged) {
      if (_lastPlayerPlaying && !event.playing) {
        final now = DateTime.now();
        final lastSavedAt = _lastPausePlayHistorySavedAt;
        if (lastSavedAt == null ||
            now.difference(lastSavedAt) >= _pausePlayHistoryThrottle) {
          _lastPausePlayHistorySavedAt = now;
          unawaited(_savePlayHistory());
        }
      }
      _lastPlayerPlaying = event.playing;
      _playStateActions.setPlaying(event.playing);
      _syncDanmakuPauseWithPlayback(event.playing);
    } else if (event is PlayerVolumeChanged) {
      if (!SystemUtil.supportsSystemVolumeSync) {
        _playStateActions.setVolume(event.volume);
      }
    } else if (event is PlayerBufferedChanged) {
      _playStateActions.setBuffered(event.buffered);
      _updateEffectiveBufferingState(buffered: event.buffered);
    } else if (event is PlayerBufferingChanged) {
      _isPlayerBuffering = event.buffering;
      _updateEffectiveBufferingState(playerBuffering: event.buffering);
    } else if (event is PlayerRateChanged) {
      _playStateActions.setRate(event.rate);
    } else if (event is PlayerPositionChanged) {
      _playStateActions.setPosition(event.position);
      _updateEffectiveBufferingState(position: event.position);
    } else if (event is PlayerDurationChanged) {
      _playStateActions.setDuration(event.duration);
    } else if (event is PlayerCompleted) {
      if (subjectId > 0) {
        _autoSwitchToNextEpisode();
        unawaited(PlayHistoryService.clearPosition(subjectId));
      }
    } else if (event is PlayerError) {
      LiggLogger().e('播放器错误: ${event.error}', error: event.stackTrace);
    }
  }

  void _syncDanmakuPauseWithPlayback(bool playing) {
    final controller = danmakuController;
    if (controller == null) return;
    if (playing) {
      controller.resume();
    } else {
      controller.pause();
    }
  }

  void _autoSwitchToNextEpisode() {
    try {
      if (_episodesActions.hasNextEpisode) {
        _episodesActions.switchToNextEpisode();
      }
    } catch (e) {
      LiggLogger().e('自动切换到下一集失败: $e');
    }
  }

  void _handleParseResultChanged(
    String? previousParseResult,
    String nextParseResult,
  ) {
    if (previousParseResult == nextParseResult) {
      return;
    }
    if (nextParseResult != _parseSuccessResult) {
      return;
    }

    if (_videoUiStateActions.currentIndicatorType !=
        VideoControlsIndicatorType.parsingIndicator) {
      return;
    }
    _videoUiStateActions.hideIndicator();
    _videoUiStateActions
        .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
    _videoUiStateActions.updateMainAxisAlignmentType(MainAxisAlignment.start);
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
    _isDisposed = true;
    unawaited(_savePlayHistory());
    if (Platform.isWindows) {
      WindowsTitleBarVisibility.reset();
    }
    SystemUtil.removeSystemVolumeListener();
    _systemVolumeSyncTimer?.cancel();
    _saveSettingsTimer?.cancel();
    _stopTimer?.cancel();
    unawaited(_playerSubscription?.cancel());
    _playerSubscription = null;
    _clearDanmakuCanvas();
    unawaited(engine.dispose());
  }

  void pauseForRouteCover() {
    cancelScheduledStop();
    unawaited(engine.pause());
  }

  Future<void> stopCurrentMedia() async {
    cancelScheduledStop();
    await engine.stop();
    _clearDanmakuCanvas();
  }

  /// 初始化播放状态
  Future<void> initPlayState(PlayRequest state) async {
    if (_isDisposed) return;
    await stopCurrentMedia();
    if (_isDisposed) return;
    removeDanmaku();
    videoUrl = state.videoUrl;
    offset = state.offset;
    subjectId = state.subjectId;
    episode = state.episodeIndex;
    episodeSort = state.episodeSort;
    episodeId = state.episodeId;
    subjectName = state.subjectName;
    subjectCover = state.subjectCover;
    alias = state.alias;
    isLocalPlayback = state.isLocalPlayback;
    localDanmakuPath = state.localDanmakuPath;
    if (state.videoUrl.isEmpty) return;
    _currentSource = PlaybackSource(
      uri: Uri.parse(state.videoUrl),
      isLocal: state.isLocalPlayback,
    );
    await engine.open(
      _currentSource!,
      autoPlay: false,
    );
    if (_isDisposed) return;
    await engine.events.firstWhere(
      (event) =>
          event is PlayerDurationChanged && event.duration > Duration.zero,
    );
    if (_isDisposed) return;
    await Future.delayed(const Duration(milliseconds: 800), () {
      if (!_isDisposed) {
        unawaited(engine.seek(Duration(seconds: offset)));
      }
    });
    if (_isDisposed) return;
    await engine.play();
    if (_isDisposed) return;
    final logger = LiggLogger();

    ///加载弹幕
    try {
      if (!_isLoadingDanmaku && episode != 0) {
        _isLoadingDanmaku = true;
        try {
          if (isLocalPlayback) {
            final danmaku = await _loadLocalDanmaku(localDanmakuPath);
            if (_isDisposed) return;
            if (danmaku.isNotEmpty) {
              final converted = await danmakuChineseConverter.convertDanmakus(
                danmaku,
                _danmakuChineseMode,
              );
              if (_isDisposed) return;
              addDanmakuAll(converted);
            }
          } else {
            final bgmBangumiId =
                await FlowApi.getDanDanBangumiIDByBgmBangumiID(subjectId);
            if (bgmBangumiId != null) {
              final danmaku =
                  await FlowApi.getDanDanmaku(bgmBangumiId, episode);
              if (_isDisposed) return;
              final converted = await danmakuChineseConverter.convertDanmakus(
                danmaku,
                _danmakuChineseMode,
              );
              if (_isDisposed) return;
              addDanmakuAll(converted);
            }
          }
        } finally {
          _isLoadingDanmaku = false;
        }
      }
    } catch (e) {
      logger.e(e);
    }
  }

  void _handlePlayStateChanged(PlayState state) {
    _latestPlayState = state;
    if (state.duration <= Duration.zero) return;
    if (subjectId <= 0 || episodeId <= 0) return;
    if (subjectName == null || subjectCover == null) return;
    if (isLocalPlayback) return;

    final setting = Storage.setting;
    if (setting.get(PlaybackKey.episodesProgress, defaultValue: true)) {
      if (state.playing) {
        _autoUpdateEpisodeWatchedIfNeeded(state);
      }
    }
  }

  void _autoUpdateEpisodeWatchedIfNeeded(PlayState state) {
    final progress =
        state.position.inMilliseconds / state.duration.inMilliseconds;
    if (progress < _watchedProgressThreshold) {
      return;
    }
    if (_autoWatchedEpisodeIds.contains(episodeId) ||
        _autoWatchedEpisodeUpdatesInFlight.contains(episodeId)) {
      return;
    }

    _autoWatchedEpisodeUpdatesInFlight.add(episodeId);
    unawaited(_autoUpdateEpisodeWatched(episodeId));
  }

  Future<void> _autoUpdateEpisodeWatched(int targetEpisodeId) async {
    try {
      await updateEpisodeWatched(targetEpisodeId);
      _autoWatchedEpisodeIds.add(targetEpisodeId);
    } catch (e) {
      LiggLogger().e('自动更新观看进度失败: $e');
    } finally {
      _autoWatchedEpisodeUpdatesInFlight.remove(targetEpisodeId);
    }
  }

  Future<void> _savePlayHistory({
    Duration? position,
    PlayHistoryEventType eventType = PlayHistoryEventType.defaults,
  }) async {
    final state = _latestPlayState;
    if (state.duration <= Duration.zero ||
        subjectId <= 0 ||
        episodeId <= 0 ||
        subjectName == null ||
        subjectCover == null) {
      return;
    }
    final savedPosition = position ?? state.position;
    final savedSubjectId = subjectId;
    final savedEpisodeId = episodeId;
    final savedEpisodeSort = episodeSort;
    final savedSubjectName = subjectName!;
    final savedSubjectCover = subjectCover!;
    final savedAlias = List<String>.from(alias);
    _playHistorySaveQueue = _playHistorySaveQueue.then((_) async {
      try {
        final playHistory = PlayHistory(
          subjectId: savedSubjectId,
          subjectName: savedSubjectName,
          episodeId: savedEpisodeId,
          episodeSort: savedEpisodeSort,
          cover: savedSubjectCover,
          updateAt: DateTime.now(),
          position: savedPosition.inSeconds,
          duration: state.duration.inSeconds,
          alias: savedAlias,
        );
        await PlayHistoryService.save(playHistory, eventType: eventType);
      } catch (e) {
        LiggLogger().e('保存播放进度失败: $e');
      }
    });
    await _playHistorySaveQueue;
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

  void _updateEffectiveBufferingState({
    Duration? position,
    Duration? buffered,
    bool? playerBuffering,
  }) {
    final playState = _playStateActions.value;
    final currentPosition = position ?? playState.position;
    final currentBuffered = buffered ?? playState.buffered;
    final isBuffering = (playerBuffering ?? _isPlayerBuffering) ||
        _isPositionPastBuffered(currentPosition, currentBuffered);

    _playStateActions.setBuffering(isBuffering);
    _updateBufferingState(isBuffering);
  }

  bool _isPositionPastBuffered(Duration position, Duration buffered) {
    if (position <= Duration.zero) return false;
    if (buffered <= Duration.zero) return false;

    return position - buffered > _bufferingPositionTolerance;
  }

  /// 更新剧集观看状态
  Future<void> updateEpisodeWatched(int episodeId,
      {bool watched = true}) async {
    final targetSubjectId = subjectId;
    await FlowApi.updateEpisodeWatchedService(episodeId, watched: watched);
    if (targetSubjectId <= 0) {
      return;
    }
    _setEpisodeWatched(
      subjectId: targetSubjectId,
      episodeId: episodeId,
      watched: watched,
    );
  }

  /// 从存储同步平台显示/隐藏状态
  void syncPlatformVisibilityFromStorage() {
    _playStateActions.setHiddenPlatforms(_loadHiddenPlatformsFromStorage());

    // 同步后清空屏幕弹幕，让新设置生效
    danmakuController?.clear();
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
    danmakuController?.clear();
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

  /// 播放中切换简繁转换模式时，基于原文重新转换当前剧集弹幕。
  Future<void> applyDanmakuChineseMode(DanmakuChineseMode mode) async {
    if (_danmakuChineseMode == mode) return;
    _danmakuChineseMode = mode;
    final revision = ++_danmakuChineseModeRevision;

    final state = _playStateActions.value;
    final all = state.danDanmakus.values.expand((items) => items).toList();
    if (all.isEmpty) return;

    _playStateActions.incrementDanmakuEpoch();
    _clearDanmakuCanvas();

    final converted = await danmakuChineseConverter.convertDanmakus(all, mode);
    if (revision != _danmakuChineseModeRevision) return;
    final grouped = <int, List<Danmaku>>{};
    for (final item in converted) {
      grouped.putIfAbsent(item.time.toInt(), () => []).add(item);
    }
    _playStateActions.setDanDanmakus(grouped);
  }

  /// 发送弹幕
  /// [type]：1 滚动、4 底部、5 顶部。
  Future<bool> sendDanmaku(
    String message, {
    required int bgmUserId,
    Color? color,
    int type = 1,
  }) async {
    if (isLocalPlayback) return false;
    final bgmBangumiId =
        await FlowApi.getDanDanBangumiIDByBgmBangumiID(subjectId);
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
    await FlowApi.sendDanmaku(bgmBangumiId, episode,
        message: item.message,
        time: item.time,
        type: item.type,
        color: item.color);
    return true;
  }

  Future<List<Danmaku>> _loadLocalDanmaku(String? path) async {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return const [];
    }
    final file = File(trimmedPath);
    if (!await file.exists()) {
      return const [];
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      final items = switch (decoded) {
        List<dynamic> value => value,
        {'data': final List<dynamic> value} => value,
        {'comments': final List<dynamic> value} => value,
        _ => const <dynamic>[],
      };
      return items
          .whereType<Map<String, dynamic>>()
          .map(Danmaku.fromJson)
          .toList();
    } catch (e) {
      LiggLogger().e('加载本地弹幕失败: $e');
      return const [];
    }
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
      danmakuController?.addDanmaku(
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
    _danmakuChineseModeRevision++;
    _clearDanmakuCanvas();
    _playStateActions.clearDanDanmakus();
  }

  void _clearDanmakuCanvas() {
    danmakuController?.clear();
  }

  /// 切换弹幕开关
  void toggleDanmaku() {
    _playStateActions.toggleDanmakuOn();
    final danmakuOn = _playStateActions.value.danmakuOn;
    Storage.setting.put(DanmakuKey.danmakuOn, danmakuOn);
    if (!danmakuOn) {
      danmakuController?.clear();
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
    danmakuController?.clear();
  }

  /// 检查平台是否被隐藏
  bool isPlatformHidden(String platform) {
    return _playStateActions.value.hiddenPlatforms.contains(platform);
  }

  ///暂停/播放
  void playOrPauseVideo() {
    _videoUiStateActions.updateMainAxisAlignmentType(MainAxisAlignment.start);
    if (_playStateActions.value.playing) {
      unawaited(engine.pause());
    } else {
      unawaited(engine.play());
    }
  }

  void _applyPlaybackRate(double speed) {
    _playStateActions.setRate(speed);
    unawaited(engine.setRate(speed));
  }

  /// 设置播放倍数
  void setPlaybackRate(double speed, {bool temporary = false}) {
    if (temporary) {
      if (!_isSpeedBoosting) {
        _speedBeforeBoost = _playStateActions.value.rate;
        _isSpeedBoosting = true;
      }

      _applyPlaybackRate(speed);
      return;
    }

    if (_isSpeedBoosting) {
      _speedBeforeBoost = speed;
      return;
    }

    _applyPlaybackRate(speed);
  }

  /// 跳转到指定位置
  void seekTo(Duration pos) {
    unawaited(engine.seek(pos));
    _updateEffectiveBufferingState(position: pos);
    unawaited(
      _savePlayHistory(
        position: pos,
        eventType: PlayHistoryEventType.forceOverwrite,
      ),
    );
  }

  void updateBufferingForPendingSeek(Duration pos) {
    _updateEffectiveBufferingState(position: pos);
  }

  /// 结束临时播放倍速
  void endTemporaryPlaybackRate() {
    if (!_isSpeedBoosting || _speedBeforeBoost == null) return;

    final speed = _speedBeforeBoost!;
    _isSpeedBoosting = false;
    _speedBeforeBoost = null;
    _applyPlaybackRate(speed);
  }

  ///设置视频音量
  void _setPlayerVolume(double newVolume) {
    final clampedVolume = newVolume.clamp(0.0, 100.0);
    _playStateActions.setVolume(clampedVolume);
    unawaited(engine.setVolume(
      SystemUtil.supportsSystemVolumeSync ? 100.0 : clampedVolume,
    ));
  }

  void _updateVolume(
    double newVolume, {
    bool syncSystemVolume = true,
  }) {
    final clampedVolume = newVolume.clamp(0.0, 100.0);
    _setPlayerVolume(clampedVolume);
    if (syncSystemVolume) {
      _scheduleSystemVolumeSync(clampedVolume / 100);
    }
  }

  Future<void> _initSystemVolumeSync() async {
    if (!SystemUtil.supportsSystemVolumeSync) return;

    await SystemUtil.configureSystemVolumeSync();
    final systemVolume = await SystemUtil.getSystemVolume();
    if (systemVolume != null) {
      _lastKnownSystemVolume = systemVolume;
      _setPlayerVolume(systemVolume * 100);
    }

    SystemUtil.addSystemVolumeListener(_handleSystemVolumeChanged);
  }

  void _handleSystemVolumeChanged(double volume) {
    final normalized = volume.clamp(0.0, 1.0);
    final ignoreUntil = _ignoreSystemVolumeEventsUntil;
    final isSelfTriggered = ignoreUntil != null &&
        DateTime.now().isBefore(ignoreUntil) &&
        _isSameVolume(_lastKnownSystemVolume, normalized);
    if (isSelfTriggered) {
      return;
    }

    _lastKnownSystemVolume = normalized;
    _pendingSystemVolume = null;
    _updateVolume(normalized * 100, syncSystemVolume: false);
  }

  void _scheduleSystemVolumeSync(double normalizedVolume) {
    if (!SystemUtil.supportsSystemVolumeSync) return;

    final clampedVolume = normalizedVolume.clamp(0.0, 1.0);
    _pendingSystemVolume = clampedVolume;

    if (_systemVolumeSyncTimer?.isActive ?? false) {
      return;
    }

    _systemVolumeSyncTimer = Timer(_systemVolumeSyncInterval, () {
      final pendingVolume = _pendingSystemVolume;
      _pendingSystemVolume = null;
      if (pendingVolume == null ||
          _isSameVolume(_lastKnownSystemVolume, pendingVolume)) {
        return;
      }
      unawaited(_pushSystemVolume(pendingVolume));
    });
  }

  Future<void> _pushSystemVolume(double normalizedVolume) async {
    _lastKnownSystemVolume = normalizedVolume;
    _ignoreSystemVolumeEventsUntil =
        DateTime.now().add(_systemVolumeSyncInterval * 2);
    await SystemUtil.setSystemVolume(normalizedVolume);
  }

  bool _isSameVolume(double? a, double? b) {
    if (a == null || b == null) return false;
    return (a - b).abs() < 0.01;
  }

  void startVerticalDrag() {
    _dragStartVolume = _playStateActions.value.volume;
    _playStateActions.setIsVerticalDragging(true);
  }

  void adjustVolumeByWheel(double delta) {
    final newVolume = _playStateActions.value.volume + delta;
    _updateVolume(newVolume);
  }

  void updateVerticalDrag(double dragDistance, double screenHeight) {
    final volumeChange = -(dragDistance / screenHeight) * 100;
    final newVolume = _dragStartVolume + volumeChange;
    final volume = _playStateActions.value.volume;
    if (newVolume >= 100 && volume < 100) {
      vibrateHeavy();
    } else if (newVolume <= 0 && volume > 0) {
      vibrateHeavy();
    }
    _updateVolume(newVolume);
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
      await engine.play();
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
          unawaited(engine.pause());
          timer.cancel();
          _stopTimer = null;
        }
      });
    } else {
      _playStateActions.setScheduledStopDuration(0);
      await engine.pause();
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
    if (!engine.capabilities.supportsShader) {
      throw UnsupportedError('当前播放器内核不支持 Anime4K');
    }
    if (type == 2) {
      await engine.setShaders(Utils.buildShadersAbsolutePath(
          shadersDirectory.path, mpvAnime4KShadersLite));
      _playStateActions.setSuperResolutionType(2);
      return;
    }
    if (type == 3) {
      await engine.setShaders(Utils.buildShadersAbsolutePath(
          shadersDirectory.path, mpvAnime4KShaders));
      _playStateActions.setSuperResolutionType(3);
      return;
    }
    await engine.setShaders('');
    _playStateActions.setSuperResolutionType(1);
  }

  Widget buildVideoSurface({required BoxFit fit}) {
    return engine.buildVideoSurface(fit: fit);
  }

  Future<Uint8List?> takeScreenshot() => engine.screenshot();

  Future<void> stop() => engine.stop();
}
