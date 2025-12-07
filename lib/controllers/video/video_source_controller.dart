import 'package:anime_flow/data/crawler/html_request.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:anime_flow/models/item/video/search_resources_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:get/get.dart';

/// 视频源控制器
class VideoSourceController extends GetxController {
  final RxString videoRul = ''.obs;

  void setVideoUrl(String url) {
    videoRul.value = url;
  }

  //获取剧集资源
  Future<List<EpisodeResourcesItem>> getEpisodeResources(
      String keyword, CrawlConfigItem config) async {
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

    return allEpisodesList;
  }
}
