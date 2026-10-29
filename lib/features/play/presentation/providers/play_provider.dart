import 'package:anime_flow/features/play/application/play_state.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';
import 'package:anime_flow/features/play/presentation/providers/play_args_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_provider.g.dart';

@Riverpod(dependencies: [playExtra])
class PlayStateNotifier extends _$PlayStateNotifier {
  @override
  PlayState build() {
    ref.watch(playExtraProvider);
    return const PlayState();
  }

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

  void setVideoFit(VideoFit value) {
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
