import 'dart:isolate';

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
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class VideoSourceController extends GetxController {
  VideoSourceController(this._container);

  final ProviderContainer _container;

  final RxInt currentEpisodeIndex = 0.obs;
  ProviderSubscription<int>? _episodeIndexSubscription;

  final videoResources = <ResourcesItem>[].obs;
  final webSiteTitle = ''.obs;
  final webSiteIcon = ''.obs;
  final videoUrl = ''.obs;
  final keyword = ''.obs;
  final isLoading = false.obs;

  /// 当前选中的网站索引
  final RxInt selectedWebsiteIndex = 0.obs;
  final RxBool isInitWebView = false.obs;

  final LiggLogger _logger = LiggLogger();

  /// 标记用户是否手动选择了资源
  bool userManuallySelected = false;

  Worker? _isLoadingWorker;

  WebViewVideoSourceProvider? _videoSourceProvider;

  void _listenEpisodeIndex() {
    _episodeIndexSubscription?.close();
    _episodeIndexSubscription = _container.listen<int>(
      episodesProvider.select((state) => state.episodeIndex),
      (_, next) => currentEpisodeIndex.value = next,
      fireImmediately: true,
    );
  }

  @override
  void onInit() async {
    super.onInit();
    _listenEpisodeIndex();
    await initVideoResources();
  }

  @override
  void onClose() {
    _isLoadingWorker?.dispose();
    _episodeIndexSubscription?.close();
    super.onClose();
  }

  //初始化
  Future<void> initVideoResources() async {
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

  /// 搜索结果经权重排序后最多处理的条数，防止过多 HTTP 请求
  static const _maxSearchItems = 5;

  Future<void> _getResources(String keyword, CrawlConfigItem config) async {
    try {
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

      // 在主线程读取 aliases，随后交给 Isolate 做排序
      final aliases =
          _container.read(playExtraProvider).playExtra.subjectAliases;
      final rawSearchList =
          await WebRequest.getSearchSubjectListService(keyword, config);

      // 将 O(n²~n³) 的权重排序移入后台 Isolate，避免阻塞 UI 线程
      final names =
          rawSearchList.map((item) => item.name).toList(growable: false);
      final sortedResult = await Isolate.run(() {
        final service = SearchResultRankService(
          searchTerm: keyword,
          aliases: aliases,
        );
        final scores = service.computeScoresBatch(names);
        final matchRatios = names
            .map((n) => service.computeMatchRatio(n))
            .toList(growable: false);
        final indices = List.generate(names.length, (i) => i, growable: false);
        indices.sort((a, b) {
          final cmp = scores[b].compareTo(scores[a]);
          return cmp != 0 ? cmp : a.compareTo(b);
        });
        return (indices: indices, matchRatios: matchRatios);
      });

      // 仅处理相关度最高的前 N 条，避免对大量低质量结果发起无效请求
      final searchEntries = sortedResult.indices
          .take(_maxSearchItems)
          .map((i) => (
                item: rawSearchList[i],
                matchRatio: sortedResult.matchRatios[i],
              ))
          .toList(growable: false);

      final allEpisodesList = <EpisodeResourcesItem>[];

      for (final entry in searchEntries) {
        final search = entry.item;
        final matchRatio = entry.matchRatio;
        final crawlerEpisodeResources =
            await WebRequest.getResourcesListService(search.link, config);

        for (final crawlerResource in crawlerEpisodeResources) {
          allEpisodesList.add(
            EpisodeResourcesItem(
              lineNames: crawlerResource.lineNames,
              episodes: crawlerResource.episodes,
              subjectsTitle: search.name,
              matchRatio: matchRatio,
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
          (ep) =>
              ep.episodeSort == _container.read(episodesProvider).episodeIndex,
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
      // 用户在自动切换过程中手动选择了数据源，取消自动选择
      if (userManuallySelected) {
        return;
      }

      selectedWebsiteIndex.value = candidate.websiteIndex;
      final candidateUrl = candidate.resource.baseUrl + candidate.episode.like;

      setWebSite(
        title: candidate.resource.websiteName,
        iconUrl: candidate.resource.websiteIcon,
        videoUrl: candidateUrl,
      );

      final loaded = await loadVideoPage(candidateUrl);
      if (!loaded) {
        // 解析失败，但在解析期间用户可能已手动选择，检查后决定是否继续
        if (userManuallySelected) {
          return;
        }
        setWebSite(title: '', iconUrl: '', videoUrl: '');
        continue;
      }
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
    final subject = _container.read(playExtraProvider).playExtra;
    final episodesState = _container.read(episodesProvider);
    final subjectId = subject.subjectId;
    final episodeIndex = episodesState.episodeIndex;
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
        episodeId: episodesState.episodeId,
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
