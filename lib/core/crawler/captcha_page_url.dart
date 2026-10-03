import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';

/// 验证页地址的回退链。
///
/// 优先使用规则声明的 `AntiCrawlerConfig.captchaPageUrl`；为空时回退到搜索地址；
/// API 规则没有搜索页，再回退到 API 搜索请求地址。
String captchaPageTemplate(CrawlConfigItem config) {
  final explicit = config.antiCrawlerConfig.captchaPageUrl.trim();
  if (explicit.isNotEmpty) return explicit;
  if (config.searchUrl.trim().isNotEmpty) return config.searchUrl;
  return config.searchApiConfig.request.url;
}

/// 渲染验证页地址：替换 `{keyword}`。
///
/// `@变量` 是 API 请求模板的语法，由 `RuleTemplate` 处理；验证页沿用规则里
/// 已有的 `{keyword}` 写法，替换值做 URL 编码。
String renderKeywordUrl(String template, String keyword) {
  return template.replaceAll('{keyword}', Uri.encodeQueryComponent(keyword));
}
