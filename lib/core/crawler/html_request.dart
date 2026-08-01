import 'dart:async';

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/models/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/play/video/search_resources_item.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:dio/dio.dart';
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

class WebRequest {
  static LiggLogger logger = LiggLogger();
  static const int _maxAttempts = 3;

  ///获取搜索条目列表
  static Future<List<SearchResourcesItem>> getSearchSubjectListService(
      String keyword, CrawlConfigItem crawlConfig) async {
    final requestUrl = crawlConfig.searchUrl.replaceFirst(
      '{keyword}',
      Uri.encodeQueryComponent(keyword),
    );
    final cookie = await _cookieHeaderFor(requestUrl, crawlConfig.name);

    final httpHeaders = {
      'referer': '${crawlConfig.baseUrl}/',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept-Language': Utils.getRandomAcceptedLanguage(),
      'Connection': 'keep-alive',
      Constants.userAgentName: Utils.getRandomUA(),
      if (cookie.isNotEmpty) 'Cookie': cookie
    };
    final response = await _getHtmlWithRetry(
      requestUrl,
      httpHeaders,
      crawlConfig,
    );

    return HtmlCrawler.parseSearchHtml(response, crawlConfig);
  }

  ///获取剧集资源列表
  static Future<List<CrawlerEpisodeResourcesItem>> getResourcesListService(
      String link, CrawlConfigItem crawlConfig) async {
    final String baseURL = crawlConfig.baseUrl;
    String linkUrl;
    if (link.startsWith("http")) {
      linkUrl = link;
    } else {
      linkUrl = baseURL + link;
    }
    final cookie = await _cookieHeaderFor(linkUrl, crawlConfig.name);
    final httpHeaders = {
      'referer': '${crawlConfig.baseUrl}/',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept-Language': Utils.getRandomAcceptedLanguage(),
      'Connection': 'keep-alive',
      Constants.userAgentName: Utils.getRandomUA(),
      if (cookie.isNotEmpty) 'Cookie': cookie,
    };

    final response = await _getHtmlWithRetry(
      linkUrl,
      httpHeaders,
      crawlConfig,
    );
    return HtmlCrawler.parseResourcesHtml(response, crawlConfig);
  }

  static Future<String> _getHtmlWithRetry(
    String url,
    Map<String, dynamic> headers,
    CrawlConfigItem crawlConfig,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await Api.getResources<String>(
          url,
          options: Options(
            headers: headers,
            responseType: ResponseType.plain,
          ),
        );
        if (response.trim().isEmpty) {
          throw StateError('empty HTML response');
        }

        _ensureCaptchaNotDetected(response, crawlConfig);
        return response;
      } on CaptchaRequiredException {
        rethrow;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        logger.w(
          'WebRequest: ${crawlConfig.name} request attempt '
          '$attempt/$_maxAttempts failed: $url',
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
      logger.w('WebRequest: ${crawlConfig.name} detected captcha challenge');
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
