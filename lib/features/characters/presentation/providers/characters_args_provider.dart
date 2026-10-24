import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'characters_args_provider.g.dart';

/// 由路由的 ProviderScope 提供页面参数。
@Riverpod(keepAlive: true, dependencies: [])
int charactersArgs(Ref ref) {
  throw UnimplementedError('charactersArgsProvider must be overridden');
}
