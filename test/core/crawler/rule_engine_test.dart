import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_engine.dart';
import 'package:anime_flow/core/crawler/rule_request.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:flutter_test/flutter_test.dart';

CrawlConfigItem _apiRule({
  String searchRequestUrl = 'https://api.site.com/search',
  String chapterRequestUrl = 'https://api.site.com/detail',
  AntiCrawlerConfig? antiCrawlerConfig,
}) {
  return CrawlConfigItem(
    version: '1.0.0',
    name: 'API 源',
    iconUrl: '',
    baseUrl: 'https://api.site.com',
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
      request: ApiRequestConfig(method: 'GET', url: searchRequestUrl),
    ),
    chapterApiConfig: ApiChapterConfig(
      request: ApiRequestConfig(method: 'GET', url: chapterRequestUrl),
    ),
    antiCrawlerConfig: antiCrawlerConfig,
  );
}

/// 传输层被替换成假实现，因此这里只验证引擎自身的编排与异常分类；
/// 真实的 HTTP、重试与挑战页识别由 `rule_request_e2e_test.dart` 覆盖。
RuleEngine _engine(RuleRequestTransport transport) {
  return RuleEngine(transport: transport);
}

void main() {
  test('搜索无结果抛出 NoResultException', () async {
    final engine = _engine((request, config) async => '{"data":[]}');

    await expectLater(
      engine.search(keyword: '巨人', config: _apiRule()),
      throwsA(isA<NoResultException>()),
    );
  });

  test('请求准备失败抛出 SearchErrorException', () async {
    final engine = _engine((request, config) async => '{}');

    await expectLater(
      engine.search(keyword: '巨人', config: _apiRule(searchRequestUrl: '')),
      throwsA(isA<SearchErrorException>()),
    );
  });

  test('章节请求准备失败抛出 ChapterErrorException', () async {
    final engine = _engine((request, config) async => '{}');

    await expectLater(
      engine.fetchEpisodeResources(
        sourceUrl: '/d/1',
        config: _apiRule(chapterRequestUrl: ''),
      ),
      throwsA(isA<ChapterErrorException>()),
    );
  });

  test('响应解析失败抛出 SearchErrorException 而不是原始异常', () async {
    final engine = _engine((request, config) async => '<html>not json</html>');

    await expectLater(
      engine.search(keyword: '巨人', config: _apiRule()),
      throwsA(isA<SearchErrorException>()),
    );
  });

  test('传输失败抛出 SearchErrorException 并保留原因', () async {
    const cause = NetworkException(
      type: NetworkExceptionType.connectionError,
      message: '连接错误，请检查网络设置',
    );
    final engine = _engine((request, config) async => throw cause);

    await expectLater(
      engine.search(keyword: '巨人', config: _apiRule()),
      throwsA(
        isA<SearchErrorException>()
            .having((error) => error.cause, 'cause', same(cause)),
      ),
    );
  });

  test('需要验证的异常不被包装，直接透传给调用方', () async {
    final engine = _engine(
      (request, config) async => throw const CaptchaRequiredException('API 源'),
    );

    await expectLater(
      engine.search(keyword: '巨人', config: _apiRule()),
      throwsA(isA<CaptchaRequiredException>()),
    );
    await expectLater(
      engine.fetchEpisodeResources(sourceUrl: '/d/1', config: _apiRule()),
      throwsA(isA<CaptchaRequiredException>()),
    );
  });

  test('章节解析失败抛出 ChapterErrorException', () async {
    final engine = _engine((request, config) async => 'not json');

    await expectLater(
      engine.fetchEpisodeResources(sourceUrl: '/d/1', config: _apiRule()),
      throwsA(isA<ChapterErrorException>()),
    );
  });
}
