import 'dart:io';

import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/infrastructure/player/fvp/fvp_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/media_kit/media_kit_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/video_player/video_player_engine.dart';

PlayerEngine createNativePlayerEngine(
  PlayerKernel kernel, {
  required bool adBlocker,
  required bool hardwareDecoder,
  required Future<Directory> Function() loadShadersDirectory,
}) {
  switch (kernel) {
    case PlayerKernel.mediaKit:
      return MediaKitEngine(
          adBlocker: adBlocker,
          hardwareDecoder: hardwareDecoder,
          loadShadersDirectory: loadShadersDirectory);
    case PlayerKernel.fvp:
      return FvpEngine(hardwareDecoder: hardwareDecoder);
    case PlayerKernel.videoPlayer:
      if (!kernel.isSupported) {
        throw UnsupportedError('Video Player is unavailable on this platform');
      }
      return VideoPlayerEngine();
  }
}
