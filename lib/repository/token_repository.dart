/// 持久化 OAuth 等敏感令牌（实现类通常使用安全存储）。
abstract class TokenRepository<T> {
  /// 读取当前令牌；损坏或缺失时返回 `null`。
  Future<T?> getToken();

  /// 覆盖保存令牌。
  Future<void> saveToken(T token);

  /// 清除已保存的令牌。
  Future<void> removeToken();
}
