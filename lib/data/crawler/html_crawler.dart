import 'dart:async';

import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/search_resources_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
import 'package:logger/logger.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class HtmlCrawler {
  static Logger logger = Logger();

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
      // 获取线路名称
      String lineName = '';
      if (i < lineNamesElement.nodes.length) {
        lineName = lineNamesElement.nodes[i].text?.trim() ?? '';
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
  static Future<String> getVideoSourceWithInAppWebView(
      String url, VideoConfig videoConfig) async {
    final bool enableNestedUrl = videoConfig.enableNestedUrl;
    final String matchNestedUrl = videoConfig.matchNestedUrl;
    final String matchVideoUrl = videoConfig.matchVideoUrl;
    final RegExp videoRegex = RegExp(
      matchVideoUrl,
      caseSensitive: false,
    );

    final Completer<String> completer = Completer<String>();
    late InAppWebViewController webViewController;

    final headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      onLoadStop: (controller, uri) async {
        try {
          // 等待页面 JavaScript 执行完成
          await Future.delayed(const Duration(seconds: 3));

          // 获取页面 HTML 内容
          final html = await controller.evaluateJavascript(
              source: "document.documentElement.outerHTML");

          if (html != null) {
            // 清理返回的 HTML 字符串
            final cleanHtml = html
                .toString()
                .replaceAll(r'\n', '\n')
                .replaceAll(r'\"', '"')
                .replaceAll(r"\'", "'");

            // 查找视频链接
            final directMatches = videoRegex.allMatches(cleanHtml);
            if (directMatches.isNotEmpty) {
              final foundVideoUrl = directMatches.first.group(0);

              if (!completer.isCompleted) {
                if (enableNestedUrl) {
                  final nestedUrlRegex = RegExp(matchNestedUrl);
                  final nestedUrlMatches =
                      nestedUrlRegex.allMatches(foundVideoUrl!);
                  logger.i("原链接: $foundVideoUrl");
                  final realVideoUrl = nestedUrlMatches.first.group(0);
                  completer.complete(realVideoUrl);
                  logger.i('✅ 找到视频源 (嵌套匹配): $realVideoUrl');
                } else {
                  logger.i('✅ 找到视频源 (直接匹配): $foundVideoUrl');
                  completer.complete(foundVideoUrl);
                }
              }
            }
          }
        } catch (e) {
          logger.e('提取视频源时出错: $e');
          if (!completer.isCompleted) {
            completer.completeError('提取视频源失败: $e');
          }
        }
      },
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
    );

    try {
      // 启动无头 WebView
      await headlessWebView.run();

      //等待结果，超时时间 30 秒
      final result = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('获取视频源超时');
        },
      );
      logger.i('✅ 最终返回视频源: $result');
      return result;
    } finally {
      // 清理资源
      await headlessWebView.dispose();
    }
  }
}
