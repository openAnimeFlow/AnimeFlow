import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:anime_flow/features/auth/application/token_providers.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前 AnimeFlow 账号的业务操作。
///
/// OAuth 授权状态由 [UserOAuthController] 管理；本服务只负责账号会话
/// 和密码等账号级操作，避免把无状态业务混入 OAuth 状态控制器。
class AccountService {
  const AccountService(this._ref);

  final Ref _ref;

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await FlowApi.changePasswordService(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    // 后端修改密码后已撤销全部会话，无需再调用登出接口。
    await clearUserInfo(notifyServer: false);
  }

  Future<void> clearUserInfo({bool notifyServer = true}) async {
    final repository = _ref.read(flowTokenRepositoryProvider);
    FlowRefreshTokenInterceptor.invalidatePendingRefresh(repository);
    final sessionToken = await repository.getToken();
    await repository.removeToken();
    _ref.invalidate(currentFlowTokenProvider);
    _ref.invalidate(isLoggedInProvider);
    _ref.invalidate(currentUserInfoProvider);
    _ref.invalidate(bangumiBindProvider);
    _ref.invalidate(bgmCollectionSyncProvider);
    _ref.invalidate(userCollectionsProvider);
    if (!notifyServer || sessionToken == null) return;
    FlowApi.logoutService(sessionToken: sessionToken).catchError((error) {
      LiggLogger().w('服务端登出失败: $error');
    });
  }
}

final accountServiceProvider = Provider<AccountService>(
  (ref) => AccountService(ref),
);
