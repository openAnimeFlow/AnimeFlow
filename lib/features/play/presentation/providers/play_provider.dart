import 'package:anime_flow/features/play/application/play_state_controller.dart';
import 'package:anime_flow/features/play/domain/play_state.dart';
import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_provider.g.dart';

/// 由路由的 ProviderScope 提供页面参数。
@Riverpod(dependencies: [])
PlayRouteExtra playExtra(Ref ref) {
  throw UnimplementedError('playExtraProvider must be overridden');
}

@Riverpod(dependencies: [playExtra])
class PlayStateNotifier extends _$PlayStateNotifier with PlayStateController {
  @override
  PlayState build() {
    ref.watch(playExtraProvider);
    return const PlayState();
  }
}
