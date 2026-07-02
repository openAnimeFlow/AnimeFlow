import 'package:anime_flow/routes/model/character_info_extra.dart';
import 'package:anime_flow/routes/model/info_route_extra.dart';
import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'routes_args.g.dart';

@Riverpod(keepAlive: true, dependencies: [])
InfoRouteExtra animeInfoArgs(Ref ref) {
  throw UnimplementedError('animeInfoArgsProvider must be overridden');
}

@Riverpod(keepAlive: true, dependencies: [])
int charactersArgs(Ref ref) {
  throw UnimplementedError('charactersArgsProvider must be overridden');
}

@Riverpod(keepAlive: true, dependencies: [])
CharacterInfoExtra characterInfoArgs(Ref ref) {
  throw UnimplementedError('characterInfoArgsProvider must be overridden');
}

@Riverpod(dependencies: [])
PlayRouteExtra playExtra(Ref ref) {
  throw UnimplementedError('playExtraProvider must be overridden');
}