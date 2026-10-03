import 'package:anime_flow/core/crawler/rule_exceptions.dart';
import 'package:json_path/json_path.dart';

/// 受限 JSONPath。
///
/// 规则文件由第三方提供，**不能**把任意表达式直接交给 JSONPath 求值。
/// 这里只放行最基础、最常见的语法，其余（函数、过滤器、递归 `..`、联合等）
/// 一律拒绝，校验通过后再交给 `json_path` 解析。
class RestrictedJsonPath {
  const RestrictedJsonPath._();

  static void validate(String expression) {
    if (expression.isEmpty || !expression.startsWith(r'$')) {
      throw ApiRuleFormatException('JSONPath 必须以 \$ 开头：$expression');
    }

    var index = 1;
    while (index < expression.length) {
      final char = expression[index];

      if (char == '.') {
        index++;
        final start = index;
        while (index < expression.length &&
            RegExp(r'[A-Za-z0-9_$-]').hasMatch(expression[index])) {
          index++;
        }
        if (index == start) {
          throw ApiRuleFormatException('不支持的 JSONPath：$expression');
        }
        continue;
      }

      if (char == '[') {
        final end = _findBracketEnd(expression, index);
        final content = expression.substring(index + 1, end).trim();
        final isIndex = RegExp(r'^\d+$').hasMatch(content);
        final isWildcard = content == '*';
        final isQuoted = content.length >= 2 &&
            ((content.startsWith("'") && content.endsWith("'")) ||
                (content.startsWith('"') && content.endsWith('"')));
        if (!isIndex && !isWildcard && !isQuoted) {
          throw ApiRuleFormatException('不支持的 JSONPath 片段：[$content]');
        }
        index = end + 1;
        continue;
      }

      throw ApiRuleFormatException('不支持的 JSONPath：$expression');
    }
  }

  static int _findBracketEnd(String expression, int start) {
    String? quote;
    var escaped = false;
    for (var i = start + 1; i < expression.length; i++) {
      final char = expression[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (quote != null) {
        if (char == quote) quote = null;
        continue;
      }
      if (char == "'" || char == '"') {
        quote = char;
        continue;
      }
      if (char == ']') return i;
    }
    throw ApiRuleFormatException('JSONPath 缺少 ]：$expression');
  }

  static List<Object?> read(dynamic document, String expression) {
    validate(expression);
    try {
      return JsonPath(expression).readValues(document).toList();
    } catch (error) {
      throw ApiRuleFormatException('JSONPath 解析失败 $expression：$error');
    }
  }

  static Object? readFirst(dynamic document, String expression) {
    final values = read(document, expression);
    return values.isEmpty ? null : values.first;
  }
}
