import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/crawler/html_request.dart';
import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/models/item/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/play/video/resources_item.dart';
import 'package:anime_flow/models/item/play/video/search_resources_item.dart';
import 'package:anime_flow/providers/video/video_source_provider.dart';
import 'package:anime_flow/providers/video/webview_video_source_provider.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class VideoSourceController extends GetxController {
  final RxList<ResourcesItem> videoResources = <ResourcesItem>[].obs;
  final RxString webSiteTitle = ''.obs;
  final RxString webSiteIcon = ''.obs;
  final RxString videoUrl = ''.obs;
  final RxString keyword = ''.obs;
  final RxBool isLoading = false.obs;

  /// 当前选中的网站索引
  final RxInt selectedWebsiteIndex = 0.obs;
  final RxBool isInitWebView = false.obs;

  late EpisodesState _episodesState;
  late PlaySubjectState _subjectState;
  final Logger _logger = Logger();

  /// 标记用户是否手动选择了资源
  bool userManuallySelected = false;

  Worker? _isLoadingWorker;
  Worker? _episodeIndexWorker;

  WebViewVideoSourceProvider? _videoSourceProvider;

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
    _subjectState = Get.find<PlaySubjectState>();
    _episodesState = Get.find<EpisodesState>();
  }

  //初始化
  Future<void> _initVideoResources() async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    final resources = configs.map((config) {
      return ResourcesItem(
        websiteName: config.name,
        websiteIcon: config.iconUrl,
        baseUrl: config.baseUrl,
        searchUrl: config.searchUrl,
        needsCaptcha: config.antiCrawlerConfig.enabled,
        episodeResources: [],
      );
    }).toList();
    videoResources.value = resources;
  }

  //初始化资源
  Future<void> initResources(String keyword) async {
    _clearAllResources();
    this.keyword.value = keyword;
    // 重置手动选择标志，允许重新自动选择
    userManuallySelected = false;
    updateLoading(false);
    final configs = await CrawlConfig.loadAllCrawlConfigs();

    // 错开发起时间（相邻间隔 0.5 秒），不串行等待每个请求；全部完成后再结束加载态
    final futures = <Future<void>>[];
    for (var i = 0; i < configs.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      futures.add(_getResources(keyword, configs[i]));
    }
    await Future.wait(futures);
    updateLoading(true);
  }

  void _clearAllResources() {
    final currentResources = videoResources;
    final clearedResources = currentResources.map((resource) {
      return ResourcesItem(
        websiteName: resource.websiteName,
        websiteIcon: resource.websiteIcon,
        baseUrl: resource.baseUrl,
        searchUrl: resource.searchUrl,
        episodeResources: [],
        isLoading: false,
        errorMessage: null,
        needsCaptcha: false,
      );
    }).toList();

    videoResources.value = clearedResources;
  }

  /// 重新请求指定站点的资源（验证通过后调用）
  Future<void> retryResources(String websiteName) async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    final config = configs.firstWhereOrNull((c) => c.name == websiteName);
    if (config == null) return;
    await _getResources(keyword.value, config);
  }

  Future<void> _getResources(String keyword, CrawlConfigItem config) async {
    try {
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

      List<SearchResourcesItem> searchList =
          await WebRequest.getSearchSubjectListService(keyword, config);
      List<EpisodeResourcesItem> allEpisodesList = [];

      for (var search in searchList) {
        var crawlerEpisodeResources =
            await WebRequest.getResourcesListService(search.link, config);

        for (var crawlerResource in crawlerEpisodeResources) {
          var episodeResource = EpisodeResourcesItem(
            lineNames: crawlerResource.lineNames,
            episodes: crawlerResource.episodes,
            subjectsTitle: search.name,
          );
          allEpisodesList.add(episodeResource);
        }
      }

      _updateResourceStatus(
        config.name,
        isLoading: false,
        episodeResources: allEpisodesList,
        needsCaptcha: false,
      );
    } on CaptchaRequiredException {
      _updateResourceStatus(
        config.name,
        isLoading: false,
        needsCaptcha: true,
        antiCrawlerConfig: config.antiCrawlerConfig,
        errorMessage: null,
      );
    } catch (e) {
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

  void _updateResourceStatus(
    String websiteName, {
    bool? isLoading,
    List<EpisodeResourcesItem>? episodeResources,
    String? errorMessage,
    bool? needsCaptcha,
    AntiCrawlerConfig? antiCrawlerConfig,
  }) {
    final currentResources = videoResources.toList();
    final updatedResources = currentResources.map((resource) {
      if (resource.websiteName == websiteName) {
        return resource.copyWith(
          isLoading: isLoading,
          episodeResources: episodeResources,
          errorMessage: errorMessage,
          needsCaptcha: needsCaptcha,
          antiCrawlerConfig: antiCrawlerConfig,
        );
      }
      return resource;
    }).toList();

    videoResources.value = updatedResources;
  }

  /// 设置当前选中的网站
  void setWebSite({
    required String title,
    required String iconUrl,
    required String videoUrl,
    bool isManual = false,
  }) {
    if (isManual) {
      userManuallySelected = true;
    }
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
  void autoSelectFirstResource(List<ResourcesItem> resources,
      {bool force = false}) {
    // 如果用户手动选择了资源，不再自动选择
    if (userManuallySelected) {
      return;
    }
    // 如果已经自动选择过，且不是强制重新选择，或者已经有选中的资源且不是强制重新选择，不再自动选择
    if (!force && (webSiteTitle.value.isNotEmpty)) {
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

    // 自动加载第一个匹配的资源
    Future.microtask(() {
      _autoLoadFirstResource(selectedResource, force: force);
    });
  }

  /// 自动加载第一个匹配当前剧集的资源
  /// [force] 是否强制重新加载，即使已经有选中的资源
  Future<void> _autoLoadFirstResource(ResourcesItem resource,
      {bool force = false}) async {
    // 如果用户手动选择了资源，不再自动加载
    if (userManuallySelected) {
      return;
    }
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
        setWebSite(
          title: resource.websiteName,
          iconUrl: resource.websiteIcon,
          videoUrl: resource.baseUrl + currentEpisode.like,
        );
        // _videoStateController.disposeVideo();
        await loadVideoPage(resource.baseUrl + currentEpisode.like);
        return;
      }
    }
  }

  /// 加载视频页面
  Future<void> loadVideoPage(String url) async {
    _videoSourceProvider?.cancel();

    final playController = Get.find<PlayController>();
    playController.isParsing.value = true;

    _videoSourceProvider ??= WebViewVideoSourceProvider();

    int offset = 0;
    final subjectId = _subjectState.subject.value.id;
    final episodeIndex = _episodesState.episodeIndex.value;
    final subjectName = _subjectState.subject.value.name;
    final subjectCover = _subjectState.subject.value.image;
    final position = await PlayRepository.getPlayHistory(subjectId);
    if (position != null &&
        position.position > 0 &&
        position.episodeSort == episodeIndex) {
      offset = position.position;
    }
    try {
      final videoUiStateController = Get.find<VideoUiStateController>();

      videoUiStateController
          .updateIndicatorType(VideoControlsIndicatorType.parsingIndicator);
      videoUiStateController.updateMainAxisAlignmentType(MainAxisAlignment.center);
      videoUiStateController.showIndicator();
      playController.parseResult.value = '正在解析视频源...';
      final source = await _videoSourceProvider!
          .resolve(url, useLegacyParser: false, offset: offset);
      playController.isParsing.value = false;
      playController.parseResult.value = '视频解析成功';
      await playController.initPlayState(PlayState(
        videoUrl: source.url,
        offset: source.offset,
        subjectId: subjectId,
        subjectName: subjectName,
        subjectCover: subjectCover,
        episodeIndex: episodeIndex,
        episodeId: _episodesState.episodeId.value,
      ));
    } on VideoSourceTimeoutException {
      playController.isParsing.value = false;
      playController.parseResult.value = '视频解析超时，请重试';
    } on VideoSourceNotFoundException {
      playController.isParsing.value = false;
      playController.parseResult.value = '为找到视频资源，请切换数据源重试';
    } catch (e) {
      playController.isParsing.value = false;
      playController.parseResult.value = '视频解析失败：${e.toString()}';
      _logger.e( e);
    }
  }

  /// 取消当前视频源解析并销毁 Provider
  void cancelVideoSourceResolution() {
    _videoSourceProvider?.dispose();
    _videoSourceProvider = null;
  }
}
