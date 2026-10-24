import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_info_args_provider.g.dart';

/// 由路由的 ProviderScope 提供页面参数。
@Riverpod(keepAlive: true, dependencies: [])
InfoRouteExtra animeInfoArgs(Ref ref) {
  throw UnimplementedError('animeInfoArgsProvider must be overridden');
}
