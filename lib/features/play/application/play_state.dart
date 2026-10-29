import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';

/// 当前播放会话的不可变状态，由 PlayStateNotifier 管理更新。
class PlayState {
  final PlayerKernel kernel;
  final bool switchingKernel;
  final int superResolutionType;
  final bool isWideScreen;
  final bool isContentExpanded;
  final bool isFullscreen;
  final VideoFit videoFit;
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
    this.videoFit = VideoFit.contain,
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
    VideoFit? videoFit,
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
