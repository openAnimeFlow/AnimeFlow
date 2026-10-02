import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_request.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:dio/dio.dart';
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

NetworkException _badResponse({String? body, List<String>? cfMitigated}) {
  final options = RequestOptions(path: 'https://api.site.com/search');
  return NetworkException(
    type: NetworkExceptionType.badResponse,
    message: '服务器异常，请稍后重试！',
    statusCode: 403,
    rawError: DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 403,
        data: body,
        headers: cfMitigated == null
            ? null
            : Headers.fromMap(<String, List<String>>{
                'cf-mitigated': cfMitigated,
              }),
      ),
    ),
  );
}

void main() {
  late RuleRequestTransport originalTransport;

  setUp(() {
    originalTransport = RuleRequest.transport;
  });

  tearDown(() {
    RuleRequest.transport = originalTransport;
  });

  test('搜索无结果抛出 NoResultException', () async {
    RuleRequest.transport = (request, config) async => '{"data":[]}';

    await expectLater(
      RuleRequest.searchSubjects('巨人', _apiRule()),
      throwsA(isA<NoResultException>()),
    );
  });

  test('请求准备失败抛出 SearchErrorException', () async {
    RuleRequest.transport = (request, config) async => '{}';

    await expectLater(
      RuleRequest.searchSubjects(
        '巨人',
        _apiRule(searchRequestUrl: ''),
      ),
      throwsA(isA<SearchErrorException>()),
    );
  });

  test('章节请求准备失败抛出 ChapterErrorException', () async {
    RuleRequest.transport = (request, config) async => '{}';

    await expectLater(
      RuleRequest.fetchEpisodeResources(
        '/d/1',
        _apiRule(chapterRequestUrl: ''),
      ),
      throwsA(isA<ChapterErrorException>()),
    );
  });

  test('响应解析失败抛出 SearchErrorException 而不是原始异常', () async {
    RuleRequest.transport = (request, config) async => '<html>not json</html>';

    await expectLater(
      RuleRequest.searchSubjects('巨人', _apiRule()),
      throwsA(isA<SearchErrorException>()),
    );
  });

  test('普通网络错误重试后抛出 SearchErrorException', () async {
    var attempts = 0;
    RuleRequest.transport = (request, config) async {
      attempts++;
      throw const NetworkException(
        type: NetworkExceptionType.connectionError,
        message: '连接错误，请检查网络设置',
      );
    };

    await expectLater(
      RuleRequest.searchSubjects('巨人', _apiRule()),
      throwsA(isA<SearchErrorException>()),
    );
    expect(attempts, 3);
  });

  test('非 2xx 且带 cf-mitigated 头时判定为需要验证', () async {
    RuleRequest.transport = (request, config) async {
      throw _badResponse(cfMitigated: <String>['challenge']);
    };

    await expectLater(
      RuleRequest.searchSubjects(
        '巨人',
        _apiRule(
          antiCrawlerConfig: AntiCrawlerConfig(
            enabled: true,
            captchaType: CaptchaType.imageCaptcha,
            captchaImage: '',
            captchaInput: '',
            captchaButton: '',
          ),
        ),
      ),
      throwsA(isA<CaptchaRequiredException>()),
    );
  });

  test('非 2xx 响应体命中文本检测时判定为需要验证', () async {
    RuleRequest.transport = (request, config) async {
      throw _badResponse(body: '{"msg":"请完成验证"}');
    };

    await expectLater(
      RuleRequest.searchSubjects(
        '巨人',
        _apiRule(
          antiCrawlerConfig: AntiCrawlerConfig(
            enabled: true,
            captchaType: CaptchaType.imageCaptcha,
            captchaImage: '',
            captchaInput: '',
            captchaButton: '',
            captchaDetectType: CaptchaDetectType.text,
            captchaDetectValue: '请完成验证',
          ),
        ),
      ),
      throwsA(isA<CaptchaRequiredException>()),
    );
  });

  test('未启用反爬时非 2xx 不算验证页', () async {
    RuleRequest.transport = (request, config) async {
      throw _badResponse(cfMitigated: <String>['challenge']);
    };

    await expectLater(
      RuleRequest.searchSubjects('巨人', _apiRule()),
      throwsA(isA<SearchErrorException>()),
    );
  });
}
