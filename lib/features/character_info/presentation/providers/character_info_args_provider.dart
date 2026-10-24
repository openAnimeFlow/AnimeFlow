import 'package:anime_flow/shared/navigation/args/character_info_extra.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_info_args_provider.g.dart';

/// 由路由的 ProviderScope 提供页面参数。
@Riverpod(keepAlive: true, dependencies: [])
CharacterInfoExtra characterInfoArgs(Ref ref) {
  throw UnimplementedError('characterInfoArgsProvider must be overridden');
}
