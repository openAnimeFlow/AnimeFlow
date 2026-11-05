import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';

/// 播放会话写入当前播放状态所需的操作。
abstract interface class PlayStateActions {
  void setPlaybackPhase(PlaybackPhase phase, {String? message});
  void setPlaying(bool value);
  void setPosition(Duration value);
  void setDuration(Duration value);
  void setBuffered(Duration value);
  void setBuffering(bool value);
  void setRate(double value);
  void setVolume(double value);
  void setKernel(PlayerKernel value);
  void setSwitchingKernel(bool value);
  void setUpscalePreset(UpscalePreset value);
  void setVideoFit(VideoFit value);
  void setScheduledStopDuration(int value);
}

/// 播放会话通过当前剧集列表切集及更新观看状态。
abstract interface class EpisodeActions {
  bool hasNextEpisode();
  void switchToNextEpisode();
  Future<void> updateEpisodeWatched(int episodeId, {required bool watched});
}
