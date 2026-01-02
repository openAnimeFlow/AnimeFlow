import 'dart:async';
import 'dart:math';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/search_resources_item.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:logger/logger.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class HtmlCrawler {
  static Logger logger = Logger();
  // static HeadlessInAppWebView? _currentWebView;
  static Completer<String>? _currentCompleter;

  /// 取消当前的视频源请求
  // static Future<void> cancelCurrentVideoRequest() async {
  //   if (_currentWebView != null) {
  //     logger.w('取消上一次视频源请求');
  //     try {
  //       await _currentWebView?.dispose();
  //       _currentWebView = null;
  //     } catch (e) {
  //       logger.e('取消请求时出错: $e');
  //     }
  //   }
  //
  //   if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
  //     _currentCompleter!.completeError('请求已取消');
  //     _currentCompleter = null;
  //   }
  // }

  /// 跟随重定向获取最终URL
  static Future<String> _followRedirects(String url, String userAgent) async {
    try {
      final response = await dioRequest.head(
        url,
        options: Options(
          followRedirects: true, // 自动跟随重定向
          maxRedirects: 5, // 最多跟随5次重定向
          validateStatus: (status) => status != null && status < 400,
          headers: {
            'User-Agent': userAgent,
            'Referer': url,
          },
        ),
      );

      // 返回最终的 URL（已跟随重定向）
      final finalUrl = response.realUri.toString();
      if (finalUrl != url) {
        logger.i('🔀 重定向: $url → $finalUrl');
      }
      return finalUrl;
    } catch (e) {
      logger.w('跟随重定向失败，使用原始URL: $e');
      return url; // 如果失败，返回原始URL
    }
  }

  ///解析html搜索页
  static Future<List<SearchResourcesItem>> parseSearchHtml(
      String searchHtml, CrawlConfigItem crawlConfig) async {
    final String searchList = crawlConfig.searchList;
    final String searchName = crawlConfig.searchName;
    final String searchLink = crawlConfig.searchLink;

    final parser = parse(searchHtml).documentElement!;

    final searchListElement = parser.queryXPath(searchList);
    final searchNameElement = parser.queryXPath('$searchList$searchName');
    final searchLinkElement = parser.queryXPath('$searchList$searchLink');

    final List<SearchResourcesItem> resourcesItems = List.generate(
      searchListElement.nodes.length,
      (i) => SearchResourcesItem(
        name: searchNameElement.nodes[i].text?.trim() ?? '',
        link: searchLinkElement.nodes[i].attributes['href'] ?? '',
      ),
    );

    logger.i("搜索结果:${resourcesItems.toString()}");
    return resourcesItems;
  }

  ///解析html资源页面
  static Future<List<CrawlerEpisodeResourcesItem>> parseResourcesHtml(
      String resourcesHtml, CrawlConfigItem crawlConfig) async {
    final String lineNames = crawlConfig.lineNames;
    final String lineList = crawlConfig.lineList;
    final String episode = crawlConfig.episode;

    final parser = parse(resourcesHtml).documentElement!;
    final lineNamesElement = parser.queryXPath(lineNames);
    final lineListElement = parser.queryXPath(lineList);

    List<CrawlerEpisodeResourcesItem> episodeResourcesList = [];

    // 根据lineListElement长度循环（每个线路）
    for (int i = 0; i < lineListElement.nodes.length; i++) {
      // 获取线路名称（只提取直接文本节点，不包括子元素的文本）
      String lineName = '';
      if (i < lineNamesElement.nodes.length) {
        final lineNameNode = lineNamesElement.nodes[i];
        // 访问原始 Element，提取直接文本节点（不包括子元素的文本）
        final element = lineNameNode.node;
        // 提取直接文本节点（不包括子元素的文本）
        final directTextNodes = element.nodes
            .whereType<Text>()
            .map((text) => text.text)
            .join('')
            .trim();
        lineName = directTextNodes;
      }

      // 将lineListElement转换为HTML元素，在该元素内查找剧集
      final currentLineElement = lineListElement.nodes[i];
      final currentEpisodesElement = currentLineElement.queryXPath(episode);

      // 提取当前线路的所有剧集
      List<Episode> episodes = [];
      for (int j = 0; j < currentEpisodesElement.nodes.length; j++) {
        var episodeNode = currentEpisodesElement.nodes[j];
        int episodeStr = (j + 1);
        //TODO episodeLike需要单独创建一个xpath配置
        String episodeLike = episodeNode.attributes['href'] ?? '';

        Episode episodeObj = Episode(
          episodeSort: episodeStr,
          like: episodeLike,
        );
        episodes.add(episodeObj);
      }

      // 创建EpisodeResources对象
      CrawlerEpisodeResourcesItem episodeResource = CrawlerEpisodeResourcesItem(
        lineNames: lineName,
        episodes: episodes,
      );

      episodeResourcesList.add(episodeResource);
    }

    logger.i("线路资源:${episodeResourcesList.toString()}");
    return episodeResourcesList;
  }

  ///解析html视频源
  // static Future<String> getVideoSourceWithInAppWebView(
  //     String url, VideoConfig videoConfig) async {
  //   // 取消上一次请求
  //   await cancelCurrentVideoRequest();
  //
  //   final userAgent = Constants
  //       .userAgentList[Random().nextInt(Constants.userAgentList.length)];
  //   final bool enableNestedUrl = videoConfig.enableNestedUrl;
  //   final String matchNestedUrl = videoConfig.matchNestedUrl;
  //   final String matchVideoUrl = videoConfig.matchVideoUrl;
  //
  //   final RegExp matchNestedRegex = RegExp(matchNestedUrl);
  //   final RegExp matchVideoRegex = RegExp(matchVideoUrl);
  //
  //   final Completer<String> completer = Completer<String>();
  //   _currentCompleter = completer;
  //
  //   final headlessWebView = HeadlessInAppWebView(
  //     initialUrlRequest: URLRequest(url: WebUri(url), headers: {
  //       Constants.userAgentName: userAgent,
  //     }),
  //     initialSettings: InAppWebViewSettings(
  //       // 启用网络拦截
  //       useShouldInterceptRequest: true,
  //       // 允许后台播放
  //       // mediaPlaybackRequiresUserGesture: false,
  //     ),
  //
  //     // 拦截所有网络请求
  //     shouldInterceptRequest: (controller, request) async {
  //       final requestUrl = request.url.toString();
  //       if(enableNestedUrl) {
  //         final videoMatches = matchNestedRegex.allMatches(requestUrl);
  //
  //         if (videoMatches.isNotEmpty && !completer.isCompleted) {
  //           final videoUrl = requestUrl.split('url=')[1];
  //           logger.i('视频源: $videoUrl');
  //           completer.complete(videoUrl);
  //         }
  //       } else {
  //         //直接匹配
  //       }
  //
  //       // 返回 null 继续正常请求
  //       return null;
  //     },
  //     onLoadStop: (controller, uri) async {
  //       // 页面加载完成，等待资源请求完成
  //       logger.i('📄 页面加载完成: $uri');
  //     },
  //   );
  //
  //   try {
  //     // 启动无头 WebView
  //     await headlessWebView.run();
  //     _currentWebView = headlessWebView;
  //
  //     final result = await completer.future.timeout(
  //       const Duration(seconds: 60),
  //       onTimeout: () {
  //         throw TimeoutException('获取视频源超时');
  //       },
  //     );
  //     return result;
  //   } catch (e) {
  //     logger.e('获取视频源失败: $e');
  //     rethrow;
  //   } finally {
  //     // 清理资源
  //     if (_currentWebView == headlessWebView) {
  //       _currentWebView = null;
  //     }
  //     if (_currentCompleter == completer) {
  //       _currentCompleter = null;
  //     }
  //     await headlessWebView.dispose();
  //   }
  // }
}
