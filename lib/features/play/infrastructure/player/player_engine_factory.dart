import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/infrastructure/player/fvp/fvp_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/media_kit/media_kit_engine.dart';

class PlayerEngineFactory {
  const PlayerEngineFactory();

  PlayerEngine create(
    PlayerKernel kernel, {
    required bool adBlocker,
  }) {
    final hardwareDecoder = Storage.setting
        .get(PlaybackKey.hardwareDecoder, defaultValue: true) as bool;
    return switch (kernel) {
      PlayerKernel.mediaKit =>
        MediaKitEngine(adBlocker: adBlocker, hardwareDecoder: hardwareDecoder),
      PlayerKernel.fvp => FvpEngine(hardwareDecoder: hardwareDecoder),
    };
  }
}
