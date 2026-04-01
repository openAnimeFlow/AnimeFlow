import 'dart:async';

import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/models/item/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/play/video/search_resources_item.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
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

    return episodeResourcesList;
  }
}
