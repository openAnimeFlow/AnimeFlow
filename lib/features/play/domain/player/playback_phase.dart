/// 当前播放启动流程所处的阶段。
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

extension PlaybackPhaseX on PlaybackPhase {
  bool get isResolving => this == PlaybackPhase.resolving;

  bool get keepsStartupIndicator => switch (this) {
        PlaybackPhase.resolving ||
        PlaybackPhase.resolved ||
        PlaybackPhase.opening => true,
        _ => false,
      };
}
