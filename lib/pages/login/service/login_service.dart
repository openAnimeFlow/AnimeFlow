import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/repository/flow_token_storage.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:anime_flow/utils/systemUtil.dart';

typedef EmailLoginFn = Future<FlowToken> Function({
  required String email,
  required String password,
  required String platform,
});

/// 登录页业务逻辑：封装邮箱密码登录与令牌持久化。
class LoginService {
  LoginService({
    TokenRepository<FlowToken>? flowTokenRepository,
    EmailLoginFn? emailLogin,
  })  : _flowTokenRepository =
            flowTokenRepository ?? FlowTokenStorage.instance,
        _emailLogin = emailLogin ?? FlowRequest.emailLoginService;

  final TokenRepository<FlowToken> _flowTokenRepository;
  final EmailLoginFn _emailLogin;

  /// 邮箱密码登录，成功后写入本地 FlowToken。
  Future<FlowToken> login({
    required String email,
    required String password,
  }) async {
    final token = await _emailLogin(
      email: email.trim(),
      password: password,
      platform: SystemUtil.getDevice().toUpperCase(),
    );
    await _flowTokenRepository.saveToken(token);
    return token;
  }
}
