// 规则执行过程中抛出的异常。
//
// 调用方据此区分「需要验证」「没有结果」与「请求/解析失败」三种状态，
// 而不是把所有问题都当成一种错误展示。

/// 响应中检测到验证码质询，需要走 WebView 验证流程。
class CaptchaRequiredException implements Exception {
  const CaptchaRequiredException(this.configName);

  final String configName;

  @override
  String toString() =>
      'CaptchaRequiredException: $configName requires captcha verification';
}

/// 请求成功但没有任何匹配结果。
class NoResultException implements Exception {
  const NoResultException(this.configName);

  final String configName;

  @override
  String toString() => 'NoResultException: $configName returned no results';
}

/// 搜索失败：请求准备、发送或响应解析出现问题。
class SearchErrorException implements Exception {
  const SearchErrorException(this.configName, {this.cause});

  final String configName;
  final Object? cause;

  @override
  String toString() => 'SearchErrorException: $configName search failed'
      '${cause == null ? '' : ' ($cause)'}';
}

/// 章节查询失败：请求准备、发送或响应解析出现问题。
class ChapterErrorException implements Exception {
  const ChapterErrorException(this.configName, {this.cause});

  final String configName;
  final Object? cause;

  @override
  String toString() => 'ChapterErrorException: $configName chapter query failed'
      '${cause == null ? '' : ' ($cause)'}';
}

/// API 规则配置或响应不符合预期（请求模板非法、响应不是 JSON、JSONPath 非法等）。
class ApiRuleFormatException implements Exception {
  const ApiRuleFormatException(this.message);

  final String message;

  @override
  String toString() => 'ApiRuleFormatException: $message';
}
