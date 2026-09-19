import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_session.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/application/system_volume_synchronizer.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/presence/presence_service.dart';
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
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:anime_flow/features/play/application/playback_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'play_provider.g.dart';

@Riverpod(
  keepAlive: true,
  dependencies: [
    shadersDirectory,
    PlayStateNotifier,
    DanmakuStateNotifier,
    VideoUiNotifier,
    Episodes,
    playExtra,
  ],
)
PlaySession playSession(Ref ref) {
  ref.watch(playExtraProvider);
  // 模式变化由下方 ref.listen 处理，不能 watch 重建整个播放会话。
  final initialDanmakuChineseMode = ref.read(danmakuChineseModeProvider);
  final playStateActions = ref.watch(playStateProvider.notifier);
  final danmaku = DanmakuSession(
    store: ref.watch(danmakuStateProvider.notifier),
    converter: ref.watch(danmakuChineseConverterProvider),
    initialChineseMode: initialDanmakuChineseMode,
    readPlayback: () {
      final state = playStateActions.value;
      return DanmakuPlaybackSnapshot(
        position: state.position,
        duration: state.duration,
        playing: state.playing,
      );
    },
    currentUserId: () => ref.read(currentUserInfoProvider).value?.id,
  );
  final controller = PlaySession(
    shadersDirectory: ref.watch(shadersDirectoryProvider).requireValue,
    playStateActions: playStateActions,
    videoUiStateActions: ref.watch(videoUiProvider.notifier),
    episodesActions: ref.watch(episodesProvider.notifier),
    danmaku: danmaku,
    engineFactory: const PlayerEngineFactory(),
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
        unawaited(danmaku.applyChineseMode(next));
      }
    },
  );

  ref.listen<PlayState>(
    playStateProvider,
    (previous, next) {
      controller._handlePlayStateChanged(
        next,
        isLoggedIn: ref.read(isLoggedInProvider).value ?? false,
      );
      controller._handlePlaybackPhaseChanged(
        previous?.phase,
        next.phase,
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
    return const PlayState();
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

  void setPlaybackPhase(PlaybackPhase phase, {String? message}) {
    state = state.copyWith(
      phase: phase,
      statusMessage: message ?? '',
    );
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

class PlayState {
  final PlayerKernel kernel;
  final bool switchingKernel;
  final int superResolutionType;
  final bool isWideScreen;
  final bool isContentExpanded;
  final bool isFullscreen;
  final BoxFit videoFit;
  final PlaybackPhase phase;
  final String statusMessage;
  final bool playing;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final double volume;
  final bool isVerticalDragging;
  final double rate;
  final bool buffering;
  final int scheduledStopDuration;

  const PlayState({
    this.kernel = PlayerKernel.mediaKit,
    this.switchingKernel = false,
    this.superResolutionType = 0,
    this.isWideScreen = false,
    this.isContentExpanded = true,
    this.isFullscreen = false,
    this.videoFit = BoxFit.contain,
    this.phase = PlaybackPhase.idle,
    this.statusMessage = '',
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

  PlayState copyWith({
    PlayerKernel? kernel,
    bool? switchingKernel,
    int? superResolutionType,
    bool? isWideScreen,
    bool? isContentExpanded,
    bool? isFullscreen,
    BoxFit? videoFit,
    PlaybackPhase? phase,
    String? statusMessage,
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
    return PlayState(
      kernel: kernel ?? this.kernel,
      switchingKernel: switchingKernel ?? this.switchingKernel,
      superResolutionType: superResolutionType ?? this.superResolutionType,
      isWideScreen: isWideScreen ?? this.isWideScreen,
      isContentExpanded: isContentExpanded ?? this.isContentExpanded,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      videoFit: videoFit ?? this.videoFit,
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
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
  PlaySession({
    required this.shadersDirectory,
    required PlayStateNotifier playStateActions,
    required VideoUiStateActions videoUiStateActions,
    required Episodes episodesActions,
    required this.danmaku,
    required this.engineFactory,
    required void Function({
      required int subjectId,
      required int episodeId,
      required bool watched,
    }) setEpisodeWatched,
  })  : _playStateActions = playStateActions,
        _videoUiStateActions = videoUiStateActions,
        _episodesActions = episodesActions,
        _setEpisodeWatched = setEpisodeWatched;

  final PlayerEngineFactory engineFactory;
  late final PlaybackCoordinator playbackCoordinator;
  late final PlaybackProgressManager playbackProgressManager;
  final PlayStateNotifier _playStateActions;
  final VideoUiStateActions _videoUiStateActions;
  final Episodes _episodesActions;
  final DanmakuSession danmaku;
  final void Function({
    required int subjectId,
    required int episodeId,
    required bool watched,
  }) _setEpisodeWatched;

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

  /// 记录原始倍速
  double? _speedBeforeBoost;
  bool _isSpeedBoosting = false;

  /// 垂直拖动相关
  double _dragStartVolume = 100.0;

  late final SystemVolumeSynchronizer systemVolumeSynchronizer;

  /// 定时停止播放的计时器
  Timer? _stopTimer;

  bool _isPlayerBuffering = false;
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
    final adBlocker = AppSettings.adBlocker;
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
        final previous = AppSettings.hardwareDecoder;
        if (previous == enabled) return true;
        await AppSettings.setHardwareDecoder(enabled);
        var applied = false;
        try {
          applied =
              await _switchKernel(playbackCoordinator.kernel, force: true);
          return applied;
        } finally {
          if (!_isDisposed) _playStateActions.setSwitchingKernel(false);
          if (!applied) {
            await AppSettings.setHardwareDecoder(previous);
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
      // 系统音量已控制输出响度，重建时不能再叠加到播放器内部音量。
      volume: SystemUtil.supportsSystemVolumeSync ? 100.0 : state.volume,
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
        AppSettings.setPreferredPlayerKernel(target.name),
      );
    } else {
      LiggLogger().e('切换播放器内核失败: $target');
    }
    _playStateActions.setSwitchingKernel(false);
    return switched;
  }

  PlayerKernel _readPreferredPlayerKernel() {
    final value = AppSettings.preferredPlayerKernelName;
    return PlayerKernel.values.firstWhere(
      (kernel) => kernel.name == value,
      orElse: () => PlayerKernel.mediaKit,
    );
  }

  void _handlePlayerEvent(PlayerEvent event) {
    if (event is PlayerPlayingChanged) {
      playbackProgressManager.saveAfterPlaybackChange();
      _playStateActions.setPlaying(event.playing);
      if (event.playing) {
        _playStateActions.setPlaybackPhase(PlaybackPhase.playing);
      } else if (_playStateActions.value.phase == PlaybackPhase.playing ||
          _playStateActions.value.phase == PlaybackPhase.buffering) {
        _playStateActions.setPlaybackPhase(PlaybackPhase.paused);
      }
      danmaku.onPlaybackChanged(event.playing);
    } else if (event is PlayerVolumeChanged) {
      if (!SystemUtil.supportsSystemVolumeSync) {
        _playStateActions.setVolume(event.volume);
      }
    } else if (event is PlayerBufferedChanged) {
      _playStateActions.setBuffered(event.buffered);
      _updateEffectiveBufferingState(buffered: event.buffered);
    } else if (event is PlayerBufferingChanged) {
      _isPlayerBuffering = event.buffering;
      if (event.buffering &&
          _playStateActions.value.phase != PlaybackPhase.resolving) {
        _playStateActions.setPlaybackPhase(PlaybackPhase.buffering);
      } else if (!event.buffering &&
          _playStateActions.value.phase == PlaybackPhase.buffering) {
        _playStateActions.setPlaybackPhase(
          _playStateActions.value.playing
              ? PlaybackPhase.playing
              : PlaybackPhase.paused,
        );
      }
      _updateEffectiveBufferingState(playerBuffering: event.buffering);
    } else if (event is PlayerRateChanged) {
      _playStateActions.setRate(event.rate);
    } else if (event is PlayerPositionChanged) {
      _playStateActions.setPosition(event.position);
      _updateEffectiveBufferingState(position: event.position);
    } else if (event is PlayerDurationChanged) {
      _playStateActions.setDuration(event.duration);
    } else if (event is PlayerCompleted) {
      _playStateActions.setPlaybackPhase(PlaybackPhase.completed);
      if (subjectId > 0) {
        _autoSwitchToNextEpisode();
        unawaited(PlayHistoryService.clearPosition(subjectId));
      }
    } else if (event is PlayerError) {
      LiggLogger().e('播放器错误: ${event.error}', error: event.stackTrace);
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

  void _handlePlaybackPhaseChanged(
    PlaybackPhase? previousPhase,
    PlaybackPhase nextPhase,
  ) {
    if (previousPhase == nextPhase) {
      return;
    }
    if (nextPhase == PlaybackPhase.playing ||
        nextPhase == PlaybackPhase.buffering ||
        nextPhase == PlaybackPhase.paused ||
        nextPhase == PlaybackPhase.completed) {
      _videoUiStateActions.finishParsingIndicator();
    }
  }

  /// 选中集与当前播放集不一致时清空弹幕数据与画布（切换集过程中）
  void clearDanmakuIfEpisodeMismatch(int selectedIndex) {
    if (selectedIndex != episode) {
      try {
        danmaku.clear();
        danmaku.beginPlaybackChange();
      } catch (_) {}
    }
  }

  void dispose() {
    _isDisposed = true;
    danmaku.dispose();
    unawaited(playbackProgressManager.save());
    if (Platform.isWindows) {
      WindowsTitleBarVisibility.reset();
    }
    systemVolumeSynchronizer.dispose();
    _stopTimer?.cancel();
    unawaited(_playerSubscription?.cancel());
    _playerSubscription = null;
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
    danmaku.beginPlaybackChange();
    await _serializePlaybackChange(() async {
      if (_isDisposed) return;
      cancelScheduledStop();
      _currentSource = null;
      await playbackCoordinator.stop();
      if (_isDisposed) return;
      danmaku.clearCanvas();
    });
  }

  /// 初始化播放状态
  Future<void> initPlayState(PlayRequest state) async {
    if (_isDisposed) return;
    _playStateActions.setPlaybackPhase(
      PlaybackPhase.opening,
      message: '资源解析成功，准备播放',
    );
    danmaku.beginPlaybackChange();
    final requestId = ++_playRequestId;
    int? automaticDanmakuRequestId;
    await _serializePlaybackChange(() async {
      if (!_isCurrentPlayRequest(requestId)) return;
      cancelScheduledStop();
      _currentSource = null;
      await playbackCoordinator.stop();
      if (!_isCurrentPlayRequest(requestId)) return;
      danmaku.clear();
      automaticDanmakuRequestId = danmaku.requestId;
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
      danmaku.setPlaybackContext(
        subjectId: subjectId,
        episode: episode,
        isLocalPlayback: isLocalPlayback,
      );
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
      _currentSource = state.isLocalPlayback
          ? PlaybackSource.localFile(state.videoUrl)
          : PlaybackSource(uri: Uri.parse(state.videoUrl));
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
    await danmaku.loadEpisode(
      subjectId: state.subjectId,
      episode: state.episodeIndex,
      isLocalPlayback: state.isLocalPlayback,
      localPath: state.localDanmakuPath,
      expectedRequestId: automaticDanmakuRequestId!,
      isPlaybackCurrent: () => _isCurrentPlayRequest(requestId),
    );
  }

  void _handlePlayStateChanged(PlayState state, {required bool isLoggedIn}) {
    if (state.phase.keepsStartupIndicator) {
      _videoUiStateActions.showParsingIndicator();
    }
    playbackProgressManager.updatePlaybackState(
      position: state.position,
      duration: state.duration,
      playing: state.playing,
      isLoggedIn: isLoggedIn,
    );
    if (subjectId > 0 && episodeId > 0) {
      PresenceService.instance.setPlaybackContext(
        subjectId: subjectId,
        episodeId: episodeId,
        watching: state.playing || state.buffering,
        positionSeconds: state.position.inSeconds,
      );
    }
  }

  ///更新缓冲状态
  void _updateBufferingState(bool buffering) {
    _videoUiStateActions.updateBufferingIndicator(
      buffering,
      isParsing: _playStateActions.value.phase.isResolving,
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

  void switchToNextEpisode() => _episodesActions.switchToNextEpisode();

  /// 切换视频画面填充模式
  void toggleVideoFit(BoxFit fits) {
    _playStateActions.setVideoFit(fits);
  }

  ///暂停/播放
  void playOrPauseVideo() {
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
    danmaku.onSeek();
    unawaited(playbackCoordinator.seek(pos));
    _updateEffectiveBufferingState(position: pos);
    playbackProgressManager.saveAfterSeek(pos);
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
