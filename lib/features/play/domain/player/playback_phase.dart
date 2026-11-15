/// 当前播放启动流程所处的阶段
enum PlaybackPhase {
  idle,
  resolving,
  resolved,
  opening,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// 播放阶段附带的状态或失败原因
enum PlaybackNotice {
  none,
  resolvingSource,
  sourceReady,
  openingLocalVideo,
  sourceResolutionTimedOut,
  sourceNotFound,
  sourceResolutionFailed,
  localVideoNoTrack,
  localVideoValidationTimedOut,
  localVideoOpenFailed,
  localVideoPlaybackFailed,
  onlineVideoPlaybackFailed,
}

extension PlaybackPhaseX on PlaybackPhase {
  bool get isResolving => this == PlaybackPhase.resolving;

  bool get keepsStartupIndicator => switch (this) {
        PlaybackPhase.resolving ||
        PlaybackPhase.resolved ||
        PlaybackPhase.opening =>
          true,
        _ => false,
      };
}
