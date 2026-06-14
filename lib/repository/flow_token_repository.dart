import 'package:anime_flow/models/item/flow/flow_token.dart';

/// 持久化 AnimeFlow 账号令牌（邮箱登录 / 刷新）。
abstract class FlowTokenRepository {
  Future<FlowToken?> getToken();

  Future<void> saveToken(FlowToken token);

  Future<void> removeToken();
}
