import 'package:anime_flow/features/auth/application/token_providers.dart';
import 'package:anime_flow/features/user/application/account_service.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前 AnimeFlow 账号业务服务。
///
/// Provider 层负责把业务服务与 Riverpod 状态失效机制连接起来，
/// [AccountService] 本身不依赖 presentation 层。
final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService(
    tokenRepository: ref.read(flowTokenRepositoryProvider),
    onSessionCleared: () {
      ref.invalidate(currentFlowTokenProvider);
      ref.invalidate(isLoggedInProvider);
      ref.invalidate(currentUserInfoProvider);
      ref.invalidate(bangumiBindProvider);
      ref.invalidate(bgmCollectionSyncProvider);
      ref.invalidate(userCollectionsProvider);
    },
  );
});
