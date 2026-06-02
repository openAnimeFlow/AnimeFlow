import 'package:anime_flow/crawler/cookie_manager.dart';
import 'package:anime_flow/crawler/html_request.dart';
import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/features/search_result_rank_service.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/models/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/play/video/resources_item.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/providers/video/video_source_provider.dart';
import 'package:anime_flow/providers/video/webview_video_source_provider.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/pages/play/provider/play_subject_provider.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class VideoSourceController extends GetxController {
  VideoSourceController(this._ref);

  final WidgetRef _ref;
  final videoResources = <ResourcesItem>[].obs;
  final webSiteTitle = ''.obs;
  final webSiteIcon = ''.obs;
  final videoUrl = ''.obs;
  final keyword = ''.obs;
  final isLoading = false.obs;

  /// 当前选中的网站索引
  final RxInt selectedWebsiteIndex = 0.obs;
  final RxBool isInitWebView = false.obs;

  late EpisodesState _episodesState;
  final LiggLogger _logger = LiggLogger();

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
        needsCaptcha: _requiresCaptcha(config),
        episodeResources: [],
      );
    }).toList();
    videoResources.value = resources;
  }

  //初始化资源
  Future<void> initResources(String keyword) async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    _clearAllResources(configs);
    this.keyword.value = keyword;
    userManuallySelected = false;
    isLoading.value = false;

    final futures = <Future<void>>[];
    for (var i = 0; i < configs.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      final config = configs[i];

      if (config.antiCrawlerConfig.enabled) {
        if (CookieManager.instance.hasCookies(config.name)) {
          futures.add(_getResources(keyword, config));
        } else {
          _updateResourceStatus(
            config.name,
            needsCaptcha: true,
            antiCrawlerConfig: config.antiCrawlerConfig,
          );
        }
        continue;
      }

      futures.add(_getResources(keyword, config));
    }

    await Future.wait(futures);
    isLoading.value = true;
  }

  void _clearAllResources(List<CrawlConfigItem> configs) {
    CrawlConfigItem? configFor(String name) {
      for (final c in configs) {
        if (c.name == name) {
          return c;
        }
      }
      return null;
    }

    final clearedResources = videoResources.map((resource) {
      final config = configFor(resource.websiteName);
      final anti = config?.antiCrawlerConfig;
      final captchaEnabled = anti?.enabled ?? false;

      return ResourcesItem(
        websiteName: resource.websiteName,
        websiteIcon: resource.websiteIcon,
        baseUrl: resource.baseUrl,
        searchUrl: resource.searchUrl,
        episodeResources: [],
        isLoading: false,
        errorMessage: null,
        needsCaptcha: captchaEnabled &&
            !CookieManager.instance.hasCookies(resource.websiteName),
        antiCrawlerConfig: captchaEnabled ? anti : null,
      );
    }).toList();

    videoResources.value = clearedResources;
  }

  /// 当前会话内已完成验证码验证（Cookie 已写入内存）
  void markCaptchaVerified(String websiteName) {
    _updateResourceStatus(
      websiteName,
      needsCaptcha: false,
      isLoading: true,
      errorMessage: null,
    );
  }

  bool _requiresCaptcha(CrawlConfigItem config) {
    return config.antiCrawlerConfig.enabled &&
        !CookieManager.instance.hasCookies(config.name);
  }

  /// 重新请求指定站点的资源（验证通过后调用）
  Future<void> retryResources(String websiteName) async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    final config = configs.firstWhereOrNull((c) => c.name == websiteName);
    if (config == null) {
      return;
    }
    await _getResources(keyword.value, config);
  }

  Future<void> _getResources(String keyword, CrawlConfigItem config) async {
    try {
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

      final rankService = SearchResultRankService(
        searchTerm: keyword,
        aliases: _ref.read(playSubjectProvider).subjectAliases,
      );
      final rawSearchList =
          await WebRequest.getSearchSubjectListService(keyword, config);
      final searchList = rankService.sort(rawSearchList, (item) => item.name);
      final allEpisodesList = <EpisodeResourcesItem>[];

      for (final search in searchList) {
        final crawlerEpisodeResources =
            await WebRequest.getResourcesListService(search.link, config);

        for (final crawlerResource in crawlerEpisodeResources) {
          allEpisodesList.add(
            EpisodeResourcesItem(
              lineNames: crawlerResource.lineNames,
              episodes: crawlerResource.episodes,
              subjectsTitle: search.name,
            ),
          );
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
    final updatedResources = videoResources.map((resource) {
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

  int _findFirstResourceIndex(List<ResourcesItem> resources) {
    for (var i = 0; i < resources.length; i++) {
      if (resources[i].episodeResources.isNotEmpty) {
        return i;
      }
    }
    return 0;
  }

  List<_AutoLoadCandidate> _buildAutoLoadCandidates(
      List<ResourcesItem> resources) {
    final candidates = <_AutoLoadCandidate>[];

    for (var websiteIndex = 0;
        websiteIndex < resources.length;
        websiteIndex++) {
      final resource = resources[websiteIndex];
      for (final resourceItem in resource.episodeResources) {
        final episode = resourceItem.episodes.firstWhereOrNull(
          (ep) => ep.episodeSort == _episodesState.episodeIndex.value,
        );
        if (episode == null) {
          continue;
        }

        candidates.add(
          _AutoLoadCandidate(
            websiteIndex: websiteIndex,
            resource: resource,
            episode: episode,
          ),
        );
      }
    }

    return candidates;
  }

  void autoSelectFirstResource(List<ResourcesItem> resources,
      {bool force = false}) {
    if (userManuallySelected) {
      return;
    }
    if (!force && webSiteTitle.value.isNotEmpty) {
      return;
    }

    final hasResource = resources.any((r) => r.episodeResources.isNotEmpty);
    if (!hasResource) {
      return;
    }

    selectedWebsiteIndex.value = _findFirstResourceIndex(resources);

    Future.microtask(() {
      _autoLoadFirstResource(resources, force: force);
    });
  }

  Future<void> _autoLoadFirstResource(List<ResourcesItem> resources,
      {bool force = false}) async {
    if (userManuallySelected) {
      return;
    }
    if (!force && webSiteTitle.value.isNotEmpty) {
      return;
    }

    final candidates = _buildAutoLoadCandidates(resources);
    for (final candidate in candidates) {
      selectedWebsiteIndex.value = candidate.websiteIndex;
      final candidateUrl = candidate.resource.baseUrl + candidate.episode.like;
      final loaded = await loadVideoPage(candidateUrl);
      if (!loaded) {
        continue;
      }

      setWebSite(
        title: candidate.resource.websiteName,
        iconUrl: candidate.resource.websiteIcon,
        videoUrl: candidateUrl,
      );
      return;
    }
  }

  /// 加载视频页面
  Future<bool> loadVideoPage(String url) async {
    _videoSourceProvider?.cancel();

    final playController = Get.find<PlayController>();
    playController.isParsing.value = true;

    _videoSourceProvider ??= WebViewVideoSourceProvider();

    var offset = 0;
    final subject = _ref.read(playSubjectProvider);
    final subjectId = subject.subjectId;
    final episodeIndex = _episodesState.episodeIndex.value;
    final subjectName = subject.subjectName;
    final subjectCover = subject.subjectCover;
    final subjectAlias = subject.subjectAliases;
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
      videoUiStateController
          .updateMainAxisAlignmentType(MainAxisAlignment.center);
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
        alias: subjectAlias,
        episodeId: _episodesState.episodeId.value,
      ));
      return true;
    } on VideoSourceTimeoutException {
      playController.isParsing.value = false;
      playController.parseResult.value = '视频解析超时，请重试';
    } on VideoSourceNotFoundException {
      playController.isParsing.value = false;
      playController.parseResult.value = '未找到视频资源，请切换数据源重试';
    } catch (e) {
      playController.isParsing.value = false;
      playController.parseResult.value = '视频解析失败: ${e.toString()}';
      _logger.e(e);
    }
    return false;
  }

  /// 取消当前视频源解析并销毁 Provider
  void cancelVideoSourceResolution() {
    _videoSourceProvider?.dispose();
    _videoSourceProvider = null;
  }
}

class _AutoLoadCandidate {
  const _AutoLoadCandidate({
    required this.websiteIndex,
    required this.resource,
    required this.episode,
  });

  final int websiteIndex;
  final ResourcesItem resource;
  final Episode episode;
}
