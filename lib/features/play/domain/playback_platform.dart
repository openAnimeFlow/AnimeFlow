import 'package:anime_flow/features/play/domain/player/player_kernel.dart';

abstract interface class PlaybackPlatform {
  List<PlayerKernel> get availableKernels;
  bool get supportsSystemVolumeSync;
  PlaybackVolume createVolume(void Function(double) onChange);
  void vibrate();
  void updatePresence(
      {required int subjectId,
      required int episodeId,
      required bool watching,
      required int positionSeconds});
  void clearPresence();
}

abstract interface class PlaybackVolume {
  Future<void> initialize();
  void scheduleSync(double normalizedVolume);
  void dispose();
}
