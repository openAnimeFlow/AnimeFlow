import 'package:anime_flow/data/crawler/html_request.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:anime_flow/models/item/video/search_resources_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:get/get.dart';

class VideoSourceController extends GetxController {
  late final Rx<List<ResourcesItem>> videoResources;
  final RxString webSiteTitle = ''.obs;
  final RxString webSiteIcon = ''.obs;
  final RxString videoUrl = ''.obs;
  final RxString keyword = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
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
        baseUrl: config.baseUrl,
        episodeResources: [],
      );
    }).toList();
    videoResources.value = resources;
  }

  //初始化资源
  Future<void> initResources(String keyword) async {
    _clearAllResources();
    this.keyword.value = keyword;
    updateLoading(false); // 开始获取资源，设置为 false
    final configs = await CrawlConfig.loadAllCrawlConfigs();

    // 并发执行所有网站的资源获取
    await Future.wait(
      configs.map((config) => _getResources(keyword, config)),
    );
    updateLoading(true); // 所有资源获取完成，设置为 true
  }

  void _clearAllResources() {
    final currentResources = videoResources.value;
    final clearedResources = currentResources.map((resource) {
      return ResourcesItem(
        websiteName: resource.websiteName,
        websiteIcon: resource.websiteIcon,
        baseUrl: resource.baseUrl,
        episodeResources: [],
        isLoading: false,
        errorMessage: null,
      );
    }).toList();

    videoResources.value = clearedResources;
  }

  Future<void> _getResources(String keyword, CrawlConfigItem config) async {
    try {
      // 设置解析中状态
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

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

      // 更新资源并设置完成状态
      _updateResourceStatus(
        config.name,
        isLoading: false,
        episodeResources: allEpisodesList,
      );
    } catch (e) {
      // 解析失败，设置错误状态
      _updateResourceStatus(
        config.name,
        isLoading: false,
        errorMessage: '解析失败: $e',
      );
    }
  }

  void updateLoading(bool isLoading) {
    this.isLoading.value = isLoading;
  }

  // 更新指定网站的状态
  void _updateResourceStatus(String websiteName, {
    bool? isLoading,
    List<EpisodeResourcesItem>? episodeResources,
    String? errorMessage,
  }) {
    final currentResources = videoResources.value;
    final updatedResources = currentResources.map((resource) {
      if (resource.websiteName == websiteName) {
        return resource.copyWith(
          isLoading: isLoading,
          episodeResources: episodeResources,
          errorMessage: errorMessage,
        );
      }
      return resource;
    }).toList();

    videoResources.value = updatedResources;
  }

  void setWebSite(
      {required String title, required String iconUrl, required String videoUrl}) {
    webSiteTitle.value = title;
    webSiteIcon.value = iconUrl;
    this.videoUrl.value = videoUrl;
  }
}
