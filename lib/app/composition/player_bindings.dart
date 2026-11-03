import 'package:anime_flow/features/play/application/player_bindings.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';

final playerOverrides = [
  playerEngineFactoryProvider.overrideWith((ref) => (kernel,
          {required adBlocker, required hardwareDecoder}) =>
      createNativePlayerEngine(
        kernel,
        adBlocker: adBlocker,
        hardwareDecoder: hardwareDecoder,
        loadShadersDirectory: () => ref.read(shadersDirectoryProvider.future),
      )),
];
