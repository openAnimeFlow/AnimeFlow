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
///
/// 当前编号：
/// - [legacyXpath]（1）：只有 XPath 字段的旧规则，也是未声明 `api` 的缺省；
/// - [apiMode]（2）：使用 API 模式（`searchMode` / `chapterMode` 为 `api`，
///   依赖 `searchApiConfig` / `chapterApiConfig`）的规则。
///
/// 判定是「规则声明的级别 <= 客户端级别」，因此高版本客户端天然兼容
/// 低级别规则（向下兼容）。
class RuleApiLevel {
  /// 纯 XPath 规则所需的级别。
  ///
  /// 注意：不要直接沿用其它项目的规则级别编号，数值相同不代表能力相同。
  static const int legacyXpath = 1;

  /// 使用 API 模式的规则所需的级别。
  static const int apiMode = 2;

  /// 当前客户端支持的规则 API 级别。
  static const int current = apiMode;

  /// 规则未声明 `api` 字段时的默认级别（老规则视作 1）。
  static const String defaultApi = '1';

  /// 规则自身内容所需的最低级别。
  static int requiredFor({
    required bool usesApiSearch,
    required bool usesApiChapter,
  }) {
    return (usesApiSearch || usesApiChapter) ? apiMode : legacyXpath;
  }

  /// 保存规则时应写入的 `api` 值。
  ///
  /// 取「规则内容所需级别」与「原有声明」中较高者：API 模式规则至少声明
  /// [apiMode]，同时不会把导入时已有的更高声明降级。
  static String declarationFor({
    required bool usesApiSearch,
    required bool usesApiChapter,
    String? declared,
  }) {
    final required = requiredFor(
      usesApiSearch: usesApiSearch,
      usesApiChapter: usesApiChapter,
    );
    final parsed = int.tryParse(declared?.trim() ?? '');
    final value = (parsed != null && parsed > required) ? parsed : required;
    return value.toString();
  }

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
