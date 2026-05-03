import 'dart:async';
import 'dart:math';
import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/play/video/search_resources_item.dart';
import 'package:dio/dio.dart';
import 'package:anime_flow/constants/constants.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:logger/logger.dart';

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
  static Logger logger = Logger();

  ///获取搜索条目列表
  static Future<List<SearchResourcesItem>> getSearchSubjectListService(
      String keyword, CrawlConfigItem crawlConfig) async {
    final String searchURL = crawlConfig.searchUrl;
    final userAgent = Constants
        .userAgentList[Random().nextInt(Constants.userAgentList.length)];
    final requestUrl = searchURL.replaceFirst("{keyword}", keyword);
    final cookie = await _cookieHeaderFor(requestUrl, crawlConfig.name);

    final httpHeaders = {
      'referer': '$searchURL/',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Connection': 'keep-alive',
      Constants.userAgentName: userAgent,
      if (cookie.isNotEmpty) 'Cookie': cookie
    };
    final response = await dioRequest.get(requestUrl,
        options: Options(headers: httpHeaders));

    final antiCrawler = crawlConfig.antiCrawlerConfig;
    if (antiCrawler.enabled) {
      final htmlElement =
          html_parser.parse(response.data.toString()).documentElement!;
      final detectionXpaths = [
        antiCrawler.captchaImage,
        antiCrawler.captchaButton,
      ].where((x) => x.isNotEmpty).toList();
      final captchaDetected = detectionXpaths
          .any((xpath) => htmlElement.queryXPath(xpath).node != null);
      if (captchaDetected) {
        logger.w('WebRequest: ${crawlConfig.name} detected captcha challenge');
        throw CaptchaRequiredException(crawlConfig.name);
      }
    }

    return HtmlCrawler.parseSearchHtml(response.data, crawlConfig);
  }

  ///获取剧集资源列表
  static Future<List<CrawlerEpisodeResourcesItem>> getResourcesListService(
      String link, CrawlConfigItem crawlConfig) async {
    final String baseURL = crawlConfig.baseUrl;

    final userAgent = Constants
        .userAgentList[Random().nextInt(Constants.userAgentName.length)];

    String linkUrl;
    if (link.startsWith("http")) {
      linkUrl = link;
    } else {
      linkUrl = baseURL + link;
    }

    final response = await dioRequest.get(linkUrl,
        options: Options(headers: {
          Constants.userAgentName: userAgent,
        }));
    return HtmlCrawler.parseResourcesHtml(response.data, crawlConfig);
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
