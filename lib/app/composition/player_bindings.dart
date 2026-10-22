import 'package:anime_flow/features/play/application/player_bindings.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';

final playerOverrides = [
  playerEngineFactoryProvider.overrideWithValue(createNativePlayerEngine),
];
