import 'dart:async';

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/crawler/api_crawler.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/clients/plugin_site_client.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/search_resources_item.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

import 'cookie_manager.dart';
import 'html_crawler.dart';

/// 搜索响应中检测到验证码质询时抛出
class CaptchaRequiredException implements Exception {
  final String configName;

  const CaptchaRequiredException(this.configName);

  @override
  String toString() =>
      'CaptchaRequiredException: $configName requires captcha verification';
}

/// 统一后的规则请求描述。
///
/// XPath 与 API 两种模式都先把配置渲染成 [PreparedRuleRequest]，
/// 再交给同一套发送逻辑（Cookie / 请求头 / 请求体 / 重试 / 反爬检测）。
class PreparedRuleRequest {
  const PreparedRuleRequest({
    required this.method,
    required this.url,
    this.headers = const <String, dynamic>{},
    this.query = const <String, dynamic>{},
    this.bodyType = ApiBodyType.none,
    this.body,
    this.includeCookies = false,
  });

  /// 仅 GET / POST。
  final String method;

  final String url;

  final Map<String, dynamic> headers;

  final Map<String, dynamic> query;

  /// 见 [ApiBodyType]。
  final String bodyType;

  final Object? body;

  /// 是否附带该规则已保存的 Cookie。
  ///
  /// 搜索与 API 请求附带；XPath 章节请求沿用既有行为，不附带。
  final bool includeCookies;
}

/// 规则请求的传输实现。
///
/// 默认走 [PluginSiteClient]；测试可替换它，从而在不发真实请求的前提下
/// 验证「模式分派 + 请求模板渲染」的结果。
typedef RuleRequestTransport = Future<String> Function(
  PreparedRuleRequest request,
  CrawlConfigItem config,
);

/// 规则请求入口：按配置的解析模式分派到 XPath 或 API 实现。
class RuleRequest {
  static LiggLogger logger = LiggLogger();
  static const int _maxAttempts = 3;

  /// 传输实现，默认 [_send]。
  static RuleRequestTransport transport = _send;

  /// 搜索条目列表
  static Future<List<SearchResourcesItem>> searchSubjects(
    String keyword,
    CrawlConfigItem crawlConfig,
  ) async {
    final request = crawlConfig.usesApiSearch
        ? _prepareApiSearchRequest(keyword, crawlConfig)
        : _prepareXPathSearchRequest(keyword, crawlConfig);
    final response = await _sendWithRetry(request, crawlConfig);

    if (crawlConfig.usesApiSearch) {
      return ApiCrawler.parseSearch(response, crawlConfig.searchApiConfig);
    }
    return HtmlCrawler.parseSearch(response, crawlConfig);
  }

  /// 剧集资源列表
  static Future<List<CrawlerEpisodeResourcesItem>> fetchEpisodeResources(
    String sourceUrl,
    CrawlConfigItem crawlConfig,
  ) async {
    final request = crawlConfig.usesApiChapter
        ? _prepareApiChapterRequest(sourceUrl, crawlConfig)
        : _prepareXPathChapterRequest(sourceUrl, crawlConfig);
    final response = await _sendWithRetry(request, crawlConfig);

    if (crawlConfig.usesApiChapter) {
      return ApiCrawler.parseChapters(
        response,
        crawlConfig.chapterApiConfig,
        source: sourceUrl,
        baseUrl: crawlConfig.baseUrl,
      );
    }
    return HtmlCrawler.parseEpisodeResources(response, crawlConfig);
  }

  // ---------------------------------------------------------------------------
  // 请求准备
  // ---------------------------------------------------------------------------

  static PreparedRuleRequest _prepareXPathSearchRequest(
    String keyword,
    CrawlConfigItem crawlConfig,
  ) {
    final queryUrl = crawlConfig.searchUrl.replaceFirst(
      '{keyword}',
      Uri.encodeQueryComponent(keyword),
    );
    return PreparedRuleRequest(
      method: 'GET',
      url: queryUrl,
      includeCookies: true,
    );
  }

  static PreparedRuleRequest _prepareXPathChapterRequest(
    String sourceUrl,
    CrawlConfigItem crawlConfig,
  ) {
    // XPath 章节请求历史上不带 Cookie，只有搜索请求带。
    return PreparedRuleRequest(
      method: 'GET',
      url: resolveSourceUrl(crawlConfig.baseUrl, sourceUrl),
    );
  }

  static PreparedRuleRequest _prepareApiSearchRequest(
    String keyword,
    CrawlConfigItem crawlConfig,
  ) {
    return _prepareApiRequest(
      crawlConfig.searchApiConfig.request,
      <String, Object?>{'keyword': keyword},
    );
  }

  static PreparedRuleRequest _prepareApiChapterRequest(
    String sourceUrl,
    CrawlConfigItem crawlConfig,
  ) {
    return _prepareApiRequest(
      crawlConfig.chapterApiConfig.request,
      <String, Object?>{'source': sourceUrl},
    );
  }

  static PreparedRuleRequest _prepareApiRequest(
    ApiRequestConfig request,
    Map<String, Object?> variables,
  ) {
    final method = request.method.toUpperCase();
    if (method != 'GET' && method != 'POST') {
      throw ApiRuleFormatException('仅支持 GET/POST，当前为 $method');
    }

    final templateUrl = request.url.trim();
    if (templateUrl.isEmpty) {
      throw const ApiRuleFormatException('API 请求 URL 不能为空');
    }

    final url = ApiCrawler.renderTemplate(templateUrl, variables, encode: true);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ApiRuleFormatException('API 请求 URL 无效：$url');
    }

    final hasBody = method == 'POST' && request.bodyType != ApiBodyType.none;
    return PreparedRuleRequest(
      method: method,
      url: url,
      headers: ApiCrawler.renderMap(request.headers, variables),
      query: ApiCrawler.renderMap(request.query, variables),
      bodyType: request.bodyType,
      body: hasBody ? ApiCrawler.renderValue(request.body, variables) : null,
      includeCookies: true,
    );
  }

  // ---------------------------------------------------------------------------
  // 发送
  // ---------------------------------------------------------------------------

  static Future<String> _sendWithRetry(
    PreparedRuleRequest request,
    CrawlConfigItem crawlConfig,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await transport(request, crawlConfig);
        if (response.trim().isEmpty) {
          throw StateError('empty response');
        }

        _ensureCaptchaNotDetected(response, crawlConfig);
        return response;
      } on CaptchaRequiredException {
        rethrow;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        logger.w(
          'RuleRequest: ${crawlConfig.name} request attempt '
          '$attempt/$_maxAttempts failed: ${request.url}',
          error: error,
        );
        if (attempt < _maxAttempts) {
          await Future<void>.delayed(
            Duration(milliseconds: 300 * attempt),
          );
        }
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  static Future<String> _send(
    PreparedRuleRequest request,
    CrawlConfigItem crawlConfig,
  ) async {
    final cookie = request.includeCookies
        ? await _cookieHeaderFor(request.url, crawlConfig.name)
        : '';

    // 规则自定义头最后合并，key 统一小写，便于覆盖上面的默认值。
    final headers = <String, dynamic>{
      'referer': '${crawlConfig.baseUrl}/',
      'Accept-Language': Utils.getRandomAcceptedLanguage(),
      'Connection': 'keep-alive',
      Constants.userAgentName: Utils.getRandomUA(),
      if (cookie.isNotEmpty) 'Cookie': cookie,
      for (final entry in request.headers.entries)
        entry.key.toLowerCase(): entry.value,
    };

    if (request.method == 'POST') {
      if (request.bodyType == ApiBodyType.json) {
        headers.putIfAbsent('content-type', () => 'application/json');
      } else if (request.bodyType == ApiBodyType.form) {
        headers.putIfAbsent(
          'content-type',
          () => 'application/x-www-form-urlencoded',
        );
      }
    }

    return PluginSiteClient.instance.requestText(
      request.url,
      method: request.method,
      headers: headers,
      queryParameters: request.query,
      data: request.method == 'POST' ? request.body : null,
    );
  }

  static void _ensureCaptchaNotDetected(
    String response,
    CrawlConfigItem crawlConfig,
  ) {
    final antiCrawler = crawlConfig.antiCrawlerConfig;
    if (!antiCrawler.enabled) return;

    final htmlElement = html_parser.parse(response).documentElement;
    if (htmlElement == null) return;

    final detectionXpaths = [
      antiCrawler.captchaImage,
      antiCrawler.captchaButton,
    ].where((xpath) => xpath.trim().isNotEmpty);
    final captchaDetected = detectionXpaths.any(
      (xpath) => htmlElement.queryXPath(xpath).node != null,
    );
    if (captchaDetected) {
      logger.w('RuleRequest: ${crawlConfig.name} detected captcha challenge');
      throw CaptchaRequiredException(crawlConfig.name);
    }
  }

  static Future<String> _cookieHeaderFor(String url, String name) async {
    if (!CookieManager.instance.hasCookies(name)) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    try {
      final cookies =
          await CookieManager.instance.getJar(name).loadForRequest(uri);
      if (cookies.isEmpty) return '';
      return cookies.map((c) => '${c.name}=${c.value}').join('; ');
    } catch (_) {
      return '';
    }
  }
}
