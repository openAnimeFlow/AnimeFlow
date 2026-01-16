import 'package:anime_flow/data/crawler/html_request.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/play/video/resources_item.dart';
import 'package:anime_flow/models/item/play/video/search_resources_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class VideoSourceController extends GetxController {
  final RxList<ResourcesItem> videoResources = <ResourcesItem>[].obs;
  final RxString webSiteTitle = ''.obs;
  final RxString webSiteIcon = ''.obs;
  final RxString videoUrl = ''.obs;
  final RxString keyword = ''.obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedWebsiteIndex = 0.obs; // 当前选中的网站索引

  late EpisodesState _episodesState;
  late VideoStateController _videoStateController;
  late WebviewItemController _webviewItemController;
  final Logger _logger = Logger();

  bool _hasAutoSelected = false; // 标记是否已经自动选择过
  Worker? _isLoadingWorker;
  Worker? _episodeIndexWorker;

  @override
  void onInit() async {
    super.onInit();
    await _initVideoResources();
    _initControllers();
  }

  @override
  void onClose() {
    _isLoadingWorker?.dispose();
    _episodeIndexWorker?.dispose();
    super.onClose();
  }

  void _initControllers() {
    _episodesState = Get.find<EpisodesState>();
    _videoStateController = Get.find<VideoStateController>();
    _webviewItemController = Get.find<WebviewItemController>();
  }

  // void _setupAutoSelectListeners() {
  //   // 监听 isLoading 变化，当所有资源获取完成时（isLoading == true）自动选择第一个有资源的网站
  //   _isLoadingWorker = ever(isLoading, (bool isLoading) {
  //     if (isLoading) {
  //       // 当 isLoading 变为 true 时，说明所有网站的资源获取完成
  //       final resources = videoResources.toList();
  //       autoSelectFirstResource(resources);
  //     }
  //   });
  //
  //   // 监听 episodeIndex 变化
  //   _episodeIndexWorker = ever(_episodesState.episodeIndex, (int newIndex) {
  //     if (newIndex != _lastEpisodeIndex && newIndex > 0) {
  //       _lastEpisodeIndex = newIndex;
  //       // 重置自动选择标志，允许重新自动选择
  //       _hasAutoSelected = false;
  //       // 如果资源已经加载完成，强制重新自动选择
  //       if (isLoading.value) {
  //         final resources = videoResources.toList();
  //         autoSelectFirstResource(resources, force: true);
  //       }
  //     }
  //   });
  // }

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
    updateLoading(false);
    final configs = await CrawlConfig.loadAllCrawlConfigs();

    // 并发执行所有网站的资源获取
    await Future.wait(
      configs.map((config) => _getResources(keyword, config)),
    );
    updateLoading(true);
  }

  void _clearAllResources() {
    final currentResources = videoResources;
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
    final currentResources = videoResources.toList();
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

  /// 查找第一个有资源的网站索引
  int _findFirstResourceIndex(List<ResourcesItem> dataSource) {
    for (int i = 0; i < dataSource.length; i++) {
      if (dataSource[i].episodeResources.isNotEmpty) {
        return i;
      }
    }
    return 0;
  }

  /// 自动选择第一个有资源的网站并加载视频
  /// [force] 是否强制重新选择，即使已经有选中的资源
  void autoSelectFirstResource(List<ResourcesItem> resources, {bool force = false}) {
    // 如果已经自动选择过，且不是强制重新选择，或者已经有选中的资源且不是强制重新选择，不再自动选择
    if (!force && (_hasAutoSelected || webSiteTitle.value.isNotEmpty)) {
      return;
    }

    // 检查是否有资源加载完成
    final hasResource = resources.any((r) => r.episodeResources.isNotEmpty);
    if (!hasResource) {
      return;
    }

    final firstResourceIndex = _findFirstResourceIndex(resources);
    final selectedResource = resources[firstResourceIndex];

    if (selectedResource.episodeResources.isEmpty) {
      return; // 没有找到有资源的网站
    }

    _hasAutoSelected = true;

    // 自动加载第一个匹配的资源
    Future.microtask(() {
      _autoLoadFirstResource(selectedResource, force: force);
    });
  }

  /// 自动加载第一个匹配当前剧集的资源
  /// [force] 是否强制重新加载，即使已经有选中的资源
  Future<void> _autoLoadFirstResource(ResourcesItem resource, {bool force = false}) async {
    // 如果不是强制重新加载，且已经有选中的资源，不再自动加载
    if (!force && webSiteTitle.value.isNotEmpty) {
      return;
    }

    // 遍历资源列表，找到第一个匹配当前剧集的资源
    for (var resourceItem in resource.episodeResources) {
      final matchingEpisodes = resourceItem.episodes.where(
            (ep) => ep.episodeSort == _episodesState.episodeIndex.value,
      );
      if (matchingEpisodes.isNotEmpty) {
        final currentEpisode = matchingEpisodes.first;
        try {
          setWebSite(
            title: resource.websiteName,
            iconUrl: resource.websiteIcon,
            videoUrl: resource.baseUrl + currentEpisode.like,
          );
          _videoStateController.disposeVideo();
          await loadVideoPage(resource.baseUrl + currentEpisode.like);
        } catch (e) {
          _logger.e('自动加载视频源失败', error: e);
        }
        return;
      }
    }
  }

  /// 加载视频页面
  Future<void> loadVideoPage(String url) async {
    _logger.d('加载视频页面: $url');
    await _webviewItemController.loadUrl(
      url,
      true, // useNativePlayer: 使用原生播放器
      true, // useLegacyParser: 不使用旧解析器
      offset: 0,
    );
  }
}
