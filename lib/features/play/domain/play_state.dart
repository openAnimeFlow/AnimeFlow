import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';

/// 当前播放会话的不可变状态。
class PlayState {
  final PlayerKernel kernel;
  final bool switchingKernel;

  /// 超分辨率挡位
  final UpscalePreset upscalePreset;
  final VideoFit videoFit;
  final PlaybackPhase phase;
  final String statusMessage;
  final bool playing;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final double volume;
  final double rate;
  final bool buffering;
  final int scheduledStopDuration;

  const PlayState({
    this.kernel = PlayerKernel.mediaKit,
    this.switchingKernel = false,
    this.upscalePreset = UpscalePreset.off,
    this.videoFit = VideoFit.contain,
    this.phase = PlaybackPhase.idle,
    this.statusMessage = '',
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.volume = 100.0,
    this.rate = 1.0,
    this.buffering = false,
    this.scheduledStopDuration = 0,
  });

  PlayState copyWith({
    PlayerKernel? kernel,
    bool? switchingKernel,
    UpscalePreset? upscalePreset,
    VideoFit? videoFit,
    PlaybackPhase? phase,
    String? statusMessage,
    bool? playing,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    double? volume,
    double? rate,
    bool? buffering,
    int? scheduledStopDuration,
  }) {
    return PlayState(
      kernel: kernel ?? this.kernel,
      switchingKernel: switchingKernel ?? this.switchingKernel,
      upscalePreset: upscalePreset ?? this.upscalePreset,
      videoFit: videoFit ?? this.videoFit,
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
      playing: playing ?? this.playing,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      buffering: buffering ?? this.buffering,
      scheduledStopDuration:
          scheduledStopDuration ?? this.scheduledStopDuration,
    );
  }
}
