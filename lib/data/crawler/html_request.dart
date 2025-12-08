import 'dart:async';
import 'dart:math';
import 'package:anime_flow/data/crawler/html_crawler.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/search_resources_item.dart';
import 'package:anime_flow/utils/http/dio_request.dart';
import 'package:dio/dio.dart';
import 'package:anime_flow/constants/constants.dart';
import 'package:logger/logger.dart';

class WebRequest {
  static Logger logger = Logger();

  ///获取搜索条目列表
  static Future<List<SearchResourcesItem>> getSearchSubjectListService(
      String keyword, CrawlConfigItem crawlConfig) async {
    final String searchURL = crawlConfig.searchURL;
    final userAgent = Constants
        .userAgentList[Random().nextInt(Constants.userAgentList.length)];

    final response =
    await dioRequest.get(searchURL.replaceFirst("{keyword}", keyword),
        options: Options(headers: {
          Constants.userAgentName: userAgent,
        }));
    return HtmlCrawler.parseSearchHtml(response.data, crawlConfig);
  }

  ///获取剧集资源列表
  static Future<List<CrawlerEpisodeResourcesItem>> getResourcesListService(
      String link, CrawlConfigItem crawlConfig) async {
    final String baseURL = crawlConfig.baseURL;

    final userAgent = Constants
        .userAgentList[Random().nextInt(Constants.userAgentName.length)];

    final response = await dioRequest.get(baseURL + link,
        options: Options(headers: {
          Constants.userAgentName: userAgent,
        }));
    return HtmlCrawler.parseResourcesHtml(response.data, crawlConfig);
  }

  /// 获取视频源
  static Future<String> getVideoSourceService(
      String link, VideoConfig videoConfig) async {
    final String baseUrl = videoConfig.baseURL;
    final url = baseUrl + link;

    // 根据平台选择不同的实现方式
    return HtmlCrawler.getVideoSourceWithInAppWebView(url, videoConfig);
  }
}
