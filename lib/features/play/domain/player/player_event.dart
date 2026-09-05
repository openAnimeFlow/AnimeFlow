sealed class PlayerEvent {
  const PlayerEvent();
}

class PlayerPlayingChanged extends PlayerEvent {
  final bool playing;

  const PlayerPlayingChanged(this.playing);
}

class PlayerPositionChanged extends PlayerEvent {
  final Duration position;

  const PlayerPositionChanged(this.position);
}

class PlayerDurationChanged extends PlayerEvent {
  final Duration duration;

  const PlayerDurationChanged(this.duration);
}

class PlayerBufferedChanged extends PlayerEvent {
  final Duration buffered;

  const PlayerBufferedChanged(this.buffered);
}

class PlayerBufferingChanged extends PlayerEvent {
  final bool buffering;

  const PlayerBufferingChanged(this.buffering);
}

class PlayerVolumeChanged extends PlayerEvent {
  final double volume;

  const PlayerVolumeChanged(this.volume);
}

class PlayerRateChanged extends PlayerEvent {
  final double rate;

  const PlayerRateChanged(this.rate);
}

class PlayerCompleted extends PlayerEvent {
  const PlayerCompleted();
}

class PlayerError extends PlayerEvent {
  final Object error;
  final StackTrace? stackTrace;

  const PlayerError(this.error, [this.stackTrace]);
}
