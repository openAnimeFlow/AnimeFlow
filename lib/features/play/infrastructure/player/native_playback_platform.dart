import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/playback_platform.dart';
import 'package:anime_flow/features/play/infrastructure/player/system_volume_synchronizer.dart';
import 'package:flutter/foundation.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/vibrate.dart';
import 'package:anime_flow/core/presence/presence_service.dart';

class NativePlaybackPlatform implements PlaybackPlatform {
  @override
  List<PlayerKernel> get availableKernels => [
        PlayerKernel.mediaKit,
        PlayerKernel.fvp,
        if (!kIsWeb &&
            const {
              TargetPlatform.android,
              TargetPlatform.iOS,
              TargetPlatform.macOS
            }.contains(defaultTargetPlatform))
          PlayerKernel.videoPlayer,
      ];
  @override
  bool get supportsSystemVolumeSync => SystemUtil.supportsSystemVolumeSync;
  @override
  PlaybackVolume createVolume(void Function(double) onChange) =>
      SystemVolumeSynchronizer(onSystemVolumeChanged: onChange);
  @override
  void vibrate() => vibrateHeavy();
  @override
  void updatePresence(
          {required int subjectId,
          required int episodeId,
          required bool watching,
          required int positionSeconds}) =>
      PresenceService.instance.setPlaybackContext(
          subjectId: subjectId,
          episodeId: episodeId,
          watching: watching,
          positionSeconds: positionSeconds);
  @override
  void clearPresence() => PresenceService.instance.clearPlaybackContext();
}
