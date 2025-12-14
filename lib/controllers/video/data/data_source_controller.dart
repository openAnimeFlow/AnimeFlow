import 'package:anime_flow/data/crawler/html_request.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:anime_flow/models/item/video/search_resources_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:get/get.dart';

class DataSourceController extends GetxController {
  late final Rx<List<ResourcesItem>> videoResources;

  DataSourceController() {
    videoResources = Rx<List<ResourcesItem>>([]);
    _initVideoResources();
  }

  //初始化
  Future<void> _initVideoResources() async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    final resources = configs.map((config) {
      return ResourcesItem(
        websiteName: config.name,
        websiteIcon: config.iconUrl,
        videoConfig: VideoConfig(
          enableNestedUrl: config.matchVideo.enableNestedUrl,
          matchNestedUrl: config.matchVideo.matchNestedUrl,
          matchVideoUrl: config.matchVideo.matchVideoUrl,
          baseURL: config.baseURL,
        ),
        episodeResources: [],
      );
    }).toList();
    videoResources.value = resources;
  }

  //初始化资源
  Future<void> initResources(String keyword) async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    for (var config in configs) {
      await _getResources(keyword, config);
    }
  }

  Future<void> _getResources(String keyword, CrawlConfigItem config) async {
    List<SearchResourcesItem> searchList =
        await WebRequest.getSearchSubjectListService(keyword, config);
    List<EpisodeResourcesItem> allEpisodesList = [];
    for (var search in searchList) {
      var crawlerEpisodeResources =
          await WebRequest.getResourcesListService(search.link, config);

      // 转换 CrawlerEpisodeResourcesItem 到 EpisodeResourcesItem
      for (var crawlerResource in crawlerEpisodeResources) {
        var episodeResource = EpisodeResourcesItem(
          lineNames: crawlerResource.lineNames,
          episodes: crawlerResource.episodes,
          subjectsTitle: search.name,
        );
        allEpisodesList.add(episodeResource);
      }
    }

    // 将 allEpisodesList 添加给 videoResources 的 episodeResources
    final currentResources = videoResources.value;
    final updatedResources = currentResources.map((resource) {
      if (resource.websiteName == config.name) {
        return ResourcesItem(
          websiteName: resource.websiteName,
          websiteIcon: resource.websiteIcon,
          videoConfig: resource.videoConfig,
          episodeResources: allEpisodesList,
        );
      }
      return resource;
    }).toList();

    videoResources.value = updatedResources;
  }
}
