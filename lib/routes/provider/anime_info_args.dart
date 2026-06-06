import 'package:anime_flow/routes/model/info_route_extra.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_info_args.g.dart';

@Riverpod(keepAlive: true, dependencies: [])
InfoRouteExtra animeInfoArgs(Ref ref) {
  throw UnimplementedError('animeInfoArgsProvider must be overridden');
}