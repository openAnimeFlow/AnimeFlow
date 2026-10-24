import 'playback_source.dart';
import 'video_fit.dart';

class PlayerSnapshot {
  final PlaybackSource? source;
  final Duration position;
  final double volume;
  final double rate;
  final bool wasPlaying;
  final VideoFit fit;

  const PlayerSnapshot({
    required this.source,
    required this.position,
    required this.volume,
    required this.rate,
    required this.wasPlaying,
    required this.fit,
  });
}
