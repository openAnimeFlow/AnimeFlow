import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

/// 验证页检测。
///
/// 检测顺序与规则配置一致：
/// 1. 配置了 [AntiCrawlerConfig.captchaDetectValue] 时按
///    [AntiCrawlerConfig.captchaDetectType]（XPath / 文本 / 正则）判定；
/// 2. 否则回退为 [AntiCrawlerConfig.captchaImage] /
///    [AntiCrawlerConfig.captchaButton] 的 XPath 存在性判断。
///
/// 检测对象是原始响应文本，因此 HTML 与接口返回的 JSON / 文本挑战页都能处理。
class CaptchaDetector {
  const CaptchaDetector._();

  static bool detects(String raw, AntiCrawlerConfig config) {
    if (!config.enabled) return false;

    final detectValue = config.captchaDetectValue.trim();
    if (detectValue.isNotEmpty) {
      switch (config.captchaDetectType) {
        case CaptchaDetectType.text:
          return raw.contains(detectValue);
        case CaptchaDetectType.regex:
          try {
            return RegExp(
              detectValue,
              caseSensitive: false,
              dotAll: true,
            ).hasMatch(raw);
          } on FormatException {
            return false;
          }
        case CaptchaDetectType.xpath:
        default:
          return _hasNode(raw, detectValue);
      }
    }

    final fallbackSelectors = <String>[
      config.captchaImage,
      config.captchaButton,
    ].where((xpath) => xpath.trim().isNotEmpty);
    return fallbackSelectors.any((xpath) => _hasNode(raw, xpath));
  }

  static bool _hasNode(String raw, String xpath) {
    if (raw.trim().isEmpty) return false;
    try {
      final root = html_parser.parse(raw).documentElement;
      if (root == null) return false;
      return root.queryXPath(xpath).node != null;
    } catch (_) {
      return false;
    }
  }
}
