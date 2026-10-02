import 'package:anime_flow/core/crawler/captcha_detector.dart';
import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:flutter_test/flutter_test.dart';

AntiCrawlerConfig _config({
  bool enabled = true,
  int detectType = CaptchaDetectType.xpath,
  String detectValue = '',
  String captchaImage = '',
  String captchaButton = '',
}) {
  return AntiCrawlerConfig(
    enabled: enabled,
    captchaType: CaptchaType.imageCaptcha,
    captchaImage: captchaImage,
    captchaInput: '',
    captchaButton: captchaButton,
    captchaDetectType: detectType,
    captchaDetectValue: detectValue,
  );
}

const String _captchaHtml =
    '<html><body><div class="captcha"></div></body></html>';
const String _captchaJson = '{"code":403,"msg":"请完成验证后重试"}';

void main() {
  group('CaptchaDetector', () {
    test('未启用时一律不判定为验证页', () {
      expect(
        CaptchaDetector.detects(
          _captchaHtml,
          _config(enabled: false, detectValue: '//div[@class="captcha"]'),
        ),
        isFalse,
      );
    });

    test('文本检测命中 JSON 挑战响应', () {
      expect(
        CaptchaDetector.detects(
          _captchaJson,
          _config(
            detectType: CaptchaDetectType.text,
            detectValue: '请完成验证',
          ),
        ),
        isTrue,
      );
      expect(
        CaptchaDetector.detects(
          _captchaJson,
          _config(detectType: CaptchaDetectType.text, detectValue: '不存在的文案'),
        ),
        isFalse,
      );
    });

    test('正则检测大小写不敏感且忽略换行', () {
      expect(
        CaptchaDetector.detects(
          '<html>Just a moment</html>',
          _config(
            detectType: CaptchaDetectType.regex,
            detectValue: r'just\s+a\s+moment',
          ),
        ),
        isTrue,
      );
    });

    test('非法正则返回 false 而不是抛错', () {
      expect(
        CaptchaDetector.detects(
          _captchaHtml,
          _config(detectType: CaptchaDetectType.regex, detectValue: '(['),
        ),
        isFalse,
      );
    });

    test('XPath 检测', () {
      expect(
        CaptchaDetector.detects(
          _captchaHtml,
          _config(detectValue: '//div[@class="captcha"]'),
        ),
        isTrue,
      );
      expect(
        CaptchaDetector.detects(
          _captchaHtml,
          _config(detectValue: '//div[@class="not-captcha"]'),
        ),
        isFalse,
      );
    });

    test('未配置 detectValue 时回退到验证码元素 XPath', () {
      expect(
        CaptchaDetector.detects(
          _captchaHtml,
          _config(captchaButton: '//div[@class="captcha"]'),
        ),
        isTrue,
      );
      expect(
        CaptchaDetector.detects(
          _captchaHtml,
          _config(captchaImage: '//img[@id="cap"]'),
        ),
        isFalse,
      );
    });

    test('空响应不判定为验证页', () {
      expect(
        CaptchaDetector.detects(
          '   ',
          _config(detectValue: '//div[@class="captcha"]'),
        ),
        isFalse,
      );
    });
  });
}
