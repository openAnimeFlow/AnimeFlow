import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/composition/play_overrides.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';

final playerOverrides = [
  ...playFeatureOverrides,
  playerEngineFactoryProvider.overrideWith((ref) => (kernel,
          {required adBlocker, required hardwareDecoder}) =>
      createNativePlayerEngine(
        kernel,
        adBlocker: adBlocker,
        hardwareDecoder: hardwareDecoder,
        loadShadersDirectory: () => ref.read(shadersDirectoryProvider.future),
      )),
];
