import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';

/// 当前 AnimeFlow 账号的业务操作。
///
/// OAuth 授权状态由 UserOAuthController 管理；本服务只负责账号会话
/// 和密码等账号级操作。
class AccountService {
  const AccountService({
    required TokenRepository<FlowToken> tokenRepository,
    required void Function() onSessionCleared,
  })  : _tokenRepository = tokenRepository,
        _onSessionCleared = onSessionCleared;

  final TokenRepository<FlowToken> _tokenRepository;
  final void Function() _onSessionCleared;

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
    FlowRefreshTokenInterceptor.invalidatePendingRefresh(_tokenRepository);
    final sessionToken = await _tokenRepository.getToken();
    await _tokenRepository.removeToken();
    _onSessionCleared();
    if (!notifyServer || sessionToken == null) return;
    FlowApi.logoutService(sessionToken: sessionToken).catchError((error) {
      LiggLogger().w('服务端登出失败: $error');
    });
  }
}
