import 'dart:async';
import 'dart:math' show min;

import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/crawler/itme/bgm_user_page_item.dart' show BgmUserStatisticsItem, Statistic;
import 'package:anime_flow/models/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/play/video/search_resources_item.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class HtmlCrawler {
  static LiggLogger logger = LiggLogger();

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

    try {
      final listNodes = searchListElement.nodes;
      final nameNodes = searchNameElement.nodes;
      final linkNodes = searchLinkElement.nodes;
      // searchList / name / link 的 XPath 命中数可能不一致，取最短长度避免 RangeError
      final rowCount = min(
        min(listNodes.length, nameNodes.length),
        linkNodes.length,
      );
      final List<SearchResourcesItem> resourcesItems = List.generate(
        rowCount,
        (i) => SearchResourcesItem(
          name: nameNodes[i].text?.trim() ?? '',
          link: linkNodes[i].attributes['href'] ?? '',
        ),
      );

      logger.i("搜索结果:${resourcesItems.toString()}");
      return resourcesItems;
    } catch (e) {
      logger.e("解析搜索结果出错:$e");
      return [];
    }
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

    // logger.i("线路资源:${episodeResourcesList.toString()}");
    return episodeResourcesList;
  }

  ///解析用户页面数据（#userStats_all 第一个 div 下每项为一组 value/name）
  static Future<BgmUserStatisticsItem> parseUserPage(String userPageHtml) async {
    const String statisticsDocument = '//*[@id="userStats_all"] /div[1] /div';
    final parser = parse(userPageHtml).documentElement!;

    final rowElements = parser.queryXPath(statisticsDocument);
    final List<Statistic> statistics = [];

    for (final row in rowElements.nodes) {
      final valueElement = row.queryXPath('/span[1]');
      final nameElement = row.queryXPath('/span[2]');

      final value = valueElement.nodes.isNotEmpty
          ? valueElement.nodes[0].text?.trim() ?? ''
          : '';
      final name = nameElement.nodes.isNotEmpty
          ? nameElement.nodes[0].text?.trim() ?? ''
          : '';

      statistics.add(Statistic(value: value, name: name));
    }

    return BgmUserStatisticsItem(statistics: statistics);
  }
}
