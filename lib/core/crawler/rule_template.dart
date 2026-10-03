import 'package:anime_flow/core/crawler/rule_exceptions.dart';

/// 规则请求 / 地址模板渲染。
///
/// 两种写法完全等价：
/// - `@name`：API 请求模板的惯用写法；
/// - `{name}`：与 XPath 规则的 `{keyword}` 风格一致。
///
/// 字符串**恰好**是整串变量（允许两侧空白）时保留变量原始类型，例如
/// `@index` 与 `{index}` 传的都是数字而不是字符串；内联场景按字符串插值；
/// [encode] 为 true 时替换值做 URL 编码。
class RuleTemplate {
  const RuleTemplate._();

  /// `@name` 形式的内联变量。
  static final RegExp _atVariable =
      RegExp(r'(?<![A-Za-z0-9_])@([A-Za-z_][A-Za-z0-9_]*)');

  /// `{name}` 形式的内联变量。
  static final RegExp _braceVariable = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}');

  static final RegExp _exactAtVariable = RegExp(r'^@([A-Za-z_][A-Za-z0-9_]*)$');

  static final RegExp _exactBraceVariable =
      RegExp(r'^\{([A-Za-z_][A-Za-z0-9_]*)\}$');

  static String render(
    String template,
    Map<String, Object?> variables, {
    bool encode = false,
  }) {
    if (template.isEmpty) return template;
    final withAt = template.replaceAllMapped(
      _atVariable,
      (match) => _renderVariable(
        match.group(1)!,
        variables,
        encode: encode,
        token: match.group(0)!,
      ),
    );
    return withAt.replaceAllMapped(
      _braceVariable,
      (match) => _renderVariable(
        match.group(1)!,
        variables,
        encode: encode,
        token: match.group(0)!,
      ),
    );
  }

  static Map<String, dynamic> renderMap(
    Map<String, dynamic> input,
    Map<String, Object?> variables,
  ) {
    return input.map(
      (key, value) => MapEntry(
        render(key, variables),
        renderValue(value, variables),
      ),
    );
  }

  static dynamic renderValue(
    dynamic value,
    Map<String, Object?> variables,
  ) {
    if (value is String) {
      final trimmed = value.trim();
      final exact = _exactAtVariable.firstMatch(trimmed) ??
          _exactBraceVariable.firstMatch(trimmed);
      if (exact != null) {
        final name = exact.group(1)!;
        if (!variables.containsKey(name)) {
          throw ApiRuleFormatException('缺少模板变量 $trimmed');
        }
        return variables[name];
      }
      return render(value, variables);
    }
    if (value is List) {
      return value.map((item) => renderValue(item, variables)).toList();
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          renderValue(item, variables),
        ),
      );
    }
    return value;
  }

  static String _renderVariable(
    String name,
    Map<String, Object?> variables, {
    required bool encode,
    required String token,
  }) {
    if (!variables.containsKey(name)) {
      throw ApiRuleFormatException('缺少模板变量 $token');
    }
    final value = variables[name]?.toString() ?? '';
    return encode ? Uri.encodeComponent(value) : value;
  }
}
