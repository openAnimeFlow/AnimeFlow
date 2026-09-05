import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_playback_synchronizer.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/application/system_volume_synchronizer.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/core/utils/vibrate.dart';
import 'package:anime_flow/shared/widgets/windows_title_bar.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/player_snapshot.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:anime_flow/features/play/application/playback_coordinator.dart';
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

  final PlayerEngineFactory engineFactory;
  late final PlaybackCoordinator playbackCoordinator;
  late final PlaybackProgressManager playbackProgressManager;
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
  final setting = Storage.setting;

  /// 着色器所在目录（由 [shadersDirectoryProvider] 在启动时准备）
  final Directory shadersDirectory;

  /// 视频地址
  String? videoUrl;

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
  final DanmakuPlaybackSynchronizer danmakuSynchronizer =
      DanmakuPlaybackSynchronizer();
  DanmakuController? get danmakuController => danmakuSynchronizer.controller;
  set danmakuController(DanmakuController? value) {
    danmakuSynchronizer.controller = value;
  }

  /// 记录原始倍速
  double? _speedBeforeBoost;
  bool _isSpeedBoosting = false;

  /// 垂直拖动相关
  double _dragStartVolume = 100.0;

  late final SystemVolumeSynchronizer systemVolumeSynchronizer;

  /// 定时停止播放的计时器
  Timer? _stopTimer;

  bool _isPlayerBuffering = false;
  bool _lastPlayerPlaying = false;
  StreamSubscription<PlayerEvent>? _playerSubscription;
  bool _isDisposed = false;
  Future<void> _playbackChanges = Future<void>.value();

  // Keep episode metadata, source opening and kernel snapshots in the same
  // order. Danmaku loading stays outside this queue so it cannot block playback.
  Future<T> _serializePlaybackChange<T>(Future<T> Function() change) {
    final result = _playbackChanges.then((_) => change());
    _playbackChanges =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static const Duration _bufferingPositionTolerance =
      Duration(milliseconds: 500);
  void init() {
    final adBlocker = setting.get(PlaybackKey.adBlocker, defaultValue: false);
    final preferredKernel = _readPreferredPlayerKernel();
    playbackCoordinator = PlaybackCoordinator(
      engineFactory: engineFactory,
      adBlocker: adBlocker,
    );
    scheduleMicrotask(() {
      if (!_isDisposed) {
        _playStateActions.setKernel(preferredKernel);
      }
    });
    playbackProgressManager = PlaybackProgressManager(
      onEpisodeWatched: ({
        required subjectId,
        required episodeId,
        required watched,
      }) {
        _setEpisodeWatched(
          subjectId: subjectId,
          episodeId: episodeId,
          watched: watched,
        );
      },
    );
    systemVolumeSynchronizer = SystemVolumeSynchronizer(
      onSystemVolumeChanged: (volume) => _updateVolume(
        volume,
        syncSystemVolume: false,
      ),
    );
    unawaited(playbackCoordinator.initialize(
      kernel: preferredKernel,
    ));
    _playerSubscription = playbackCoordinator.events.listen(_handlePlayerEvent);
    unawaited(systemVolumeSynchronizer.initialize());
  }

  /// 在保持播放上下文的前提下切换播放器内核。
  Future<bool> switchKernel(PlayerKernel target) =>
      _serializePlaybackChange(() => _switchKernel(target));

  Future<bool> setHardwareDecoder(bool enabled) =>
      _serializePlaybackChange(() async {
        if (_isDisposed) return false;
        final previous = setting.get(PlaybackKey.hardwareDecoder,
            defaultValue: true) as bool;
        if (previous == enabled) return true;
        await setting.put(PlaybackKey.hardwareDecoder, enabled);
        var applied = false;
        try {
          applied =
              await _switchKernel(playbackCoordinator.kernel, force: true);
          return applied;
        } finally {
          if (!_isDisposed) _playStateActions.setSwitchingKernel(false);
          if (!applied) {
            await setting.put(PlaybackKey.hardwareDecoder, previous);
          }
        }
      });

  Future<bool> _switchKernel(PlayerKernel target, {bool force = false}) async {
    if (_isDisposed || _playStateActions.value.switchingKernel) return false;
    if (!force && playbackCoordinator.kernel == target) return true;

    final source = _currentSource;

    final state = _playStateActions.value;
    final snapshot = PlayerSnapshot(
      source: source,
      position: state.position,
      volume: state.volume,
      rate: state.rate,
      wasPlaying: state.playing,
      fit: state.videoFit,
    );
    _playStateActions.setSwitchingKernel(true);
    final shaderList = switch (state.superResolutionType) {
      2 => mpvAnime4KShadersLite,
      3 => mpvAnime4KShaders,
      _ => const <String>[],
    };
    final switched = await playbackCoordinator.switchKernel(target, snapshot,
        force: force,
        shaders: force && shaderList.isNotEmpty
            ? Utils.buildShadersAbsolutePath(shadersDirectory.path, shaderList)
            : null);
    if (_isDisposed) return false;
    if (switched) {
      _playStateActions.setKernel(target);
      unawaited(
        setting.put(PlaybackKey.preferredPlayerKernel, target.name),
      );
    } else {
      LiggLogger().e('切换播放器内核失败: $target');
    }
    _playStateActions.setSwitchingKernel(false);
    return switched;
  }

  PlayerKernel _readPreferredPlayerKernel() {
    final value = setting.get(
      PlaybackKey.preferredPlayerKernel,
      defaultValue: PlayerKernel.mediaKit.name,
    );
    return PlayerKernel.values.firstWhere(
      (kernel) => kernel.name == value,
      orElse: () => PlayerKernel.mediaKit,
    );
  }

  void _handlePlayerEvent(PlayerEvent event) {
    if (event is PlayerPlayingChanged) {
      if (_lastPlayerPlaying && !event.playing) {
        playbackProgressManager.saveAfterPause();
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
    danmakuSynchronizer.syncPlayback(playing);
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
    _videoUiStateActions.finishParsingIndicator();
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
    unawaited(playbackProgressManager.save());
    if (Platform.isWindows) {
      WindowsTitleBarVisibility.reset();
    }
    systemVolumeSynchronizer.dispose();
    _stopTimer?.cancel();
    unawaited(_playerSubscription?.cancel());
    _playerSubscription = null;
    _clearDanmakuCanvas();
    unawaited(playbackCoordinator.dispose());
  }

  void pauseForRouteCover() {
    cancelScheduledStop();
    unawaited(playbackCoordinator.pause());
  }

  int _playRequestId = 0;

  bool _isCurrentPlayRequest(int requestId) =>
      !_isDisposed && requestId == _playRequestId;

  Future<void> stopCurrentMedia() async {
    _playRequestId++;
    await _serializePlaybackChange(() async {
      if (_isDisposed) return;
      cancelScheduledStop();
      _currentSource = null;
      await playbackCoordinator.stop();
      if (_isDisposed) return;
      _clearDanmakuCanvas();
    });
  }

  /// 初始化播放状态
  Future<void> initPlayState(PlayRequest state) async {
    if (_isDisposed) return;
    final requestId = ++_playRequestId;
    await _serializePlaybackChange(() async {
      if (!_isCurrentPlayRequest(requestId)) return;
      cancelScheduledStop();
      _currentSource = null;
      await playbackCoordinator.stop();
      if (!_isCurrentPlayRequest(requestId)) return;
      removeDanmaku();
      videoUrl = state.videoUrl;
      subjectId = state.subjectId;
      episode = state.episodeIndex;
      episodeSort = state.episodeSort;
      episodeId = state.episodeId;
      subjectName = state.subjectName;
      subjectCover = state.subjectCover;
      alias = state.alias;
      isLocalPlayback = state.isLocalPlayback;
      localDanmakuPath = state.localDanmakuPath;
      playbackProgressManager.setPlaybackContext(
        subjectId: subjectId,
        episodeId: episodeId,
        episodeSort: episodeSort,
        subjectName: subjectName,
        subjectCover: subjectCover,
        alias: alias,
        isLocalPlayback: isLocalPlayback,
      );
      if (state.videoUrl.isEmpty) return;
      _currentSource = PlaybackSource(
        uri: Uri.parse(state.videoUrl),
        isLocal: state.isLocalPlayback,
      );
      await playbackCoordinator.open(
        _currentSource!,
        startPosition: Duration(seconds: state.offset),
        autoPlay: false,
      );
      if (!_isCurrentPlayRequest(requestId)) return;
      await playbackCoordinator.play();
    });
    if (!_isCurrentPlayRequest(requestId)) return;
    if (state.videoUrl.isEmpty) return;
    await _loadEpisodeDanmaku(state, requestId);
  }

  Future<void> _loadEpisodeDanmaku(PlayRequest request, int requestId) async {
    if (request.episodeIndex == 0) return;
    try {
      final List<Danmaku> danmaku;
      if (request.isLocalPlayback) {
        danmaku = await _loadLocalDanmaku(request.localDanmakuPath);
      } else {
        final bangumiId =
            await FlowApi.getDanDanBangumiIDByBgmBangumiID(request.subjectId);
        if (!_isCurrentPlayRequest(requestId) || bangumiId == null) return;
        danmaku = await FlowApi.getDanDanmaku(bangumiId, request.episodeIndex);
      }
      if (danmaku.isEmpty) return;
      while (_isCurrentPlayRequest(requestId)) {
        final revision = _danmakuChineseModeRevision;
        final converted = await danmakuChineseConverter.convertDanmakus(
          danmaku,
          _danmakuChineseMode,
        );
        if (!_isCurrentPlayRequest(requestId)) return;
        if (revision != _danmakuChineseModeRevision) continue;
        addDanmakuAll(converted);
        return;
      }
    } catch (e) {
      LiggLogger().e(e);
    }
  }

  void _handlePlayStateChanged(PlayState state) {
    if (state.isParsing) {
      _videoUiStateActions.showParsingIndicator();
    }
    playbackProgressManager.updatePlaybackState(
      position: state.position,
      duration: state.duration,
      playing: state.playing,
    );
  }

  ///更新缓冲状态
  void _updateBufferingState(bool buffering) {
    _videoUiStateActions.updateBufferingIndicator(
      buffering,
      isParsing: _playStateActions.value.isParsing,
    );
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
    if (_isDisposed || revision != _danmakuChineseModeRevision) return;
    addDanmakuAll(converted);
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
    danmakuSynchronizer.clear();
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
      unawaited(playbackCoordinator.pause());
    } else {
      unawaited(playbackCoordinator.play());
    }
  }

  void _applyPlaybackRate(double speed) {
    _playStateActions.setRate(speed);
    unawaited(playbackCoordinator.setRate(speed));
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
    unawaited(playbackCoordinator.seek(pos));
    _updateEffectiveBufferingState(position: pos);
    unawaited(
      playbackProgressManager.save(
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

  void _updateVolume(
    double newVolume, {
    bool syncSystemVolume = true,
  }) {
    final clampedVolume = newVolume.clamp(0.0, 100.0);
    _playStateActions.setVolume(clampedVolume);
    unawaited(playbackCoordinator.setVolume(
      SystemUtil.supportsSystemVolumeSync ? 100.0 : clampedVolume,
    ));
    if (syncSystemVolume) {
      systemVolumeSynchronizer.scheduleSync(clampedVolume / 100);
    }
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
  }

  /// 开始播放
  Future<void> startPlaying() async {
    try {
      await playbackCoordinator.play();
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
          unawaited(playbackCoordinator.pause());
          timer.cancel();
          _stopTimer = null;
        }
      });
    } else {
      _playStateActions.setScheduledStopDuration(0);
      await playbackCoordinator.pause();
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
    if (!playbackCoordinator.capabilities.supportsShader) {
      throw UnsupportedError('当前播放器内核不支持 Anime4K');
    }
    final shaders = switch (type) {
      2 => mpvAnime4KShadersLite,
      3 => mpvAnime4KShaders,
      _ => const <String>[],
    };
    await playbackCoordinator.setShaders(shaders.isEmpty
        ? ''
        : Utils.buildShadersAbsolutePath(shadersDirectory.path, shaders));
    _playStateActions.setSuperResolutionType(type == 2 || type == 3 ? type : 1);
  }

  Widget buildVideoSurface({required BoxFit fit}) {
    return playbackCoordinator.buildVideoSurface(fit: fit);
  }

  Future<Uint8List?> takeScreenshot() => playbackCoordinator.screenshot();

  Future<void> stop() => stopCurrentMedia();
}
