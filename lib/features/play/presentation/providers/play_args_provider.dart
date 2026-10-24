import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_args_provider.g.dart';

/// 由路由的 ProviderScope 提供页面参数。
@Riverpod(dependencies: [])
PlayRouteExtra playExtra(Ref ref) {
  throw UnimplementedError('playExtraProvider must be overridden');
}
