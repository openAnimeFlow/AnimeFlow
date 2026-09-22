import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:anime_flow/core/presence/presence_service.dart';
import 'package:anime_flow/features/auth/application/token_providers.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_provider.g.dart';

@Riverpod(keepAlive: true)
class AccountController extends _$AccountController {
  @override
  void build() {}

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await FlowApi.changePasswordService(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    // 后端修改密码后已撤销全部会话。
    await clearUserInfo(notifyServer: false);
  }

  Future<void> clearUserInfo({bool notifyServer = true}) async {
    final repository = ref.read(flowTokenRepositoryProvider);
    FlowRefreshTokenInterceptor.invalidatePendingRefresh(repository);
    final sessionToken = await repository.getToken();
    await repository.removeToken();
    invalidateUserSession(ref);
    await PresenceService.instance.heartbeatNow();
    if (!notifyServer || sessionToken == null) return;
    FlowApi.logoutService(sessionToken: sessionToken).catchError((error) {
      LiggLogger().w('服务端登出失败: $error');
    });
  }
}
