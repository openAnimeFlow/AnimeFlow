import 'package:hive_ce/hive.dart';

part 'anti_crawler_config.g.dart';

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

/// 验证页检测方式
class CaptchaDetectType {
  /// 用 XPath 在响应里查找元素
  static const int xpath = 1;

  /// 响应中包含指定文本
  static const int text = 2;

  /// 响应匹配指定正则
  static const int regex = 3;
}

/// 反反爬虫配置
///
/// 当网站对搜索请求返回验证码时，使用 WebView 加载搜索页，
/// 根据 [captchaType] 采用不同策略完成验证，之后保存 Cookie 用于后续请求。
@HiveType(typeId: 13)
class AntiCrawlerConfig {
  /// 是否启用反反爬虫功能
  @HiveField(0)
  bool enabled;

  /// 验证类型，见 [CaptchaType] 中的常量
  ///
  /// - [CaptchaType.imageCaptcha] (1)：图片验证码，需要用户手动输入
  /// - [CaptchaType.autoClickButton] (2)：自动点击验证按钮，无需用户交互
  @HiveField(1)
  int captchaType;

  /// 验证码图片元素的 XPath 选择器（仅 captchaType == 1 时使用）
  /// 用于在 WebView 页面中定位验证码图片，通过 Canvas 抓取其像素
  @HiveField(2)
  String captchaImage;

  /// 验证码输入框元素的 XPath 选择器（仅 captchaType == 1 时使用）
  /// 用于在 WebView 页面中定位供用户输入验证码的 input 元素
  @HiveField(3)
  String captchaInput;

  /// 验证按钮元素的 XPath 选择器
  ///
  /// - captchaType == 1：提交验证码的按钮，模拟点击提交
  /// - captchaType == 2：目标验证按钮（如"我不是机器人"），检测到后自动点击
  @HiveField(4)
  String captchaButton;

  /// 验证页检测方式，见 [CaptchaDetectType]
  ///
  /// 仅当 [captchaDetectValue] 非空时生效；否则回退为
  /// [captchaImage] / [captchaButton] 的 XPath 存在性判断。
  @HiveField(5)
  int captchaDetectType;

  /// 验证页检测内容，含义取决于 [captchaDetectType]
  @HiveField(6)
  String captchaDetectValue;

  /// 加载验证页的地址
  ///
  /// API 规则没有可供 WebView 加载的搜索页，验证时需要显式指定；
  /// 留空时回退到规则的搜索地址。支持 `{keyword}` 占位符。
  @HiveField(7)
  String captchaPageUrl;

  /// 自定义 JS 验证脚本（预留，当前未使用）
  @HiveField(8)
  String captchaScript;

  AntiCrawlerConfig({
    required this.enabled,
    required this.captchaType,
    required this.captchaImage,
    required this.captchaInput,
    required this.captchaButton,
    int? captchaDetectType,
    String? captchaDetectValue,
    String? captchaPageUrl,
    String? captchaScript,
  })  : captchaDetectType = captchaDetectType ?? CaptchaDetectType.xpath,
        captchaDetectValue = captchaDetectValue ?? '',
        captchaPageUrl = captchaPageUrl ?? '',
        captchaScript = captchaScript ?? '';

  factory AntiCrawlerConfig.fromJson(Map<String, dynamic> json) {
    return AntiCrawlerConfig(
      enabled: json['enabled'] ?? false,
      captchaType: json['captchaType'] ?? CaptchaType.imageCaptcha,
      captchaImage: json['captchaImage'] ?? '',
      captchaInput: json['captchaInput'] ?? '',
      captchaButton: json['captchaButton'] ?? '',
      captchaDetectType: json['captchaDetectType'],
      captchaDetectValue: json['captchaDetectValue'],
      captchaPageUrl: json['captchaPageUrl'],
      captchaScript: json['captchaScript'],
    );
  }

  factory AntiCrawlerConfig.empty() {
    return AntiCrawlerConfig(
      enabled: false,
      captchaType: CaptchaType.imageCaptcha,
      captchaImage: '',
      captchaInput: '',
      captchaButton: '',
      captchaDetectType: CaptchaDetectType.xpath,
      captchaDetectValue: '',
      captchaPageUrl: '',
      captchaScript: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'captchaType': captchaType,
      'captchaImage': captchaImage,
      'captchaInput': captchaInput,
      'captchaButton': captchaButton,
      'captchaDetectType': captchaDetectType,
      'captchaDetectValue': captchaDetectValue,
      'captchaPageUrl': captchaPageUrl,
      'captchaScript': captchaScript,
    };
  }

  AntiCrawlerConfig copyWith({
    bool? enabled,
    int? captchaType,
    String? captchaImage,
    String? captchaInput,
    String? captchaButton,
    int? captchaDetectType,
    String? captchaDetectValue,
    String? captchaPageUrl,
    String? captchaScript,
  }) {
    return AntiCrawlerConfig(
      enabled: enabled ?? this.enabled,
      captchaType: captchaType ?? this.captchaType,
      captchaImage: captchaImage ?? this.captchaImage,
      captchaInput: captchaInput ?? this.captchaInput,
      captchaButton: captchaButton ?? this.captchaButton,
      captchaDetectType: captchaDetectType ?? this.captchaDetectType,
      captchaDetectValue: captchaDetectValue ?? this.captchaDetectValue,
      captchaPageUrl: captchaPageUrl ?? this.captchaPageUrl,
      captchaScript: captchaScript ?? this.captchaScript,
    );
  }
}
