import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/domain/play_session_actions.dart';
import 'package:anime_flow/features/play/domain/play_state.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';

mixin PlayStateController implements PlayStateActions {
  PlayState get state;
  set state(PlayState next);

  @override
  void setKernel(PlayerKernel value) {
    if (state.kernel == value) return;
    state = state.copyWith(kernel: value);
  }

  @override
  void setSwitchingKernel(bool value) {
    if (state.switchingKernel == value) return;
    state = state.copyWith(switchingKernel: value);
  }

  @override
  void setUpscalePreset(UpscalePreset value) {
    state = state.copyWith(upscalePreset: value);
  }

  @override
  void setVideoFit(VideoFit value) {
    if (state.videoFit == value) return;
    state = state.copyWith(videoFit: value);
  }

  @override
  void setPlaybackPhase(PlaybackPhase phase, {String? message}) {
    state = state.copyWith(
      phase: phase,
      statusMessage: message ?? '',
    );
  }

  @override
  void setPlaying(bool value) {
    state = state.copyWith(playing: value);
  }

  @override
  void setPosition(Duration value) {
    state = state.copyWith(position: value);
  }

  @override
  void setDuration(Duration value) {
    state = state.copyWith(duration: value);
  }

  @override
  void setBuffered(Duration value) {
    state = state.copyWith(buffered: value);
  }

  @override
  void setVolume(double value) {
    state = state.copyWith(volume: value);
  }

  @override
  void setRate(double value) {
    state = state.copyWith(rate: value);
  }

  @override
  void setBuffering(bool value) {
    state = state.copyWith(buffering: value);
  }

  @override
  void setScheduledStopDuration(int value) {
    state = state.copyWith(scheduledStopDuration: value);
  }
}
