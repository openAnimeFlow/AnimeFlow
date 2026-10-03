import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/crawler/cookie_manager.dart';
import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const String _pluginName = 'e2e';

/// 一次被假站点记录下来的请求。
class _CapturedRequest {
  _CapturedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.headers,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final Map<String, String> headers;
  final String body;

  String? header(String name) => headers[name.toLowerCase()];

  Map<String, dynamic> get jsonBody => jsonDecode(body) as Map<String, dynamic>;
}

/// 本地假规则站点：让请求真正经过 pluginDio 与网络栈。
class _FakeRuleSite {
  _FakeRuleSite._(this._server);

  final HttpServer _server;

  final List<_CapturedRequest> requests = [];

  /// 剩余需要返回 500 的次数，用于验证重试。
  int failFirstAttempts = 0;

  String get origin => 'http://127.0.0.1:${_server.port}';

  static Future<_FakeRuleSite> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final site = _FakeRuleSite._(server);
    server.listen(site._handle);
    return site;
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final headers = <String, String>{};
    request.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(',');
    });
    requests.add(
      _CapturedRequest(
        method: request.method,
        path: request.uri.path,
        query: request.uri.queryParameters,
        headers: headers,
        body: body,
      ),
    );

    final response = request.response;
    final path = request.uri.path;

    if (failFirstAttempts > 0 && path == '/api/search') {
      failFirstAttempts--;
      response.statusCode = 500;
      await response.close();
      return;
    }

    if (path == '/api/search') {
      await _json(response, _searchPayload);
      return;
    }
    if (path == '/api/detail') {
      await _json(response, _detailPayload);
      return;
    }
    if (path == '/api/delimited') {
      await _json(response, _delimitedPayload);
      return;
    }
    if (path == '/api/episode-page') {
      await _json(response, _episodePagePayload);
      return;
    }
    if (path == '/challenge-header') {
      response.statusCode = 403;
      response.headers.set('cf-mitigated', 'challenge');
      await response.close();
      return;
    }
    if (path == '/challenge-body') {
      response.statusCode = 403;
      response.write('<html><body><div class="captcha"></div></body></html>');
      await response.close();
      return;
    }
    if (path == '/xpath/search') {
      await _html(
        response,
        '<html><body><div><a href="/d/1">进击的巨人</a></div></body></html>',
      );
      return;
    }
    if (path == '/xpath/detail') {
      await _html(
        response,
        '<html><body><ul><li><a href="/play/1">第1集</a></li></ul></body></html>',
      );
      return;
    }
    if (path == '/d/1') {
      await _html(
        response,
        '<html><body><ul><li><a href="/play/1">第1集</a></li></ul></body></html>',
      );
      return;
    }

    response.statusCode = 404;
    await response.close();
  }

  static Future<void> _json(
    HttpResponse response,
    Map<String, dynamic> payload,
  ) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    await response.close();
  }

  static Future<void> _html(HttpResponse response, String html) async {
    response.headers.contentType = ContentType.html;
    response.write(html);
    await response.close();
  }
}

const Map<String, dynamic> _searchPayload = {
  'data': [
    {'name': '进击的巨人', 'url': '/d/1'},
    {'name': '进击的巨人 第二季', 'url': '/d/2'},
  ],
};

const Map<String, dynamic> _detailPayload = {
  'roads': [
    {
      'name': '线路A',
      'episodes': [
        {'url': '/play/a1'},
        {'url': '/play/a2'},
      ],
    },
    {
      'name': '',
      'episodes': [
        {'url': 'https://other.example.com/play/b1'},
      ],
    },
  ],
};

const Map<String, dynamic> _delimitedPayload = {
  'roadNames': r'线路A$$$线路B',
  'roadEpisodes': r'第1集$http://a.example.com/1#第2集$http://a.example.com/2'
      r'$$$第1集$http://b.example.com/1',
};

const Map<String, dynamic> _episodePagePayload = {
  'roads': [
    {
      'name': '线路A',
      'episodes': [
        {'id': 'e1'},
        {'id': 'e2'},
      ],
    },
  ],
};

CrawlConfigItem _apiRule(
  _FakeRuleSite site, {
  String chapterPath = '/api/detail',
  ApiChapterConfig? chapterApiConfig,
  AntiCrawlerConfig? antiCrawlerConfig,
  String searchPath = '/api/search',
}) {
  return CrawlConfigItem(
    version: '1.0.0',
    name: _pluginName,
    iconUrl: '',
    baseUrl: site.origin,
    searchUrl: '',
    searchList: '',
    searchName: '',
    searchLink: '',
    lineNames: '',
    lineList: '',
    episode: '',
    searchMode: RuleMode.api,
    chapterMode: RuleMode.api,
    searchApiConfig: ApiSearchConfig(
      request: ApiRequestConfig(
        method: 'GET',
        url: '${site.origin}$searchPath',
        headers: <String, dynamic>{'referer': '${site.origin}/'},
        query: <String, dynamic>{'wd': '@keyword'},
      ),
      listPath: r'$.data[*]',
      namePath: r'$.name',
      sourcePath: r'$.url',
    ),
    chapterApiConfig: chapterApiConfig ??
        ApiChapterConfig(
          request: ApiRequestConfig(
            method: 'POST',
            url: '${site.origin}$chapterPath',
            bodyType: ApiBodyType.json,
            body: <String, dynamic>{'id': '@source'},
          ),
          format: ApiChapterFormat.nested,
          roadsPath: r'$.roads[*]',
          roadNamePath: r'$.name',
          episodesPath: r'$.episodes[*]',
          episodeUrlPath: r'$.url',
        ),
    antiCrawlerConfig: antiCrawlerConfig,
  );
}

CrawlConfigItem _xpathRule(_FakeRuleSite site) {
  return CrawlConfigItem(
    version: '1.0.0',
    name: _pluginName,
    iconUrl: '',
    baseUrl: site.origin,
    searchUrl: '${site.origin}/xpath/search?wd={keyword}',
    searchList: '//div',
    searchName: '/a',
    searchLink: '/a',
    lineNames: '//span',
    lineList: '//ul',
    episode: '//a',
  );
}

void main() {
  late _FakeRuleSite site;

  setUpAll(() async {
    site = await _FakeRuleSite.start();
  });

  tearDownAll(() async {
    await site.close();
  });

  setUp(() async {
    site.requests.clear();
    site.failFirstAttempts = 0;
    CookieManager.instance.clearCookies(_pluginName);
    // 模拟 WebView 验证后写入的 Cookie，用于验证真实请求头。
    await CookieManager.instance.saveFromWebView(
      _pluginName,
      '${site.origin}/',
      'sid=abc123; theme=dark',
    );
  });

  test('API 搜索与章节请求真实走过 HTTP 链路', () async {
    final config = _apiRule(site);

    final items = await RuleEngine().search(
      keyword: '进击的巨人',
      config: config,
    );
    expect(items.map((item) => item.name).toList(), [
      '进击的巨人',
      '进击的巨人 第二季',
    ]);

    final search = site.requests.single;
    expect(search.method, 'GET');
    expect(search.path, '/api/search');
    expect(search.query['wd'], '进击的巨人');
    expect(search.header('referer'), '${site.origin}/');
    expect(search.header('cookie'), contains('sid=abc123'));
    expect(search.header('user-agent'), isNotEmpty);

    final roads = await RuleEngine().fetchEpisodeResources(
      sourceUrl: items.first.link,
      config: config,
    );
    expect(roads, hasLength(2));
    expect(roads[0].lineNames, '线路A');
    expect(
      roads[0].episodes.map((episode) => episode.like).toList(),
      ['${site.origin}/play/a1', '${site.origin}/play/a2'],
    );
    expect(roads[1].episodes.single.like, 'https://other.example.com/play/b1');

    final detail = site.requests.last;
    expect(detail.method, 'POST');
    expect(detail.path, '/api/detail');
    expect(detail.header('content-type'), contains('application/json'));
    expect(detail.jsonBody, <String, dynamic>{'id': '/d/1'});
    expect(detail.header('cookie'), contains('sid=abc123'));
  });

  test('分隔符格式章节响应端到端解析', () async {
    final site0 = site;
    final config = _apiRule(
      site0,
      chapterApiConfig: ApiChapterConfig(
        request: ApiRequestConfig(
            method: 'GET', url: '${site0.origin}/api/delimited'),
        format: ApiChapterFormat.delimited,
        roadNamesPath: r'$.roadNames',
        roadEpisodesPath: r'$.roadEpisodes',
      ),
    );

    final roads = await RuleEngine().fetchEpisodeResources(
      sourceUrl: '/d/1',
      config: config,
    );

    expect(roads.map((road) => road.lineNames).toList(), ['线路A', '线路B']);
    expect(roads[0].episodes.map((episode) => episode.like).toList(), [
      'http://a.example.com/1',
      'http://a.example.com/2',
    ]);
    expect(roads[1].episodes.single.like, 'http://b.example.com/1');
  });

  test('播放页模板端到端渲染索引与查询参数', () async {
    final config = _apiRule(
      site,
      chapterApiConfig: ApiChapterConfig(
        request: ApiRequestConfig(
          method: 'GET',
          url: '${site.origin}/api/episode-page',
        ),
        roadsPath: r'$.roads[*]',
        roadNamePath: r'$.name',
        episodesPath: r'$.episodes[*]',
        episodeUrlPath: r'$.id',
        episodePage: ApiEpisodePageConfig(
          url: '${site.origin}/play/@episodeUrl',
          query: <String, dynamic>{'ep': '@episodeNumber'},
        ),
      ),
    );

    final roads = await RuleEngine().fetchEpisodeResources(
      sourceUrl: '/d/1',
      config: config,
    );

    expect(roads.single.episodes.map((episode) => episode.like).toList(), [
      '${site.origin}/play/e1?ep=1',
      '${site.origin}/play/e2?ep=2',
    ]);
  });

  test('失败后重试，最终成功', () async {
    site.failFirstAttempts = 1;

    final items = await RuleEngine().search(
      keyword: '巨人',
      config: _apiRule(site),
    );

    expect(items, hasLength(2));
    expect(site.requests, hasLength(2));
    expect(site.requests.first.path, '/api/search');
  });

  test('403 + cf-mitigated 头被识别为验证页', () async {
    final config = _apiRule(
      site,
      searchPath: '/challenge-header',
      antiCrawlerConfig: AntiCrawlerConfig(
        enabled: true,
        captchaType: CaptchaType.imageCaptcha,
        captchaImage: '',
        captchaInput: '',
        captchaButton: '',
      ),
    );

    await expectLater(
      RuleEngine().search(keyword: '巨人', config: config),
      throwsA(isA<CaptchaRequiredException>()),
    );
    // 命中验证页后立即上抛，不参与重试。
    expect(site.requests, hasLength(1));
  });

  test('403 + 挑战页响应体被文本检测识别', () async {
    final config = _apiRule(
      site,
      searchPath: '/challenge-body',
      antiCrawlerConfig: AntiCrawlerConfig(
        enabled: true,
        captchaType: CaptchaType.imageCaptcha,
        captchaImage: '',
        captchaInput: '',
        captchaButton: '',
        captchaDetectType: CaptchaDetectType.xpath,
        captchaDetectValue: '//div[@class="captcha"]',
      ),
    );

    await expectLater(
      RuleEngine().search(keyword: '巨人', config: config),
      throwsA(isA<CaptchaRequiredException>()),
    );
    expect(site.requests, hasLength(1));
  });

  test('XPath 模式搜索带 Cookie、章节不带（保持既有行为）', () async {
    final config = _xpathRule(site);

    final items = await RuleEngine().search(
      keyword: '巨人',
      config: config,
    );
    expect(items.single.name, '进击的巨人');
    expect(site.requests.last.header('cookie'), contains('sid=abc123'));

    await RuleEngine().fetchEpisodeResources(
      sourceUrl: items.single.link,
      config: config,
    );
    final detail = site.requests.last;
    expect(detail.path, '/d/1');
    expect(detail.header('cookie'), isNull);
  });
}
