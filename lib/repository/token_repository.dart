import 'package:anime_flow/models/item/token_item.dart';

/// 持久化 OAuth 等敏感令牌（实现类通常使用安全存储）。
abstract class TokenRepository {
  /// 读取当前令牌；损坏或缺失时返回 `null`。
  Future<TokenItem?> getToken();

  /// 覆盖保存令牌。
  Future<void> saveToken(TokenItem token);

  /// 清除已保存的令牌。
  Future<void> removeToken();
}
