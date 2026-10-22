import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final playerEngineFactoryProvider = Provider<PlayerEngineFactory>(
  (ref) =>
      throw StateError('PlayerEngineFactory must be configured by the app'),
);
