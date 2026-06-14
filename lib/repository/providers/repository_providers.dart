/// Repository 层的 Riverpod 依赖注入入口。
///
/// 将数据访问实现注册为
/// `keepAlive` Provider，供 Controller / Notifier 通过 [Ref] 读取，
/// 避免在业务层直接依赖具体实现或单例（如 [BangumiToken.instance]）。
///
/// 使用示例：
/// ```dart
/// final tokenRepo = ref.read(tokenRepositoryProvider);
/// final userRepo = ref.read(userRepositoryProvider);
/// ```
library;
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:anime_flow/repository/flow_token_repository.dart';
import 'package:anime_flow/repository/flow_token_storage.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:anime_flow/repository/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
TokenRepository tokenRepository(Ref ref) => BangumiToken.instance;

@Riverpod(keepAlive: true)
FlowTokenRepository flowTokenRepository(Ref ref) => FlowTokenStorage.instance;

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) => UserRepository.instance;
