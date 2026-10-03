import 'package:anime_flow/core/crawler/api_crawler.dart';
import 'package:anime_flow/core/crawler/html_crawler.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_exceptions.dart';
import 'package:anime_flow/core/crawler/rule_request.dart';
import 'package:anime_flow/core/crawler/rule_template.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/utils.dart' show resolveSourceUrl;
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/search_resources_item.dart';

export 'rule_exceptions.dart';

final LiggLogger _logger = LiggLogger();

/// XPath 模式的请求准备与响应解析。
class XPathRuleStrategy {
  const XPathRuleStrategy();

  PreparedRuleRequest prepareSearchRequest(
    CrawlConfigItem config,
    String keyword,
  ) {
    final queryUrl = config.searchUrl.replaceFirst(
      '{keyword}',
      Uri.encodeQueryComponent(keyword),
    );
    return PreparedRuleRequest(
      method: 'GET',
      url: queryUrl,
      includeCookies: true,
    );
  }

  PreparedRuleRequest prepareChapterRequest(
    CrawlConfigItem config,
    String sourceUrl,
  ) {
    // XPath 章节请求历史上不带 Cookie，只有搜索请求带。
    return PreparedRuleRequest(
      method: 'GET',
      url: resolveSourceUrl(config.baseUrl, sourceUrl),
    );
  }

  Future<List<SearchResourcesItem>> parseSearch(
    String raw,
    CrawlConfigItem config,
  ) {
    return HtmlCrawler.parseSearch(raw, config);
  }

  Future<List<CrawlerEpisodeResourcesItem>> parseChapters(
    String raw,
    CrawlConfigItem config,
  ) {
    return HtmlCrawler.parseEpisodeResources(raw, config);
  }
}

/// API 模式的请求准备与响应解析。
class ApiRuleStrategy {
  const ApiRuleStrategy();

  PreparedRuleRequest prepareSearchRequest(
    CrawlConfigItem config,
    String keyword,
  ) {
    return _prepare(
      config.searchApiConfig.request,
      <String, Object?>{'keyword': keyword},
    );
  }

  PreparedRuleRequest prepareChapterRequest(
    CrawlConfigItem config,
    String sourceUrl,
  ) {
    return _prepare(
      config.chapterApiConfig.request,
      <String, Object?>{'source': sourceUrl},
    );
  }

  List<SearchResourcesItem> parseSearch(String raw, CrawlConfigItem config) {
    return ApiCrawler.parseSearch(raw, config.searchApiConfig);
  }

  List<CrawlerEpisodeResourcesItem> parseChapters(
    String raw,
    CrawlConfigItem config,
    String sourceUrl,
  ) {
    return ApiCrawler.parseChapters(
      raw,
      config.chapterApiConfig,
      source: sourceUrl,
      baseUrl: config.baseUrl,
    );
  }

  static PreparedRuleRequest _prepare(
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

    final url = RuleTemplate.render(templateUrl, variables, encode: true);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ApiRuleFormatException('API 请求 URL 无效：$url');
    }

    final hasBody = method == 'POST' && request.bodyType != ApiBodyType.none;
    return PreparedRuleRequest(
      method: method,
      url: url,
      headers: RuleTemplate.renderMap(request.headers, variables),
      query: RuleTemplate.renderMap(request.query, variables),
      bodyType: request.bodyType,
      body: hasBody ? RuleTemplate.renderValue(request.body, variables) : null,
      includeCookies: true,
    );
  }
}

/// 规则执行引擎。
///
/// 按 `searchMode` / `chapterMode` 选择策略，串联「准备请求 → 发送（含重试）
/// → 解析响应」，并把三类失败统一成调用方可区分的异常：
/// 请求准备 / 传输 / 解析失败分别包装为 [SearchErrorException] 或
/// [ChapterErrorException]，需要人工验证时保持 [CaptchaRequiredException]。
class RuleEngine {
  RuleEngine({
    RuleRequestTransport? transport,
    XPathRuleStrategy xpathStrategy = const XPathRuleStrategy(),
    ApiRuleStrategy apiStrategy = const ApiRuleStrategy(),
  })  : _transport = transport ?? sendRuleRequest,
        _xpath = xpathStrategy,
        _api = apiStrategy;

  final RuleRequestTransport _transport;
  final XPathRuleStrategy _xpath;
  final ApiRuleStrategy _api;

  /// 搜索条目列表。
  Future<List<SearchResourcesItem>> search({
    required String keyword,
    required CrawlConfigItem config,
  }) async {
    final usesApi = config.usesApiSearch;
    final items = await _execute<List<SearchResourcesItem>>(
      config: config,
      phase: 'search',
      prepare: () => usesApi
          ? _api.prepareSearchRequest(config, keyword)
          : _xpath.prepareSearchRequest(config, keyword),
      parse: usesApi
          ? (raw) async => _api.parseSearch(raw, config)
          : (raw) => _xpath.parseSearch(raw, config),
      wrapError: (cause) => SearchErrorException(config.name, cause: cause),
    );

    if (items.isEmpty) {
      throw NoResultException(config.name);
    }
    return items;
  }

  /// 剧集资源列表。
  Future<List<CrawlerEpisodeResourcesItem>> fetchEpisodeResources({
    required String sourceUrl,
    required CrawlConfigItem config,
  }) {
    final usesApi = config.usesApiChapter;
    return _execute<List<CrawlerEpisodeResourcesItem>>(
      config: config,
      phase: 'chapter',
      prepare: () => usesApi
          ? _api.prepareChapterRequest(config, sourceUrl)
          : _xpath.prepareChapterRequest(config, sourceUrl),
      parse: usesApi
          ? (raw) async => _api.parseChapters(raw, config, sourceUrl)
          : (raw) => _xpath.parseChapters(raw, config),
      wrapError: (cause) => ChapterErrorException(config.name, cause: cause),
    );
  }

  /// 三个阶段的统一错误包装：准备失败、传输失败、解析失败分别记日志并
  /// 交给 [wrapError] 转成调用方可见的异常。
  Future<T> _execute<T>({
    required CrawlConfigItem config,
    required String phase,
    required PreparedRuleRequest Function() prepare,
    required Future<T> Function(String raw) parse,
    required Object Function(Object cause) wrapError,
  }) async {
    final PreparedRuleRequest request;
    try {
      request = prepare();
    } catch (error, stackTrace) {
      _logFailure(config, '$phase request preparation', error, stackTrace);
      throw wrapError(error);
    }

    final String response;
    try {
      response = await _transport(request, config);
    } on CaptchaRequiredException {
      rethrow;
    } catch (error, stackTrace) {
      _logFailure(config, '$phase request', error, stackTrace);
      throw wrapError(error);
    }

    try {
      return await parse(response);
    } on CaptchaRequiredException {
      rethrow;
    } catch (error, stackTrace) {
      _logFailure(config, '$phase response parsing', error, stackTrace);
      throw wrapError(error);
    }
  }

  void _logFailure(
    CrawlConfigItem config,
    String phase,
    Object error,
    StackTrace stackTrace,
  ) {
    _logger.w(
      'RuleEngine: ${config.name} $phase failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
