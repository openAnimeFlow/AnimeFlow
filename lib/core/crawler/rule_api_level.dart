/// 规则文件与当前客户端的兼容性判定结果。
enum RuleCompatibility {
  /// 可以正常加载。
  compatible,

  /// 规则要求的客户端版本高于当前客户端。
  requiresNewerClient,

  /// `api` 字段非法（非正整数）。
  invalid,
}

/// 规则 API 级别。
///
/// 规则文件通过 `api` 字段声明「需要哪个级别的客户端」；当它高于
/// [current] 时，说明该规则用到了当前客户端尚未实现的能力，必须在
/// 导入/下载/加载阶段就拒绝或标记，而不是加载后静默失败。
///
/// 每次规则 schema 发生**破坏性变更**（新增客户端必须理解的能力）时把
/// [current] 加一；仅新增可选字段不需要递增。
class RuleApiLevel {
  /// AnimeFlow 自有的规则 API 级别，从 1 开始。
  ///
  /// 注意：不要直接沿用其它项目的规则级别编号，数值相同不代表能力相同。
  static const int current = 1;

  /// 规则未声明 `api` 字段时的默认级别（老规则视作 1）。
  static const String defaultApi = '1';

  static RuleCompatibility check(Object? rawApi) {
    final raw = rawApi?.toString().trim() ?? '';
    // 缺省按 [defaultApi] 处理：老规则没有 api 字段也要能正常加载。
    if (raw.isEmpty) return RuleCompatibility.compatible;

    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1) return RuleCompatibility.invalid;
    if (parsed > current) return RuleCompatibility.requiresNewerClient;
    return RuleCompatibility.compatible;
  }

  static bool isCompatible(Object? rawApi) =>
      check(rawApi) == RuleCompatibility.compatible;

  static bool requiresNewerClient(Object? rawApi) =>
      check(rawApi) == RuleCompatibility.requiresNewerClient;

  /// 供日志与 UI 使用的可读描述。
  static String describe(Object? rawApi, {String? ruleName}) {
    final name = ruleName == null || ruleName.isEmpty ? '' : '「$ruleName」';
    return switch (check(rawApi)) {
      RuleCompatibility.compatible => '$name规则与当前客户端兼容',
      RuleCompatibility.requiresNewerClient => '$name规则需要更高版本的 AnimeFlow'
          '（规则 API ${rawApi?.toString() ?? defaultApi}，'
          '当前 $current），请升级客户端后重试',
      RuleCompatibility.invalid =>
        '$name规则的 API 版本号非法：${rawApi?.toString() ?? ''}',
    };
  }
}
