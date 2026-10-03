import 'package:anime_flow/core/crawler/api_crawler.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_request.dart';
import 'package:flutter_test/flutter_test.dart';

const String _apiSearchJson = '''
{
  "data": [
    {"name": "进击的巨人", "url": "/d/1"},
    {"name": "进击的巨人 第二季", "url": "/d/2"},
    {"name": "", "url": "/d/3"},
    {"name": "缺少链接", "url": ""}
  ]
}
''';

const String _apiChapterJson = '''
{
  "roads": [
    {"name": "线路A", "episodes": [{"url": "/play/a1"}, {"url": "/play/a2"}]},
    {"name": "", "episodes": [{"url": "https://other.com/play/b1"}]}
  ]
}
''';

const String _xpathSearchHtml = '''
<html><body>
  <div><a href="/d/1">进击的巨人</a></div>
  <div><a href="/d/2">进击的巨人 第二季</a></div>
</body></html>
''';

CrawlConfigItem _xpathRule() {
  return CrawlConfigItem(
    version: '1.0.0',
    name: 'XPath 源',
    iconUrl: '',
    baseUrl: 'https://site.com',
    searchUrl: 'https://site.com/search?wd={keyword}',
    searchList: '//div',
    searchName: '/a',
    searchLink: '/a',
    lineNames: '//span',
    lineList: '//ul',
    episode: '//a',
  );
}

CrawlConfigItem _apiRule() {
  return CrawlConfigItem(
    version: '1.0.0',
    name: 'API 源',
    iconUrl: '',
    baseUrl: 'https://api.site.com',
    searchUrl: 'https://api.site.com/search?wd={keyword}',
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
        url: 'https://api.site.com/search',
        headers: <String, dynamic>{'referer': 'https://api.site.com/'},
        query: <String, dynamic>{'wd': '@keyword'},
      ),
    ),
    chapterApiConfig: ApiChapterConfig(
      request: ApiRequestConfig(
        method: 'POST',
        url: 'https://api.site.com/detail',
        bodyType: ApiBodyType.json,
        body: <String, dynamic>{'id': '@source'},
      ),
      format: ApiChapterFormat.nested,
      roadsPath: r'$.roads[*]',
      roadNamePath: r'$.name',
      episodesPath: r'$.episodes[*]',
      episodeUrlPath: r'$.url',
    ),
  );
}

void main() {
  group('模板渲染', () {
    test('@变量 与 {变量} 都会被替换并编码', () {
      expect(
        ApiCrawler.renderTemplate(
          'https://a.com/s?wd=@keyword',
          <String, Object?>{'keyword': '巨人'},
          encode: true,
        ),
        'https://a.com/s?wd=%E5%B7%A8%E4%BA%BA',
      );
      expect(
        ApiCrawler.renderTemplate(
          'https://a.com/s?wd={keyword}',
          <String, Object?>{'keyword': '巨人'},
          encode: true,
        ),
        'https://a.com/s?wd=%E5%B7%A8%E4%BA%BA',
      );
      expect(
        ApiCrawler.renderTemplate(
          'https://a.com/s?wd=@keyword',
          <String, Object?>{'keyword': '巨人'},
        ),
        'https://a.com/s?wd=巨人',
      );
    });

    test('缺少模板变量时抛错', () {
      expect(
        () => ApiCrawler.renderTemplate(
          '@missing',
          <String, Object?>{},
        ),
        throwsA(isA<ApiRuleFormatException>()),
      );
    });

    test('缺少变量时的提示回显作者写的写法', () {
      expect(
        () => ApiCrawler.renderTemplate('@missing', <String, Object?>{}),
        throwsA(
          isA<ApiRuleFormatException>().having(
              (error) => error.message, 'message', contains('@missing')),
        ),
      );
      expect(
        () => ApiCrawler.renderTemplate('{missing}', <String, Object?>{}),
        throwsA(
          isA<ApiRuleFormatException>().having(
              (error) => error.message, 'message', contains('{missing}')),
        ),
      );
    });

    test('两种写法的整串变量都保留原始类型', () {
      // 数字不会被转成字符串。
      expect(ApiCrawler.renderValue('@n', <String, Object?>{'n': 2}), 2);
      expect(ApiCrawler.renderValue('{n}', <String, Object?>{'n': 2}), 2);
      // 复杂类型同样保留。
      expect(
        ApiCrawler.renderValue('{n}', <String, Object?>{
          'n': <String, dynamic>{'a': 1},
        }),
        <String, dynamic>{'a': 1},
      );
      // 内联场景两种写法都按字符串插入。
      expect(ApiCrawler.renderValue('n=@n', <String, Object?>{'n': 2}), 'n=2');
      expect(ApiCrawler.renderValue('n={n}', <String, Object?>{'n': 2}), 'n=2');
    });

    test('整串变量周围的空白不影响类型保留', () {
      expect(ApiCrawler.renderValue('  @n  ', <String, Object?>{'n': 2}), 2);
      expect(ApiCrawler.renderValue('  {n}  ', <String, Object?>{'n': 2}), 2);
    });

    test('嵌套 Map / List 递归渲染', () {
      final rendered = ApiCrawler.renderValue(
        <String, dynamic>{
          'id': '@source',
          'altId': '{source}',
          'tags': <String>['@source', '{source}', 'fixed'],
        },
        <String, Object?>{'source': 'abc'},
      );
      expect(rendered, <String, dynamic>{
        'id': 'abc',
        'altId': 'abc',
        'tags': <String>['abc', 'abc', 'fixed'],
      });
    });
  });

  group('受限 JSONPath', () {
    test('放行基础语法', () {
      expect(() => RestrictedJsonPath.validate(r'$.data[*].name'),
          returnsNormally);
      expect(
          () => RestrictedJsonPath.validate(r"$['a-b'][0]"), returnsNormally);
      expect(() => RestrictedJsonPath.validate(r'$.list[1]'), returnsNormally);
    });

    test('拒绝递归、过滤与非法片段', () {
      expect(
        () => RestrictedJsonPath.validate(r'$..data'),
        throwsA(isA<ApiRuleFormatException>()),
      );
      expect(
        () => RestrictedJsonPath.validate(r'$.data[?(@.a)]'),
        throwsA(isA<ApiRuleFormatException>()),
      );
      expect(
        () => RestrictedJsonPath.validate('data'),
        throwsA(isA<ApiRuleFormatException>()),
      );
      expect(
        () => RestrictedJsonPath.validate(r'$.data[0'),
        throwsA(isA<ApiRuleFormatException>()),
      );
    });
  });

  group('搜索解析', () {
    test('按 listPath 逐项提取名称与链接，跳过缺失项', () {
      final config = _apiRule().searchApiConfig;
      final items = ApiCrawler.parseSearch(_apiSearchJson, config);

      expect(items, hasLength(2));
      expect(items[0].name, '进击的巨人');
      expect(items[0].link, '/d/1');
      expect(items[1].name, '进击的巨人 第二季');
    });

    test('响应不是 JSON 时抛错', () {
      expect(
        () => ApiCrawler.parseSearch(
            '<html>nope</html>', _apiRule().searchApiConfig),
        throwsA(isA<ApiRuleFormatException>()),
      );
    });
  });

  group('章节解析', () {
    test('nested：线路与剧集映射，地址基于 baseUrl 归一化', () {
      final config = _apiRule().chapterApiConfig;
      final roads = ApiCrawler.parseChapters(
        _apiChapterJson,
        config,
        source: '/d/1',
        baseUrl: 'https://api.site.com',
      );

      expect(roads, hasLength(2));
      expect(roads[0].lineNames, '线路A');
      expect(roads[0].episodes.map((e) => e.like).toList(), <String>[
        'https://api.site.com/play/a1',
        'https://api.site.com/play/a2',
      ]);
      expect(roads[0].episodes.map((e) => e.episodeSort).toList(), <int>[1, 2]);
      // 未配置线路名时回退为「播放线路N」。
      expect(roads[1].lineNames, '播放线路2');
      expect(roads[1].episodes.single.like, 'https://other.com/play/b1');
    });

    test('nested + episodePage：模板渲染索引与查询参数', () {
      const json = '''
      {"roads": [{"name": "线路A", "episodes": [{"id": "e1"}, {"id": "e2"}]}]}
      ''';
      final config = ApiChapterConfig(
        format: ApiChapterFormat.nested,
        roadsPath: r'$.roads[*]',
        roadNamePath: r'$.name',
        episodesPath: r'$.episodes[*]',
        episodeUrlPath: r'$.id',
        episodePage: ApiEpisodePageConfig(
          url: 'https://site.com/play/@episodeUrl',
          query: <String, dynamic>{'ep': '@episodeNumber'},
        ),
      );

      final roads = ApiCrawler.parseChapters(
        json,
        config,
        source: '/d/1',
        baseUrl: 'https://site.com',
      );

      expect(
        roads.single.episodes.map((e) => e.like).toList(),
        <String>[
          'https://site.com/play/e1?ep=1',
          'https://site.com/play/e2?ep=2',
        ],
      );
    });

    test('delimited：按分隔符拆分线路与剧集', () {
      const json = '''
      {
        "roadNames": "线路A\$\$\$线路B",
        "roadEpisodes": "第1集\$http://a.com/1#第2集\$http://a.com/2\$\$\$第1集\$http://b.com/1"
      }
      ''';
      final config = ApiChapterConfig(
        format: ApiChapterFormat.delimited,
        roadNamesPath: r'$.roadNames',
        roadEpisodesPath: r'$.roadEpisodes',
      );

      final roads = ApiCrawler.parseChapters(
        json,
        config,
        source: '/d/1',
        baseUrl: 'https://site.com',
      );

      expect(roads, hasLength(2));
      expect(roads[0].lineNames, '线路A');
      expect(roads[0].episodes, hasLength(2));
      expect(roads[1].lineNames, '线路B');
      expect(roads[1].episodes.single.like, 'http://b.com/1');
    });

    test('缺少播放入口与播放页模板时校验失败', () {
      final config = ApiChapterConfig(episodeUrlPath: '');
      expect(
        () => ApiCrawler.validateChapterConfig(config),
        throwsA(isA<ApiRuleFormatException>()),
      );
    });

    test('分隔符为空时校验失败', () {
      final config = ApiChapterConfig(
        format: ApiChapterFormat.delimited,
        roadNamesPath: r'$.roadNames',
        roadEpisodesPath: r'$.roadEpisodes',
        roadSeparator: '',
      );
      expect(
        () => ApiCrawler.validateChapterConfig(config),
        throwsA(isA<ApiRuleFormatException>()),
      );
    });
  });

  group('RuleRequest 模式分派', () {
    late RuleRequestTransport originalTransport;

    setUp(() {
      originalTransport = RuleRequest.transport;
    });

    tearDown(() {
      RuleRequest.transport = originalTransport;
    });

    test('XPath 搜索：GET + {keyword} 替换 + 携带 Cookie', () async {
      PreparedRuleRequest? captured;
      RuleRequest.transport = (request, _) async {
        captured = request;
        return _xpathSearchHtml;
      };

      final items = await RuleRequest.searchSubjects('巨人', _xpathRule());

      expect(captured!.method, 'GET');
      expect(captured!.url, 'https://site.com/search?wd=%E5%B7%A8%E4%BA%BA');
      expect(captured!.includeCookies, isTrue);
      expect(items.map((item) => item.name).toList(), <String>[
        '进击的巨人',
        '进击的巨人 第二季',
      ]);
    });

    test('API 搜索：模板渲染 URL/Query/Headers', () async {
      PreparedRuleRequest? captured;
      RuleRequest.transport = (request, _) async {
        captured = request;
        return _apiSearchJson;
      };

      final items = await RuleRequest.searchSubjects('巨人', _apiRule());

      expect(captured!.method, 'GET');
      expect(captured!.url, 'https://api.site.com/search');
      expect(captured!.query['wd'], '巨人');
      expect(captured!.headers['referer'], 'https://api.site.com/');
      expect(captured!.includeCookies, isTrue);
      expect(items, hasLength(2));
    });

    test('API 章节：POST JSON 请求体渲染 @source', () async {
      PreparedRuleRequest? captured;
      RuleRequest.transport = (request, _) async {
        captured = request;
        return _apiChapterJson;
      };

      final roads = await RuleRequest.fetchEpisodeResources('/d/1', _apiRule());

      expect(captured!.method, 'POST');
      expect(captured!.bodyType, ApiBodyType.json);
      expect(captured!.body, <String, dynamic>{'id': '/d/1'});
      expect(captured!.includeCookies, isTrue);
      expect(roads.first.lineNames, '线路A');
    });

    test('XPath 章节：保持不携带 Cookie 的历史行为', () async {
      PreparedRuleRequest? captured;
      RuleRequest.transport = (request, _) async {
        captured = request;
        return '<html><body><ul><a href="/play/1">1</a></ul></body></html>';
      };

      await RuleRequest.fetchEpisodeResources('/d/1', _xpathRule());

      expect(captured!.method, 'GET');
      expect(captured!.url, 'https://site.com/d/1');
      expect(captured!.includeCookies, isFalse);
    });
  });
}
