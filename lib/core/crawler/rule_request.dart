// 规则请求执行层：统一的请求描述 [PreparedRuleRequest]，以及默认的
// HTTP 传输实现 [sendRuleRequest]（Cookie / 请求头 / 请求体 / 重试 / 反爬检测）。
//
// 编排（准备 + 发送 + 解析 + 异常分类）见 `RuleEngine`。

import 'dart:async';

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/crawler/captcha_detector.dart';
import 'package:anime_flow/core/crawler/cookie_manager.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_exceptions.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/clients/plugin_site_client.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:dio/dio.dart';

final LiggLogger _logger = LiggLogger();

const int _maxAttempts = 3;

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
/// 默认是 [sendRuleRequest]；测试可把它换成假实现，从而在不发真实请求的
/// 前提下验证引擎的准备与解析逻辑（见 `RuleEngine`）。
typedef RuleRequestTransport = Future<String> Function(
  PreparedRuleRequest request,
  CrawlConfigItem config,
);

/// 默认传输：真实 HTTP 请求，带重试与反爬检测。
Future<String> sendRuleRequest(
  PreparedRuleRequest request,
  CrawlConfigItem crawlConfig,
) async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
    try {
      final response = await _send(request, crawlConfig);
      if (response.trim().isEmpty) {
        throw StateError('empty response');
      }

      _ensureCaptchaNotDetected(response, crawlConfig);
      return response;
    } on CaptchaRequiredException {
      rethrow;
    } catch (error, stackTrace) {
      if (_isCaptchaChallengeResponse(error, crawlConfig)) {
        _logger.w(
          'RuleRequest: ${crawlConfig.name} '
          'detected captcha challenge response',
        );
        throw CaptchaRequiredException(crawlConfig.name);
      }
      lastError = error;
      lastStackTrace = stackTrace;
      _logger.w(
        'RuleRequest: ${crawlConfig.name} request attempt '
        '$attempt/$_maxAttempts failed: ${request.url}',
        error: error,
      );
      if (attempt < _maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}

Future<String> _send(
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

void _ensureCaptchaNotDetected(
  String response,
  CrawlConfigItem crawlConfig,
) {
  if (CaptchaDetector.detects(response, crawlConfig.antiCrawlerConfig)) {
    _logger.w('RuleRequest: ${crawlConfig.name} detected captcha challenge');
    throw CaptchaRequiredException(crawlConfig.name);
  }
}

/// 判断一次失败是否其实是反爬挑战页。
///
/// Dio 会在非 2xx 时先抛出异常，被保护的站点常以 403/429/503 返回挑战页，
/// 因此解析层没有机会看到响应体；这里复用被保留的 Dio 响应体与
/// `cf-mitigated: challenge` 头来补上这次判断。
bool _isCaptchaChallengeResponse(
  Object error,
  CrawlConfigItem crawlConfig,
) {
  if (!crawlConfig.antiCrawlerConfig.enabled) return false;
  if (error is! NetworkException ||
      error.type != NetworkExceptionType.badResponse) {
    return false;
  }

  final rawError = error.rawError;
  if (rawError is! DioException) return false;

  final response = rawError.response;
  final cfMitigated = response?.headers.value('cf-mitigated');
  if (cfMitigated?.toLowerCase() == 'challenge') return true;

  final data = response?.data;
  final raw = data is String ? data : data?.toString() ?? '';
  if (raw.trim().isEmpty) return false;

  try {
    return CaptchaDetector.detects(raw, crawlConfig.antiCrawlerConfig);
  } catch (_) {
    return false;
  }
}

Future<String> _cookieHeaderFor(String url, String name) async {
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
