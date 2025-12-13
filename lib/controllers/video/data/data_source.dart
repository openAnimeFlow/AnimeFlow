import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:get/get.dart';

class DataSource extends GetxController {
  late final Rx<List<ResourcesItem>> videoResources;

  DataSource() {
    videoResources = Rx<List<ResourcesItem>>([]);
    _initVideoResources();
  }

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
}
