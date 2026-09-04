import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/infrastructure/player/fvp/fvp_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/media_kit/media_kit_engine.dart';

class PlayerEngineFactory {
  const PlayerEngineFactory();

  PlayerEngine create(
    PlayerKernel kernel, {
    required bool adBlocker,
  }) {
    return switch (kernel) {
      PlayerKernel.mediaKit => MediaKitEngine(adBlocker: adBlocker),
      PlayerKernel.fvp => FvpEngine(),
    };
  }
}
