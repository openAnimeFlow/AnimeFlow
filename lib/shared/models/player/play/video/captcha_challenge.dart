/// 反反爬虫验证类型
///
/// - [imageCaptcha] (1): WebView 抓取验证码图片，引导用户手动输入后提交
/// - [autoClickButton] (2): WebView 检测到验证按钮后自动点击，无需用户交互
///
/// 保留整数表示以便将来新增第三种及更多验证方式时向后兼容。
class CaptchaType {
  static const int imageCaptcha = 1;
  static const int autoClickButton = 2;
}

abstract interface class CaptchaChallenge {
  bool get enabled;
  int get captchaType;
  String get captchaImage;
  String get captchaInput;
  String get captchaButton;
}

String renderKeywordUrl(String template, String keyword) =>
    template.replaceAll('{keyword}', Uri.encodeQueryComponent(keyword));
