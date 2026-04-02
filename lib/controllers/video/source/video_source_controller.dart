import 'dart:async';

import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/crawler/html_request.dart';
import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/models/item/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/play/video/resources_item.dart';
import 'package:anime_flow/providers/video/webview_video_source_provider.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_source_controller.g.dart';

/// 播放页数据源与解析状态（原 GetX 控制器字段，现合并为不可变状态）。
class VideoSourceState {
  const VideoSourceState({
    this.videoResources = const [],
    this.webSiteTitle = '',
    this.webSiteIcon = '',
    this.videoUrl = '',
    this.keyword = '',
    this.isLoading = false,
    this.selectedWebsiteIndex = 0,
    this.userManuallySelected = false,
  });

  final List<ResourcesItem> videoResources;
  final String webSiteTitle;
  final String webSiteIcon;

  /// 当前选中的剧集页 URL（非真实流媒体地址；真实地址在 [PlayState.videoUrl]）。
  final String videoUrl;
  final String keyword;

  /// `true` 表示各站点资源列表已拉取完毕（沿用原字段名，勿与「正在请求」字面混淆）。
  final bool isLoading;
  final int selectedWebsiteIndex;
  final bool userManuallySelected;

  VideoSourceState copyWith({
    List<ResourcesItem>? videoResources,
    String? webSiteTitle,
    String? webSiteIcon,
    String? videoUrl,
    String? keyword,
    bool? isLoading,
    int? selectedWebsiteIndex,
    bool? userManuallySelected,
  }) {
    return VideoSourceState(
      videoResources: videoResources ?? this.videoResources,
      webSiteTitle: webSiteTitle ?? this.webSiteTitle,
      webSiteIcon: webSiteIcon ?? this.webSiteIcon,
      videoUrl: videoUrl ?? this.videoUrl,
      keyword: keyword ?? this.keyword,
      isLoading: isLoading ?? this.isLoading,
      selectedWebsiteIndex: selectedWebsiteIndex ?? this.selectedWebsiteIndex,
      userManuallySelected: userManuallySelected ?? this.userManuallySelected,
    );
  }
}

/// 数据源爬取、选源与 WebView 解析；依赖 [EpisodesState]、[PlaySubjectState]（仍为 GetX，在播放页注册）。
@riverpod
class VideoSourceController extends _$VideoSourceController {
  final Logger _logger = Logger();
  WebViewVideoSourceProvider? _videoSourceProvider;
  StreamSubscription<String>? _logSubscription;
  final StreamController<String> _logStreamController =
      StreamController<String>.broadcast();

  EpisodesState get _episodesState => Get.find<EpisodesState>();
  PlaySubjectState get _subjectState => Get.find<PlaySubjectState>();

  @override
  VideoSourceState build() {
    ref.onDispose(() {
      cancelVideoSource();
      if (!_logStreamController.isClosed) {
        _logStreamController.close();
      }
    });
    Future.microtask(_initVideoResources);
    return const VideoSourceState();
  }

  /// 页面退出时释放解析用 WebView，Notifier 仍可能存活至路由卸载。
  void cancelVideoSource() {
    _logSubscription?.cancel();
    _logSubscription = null;
    _videoSourceProvider?.dispose();
    _videoSourceProvider = null;
    _logger.i('清理完毕播放资源');
  }

  Future<void> _initVideoResources() async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    final resources = configs
        .map(
          (config) => ResourcesItem(
            websiteName: config.name,
            websiteIcon: config.iconUrl,
            baseUrl: config.baseUrl,
            searchUrl: config.searchUrl,
            needsCaptcha: config.antiCrawlerConfig.enabled,
            episodeResources: [],
          ),
        )
        .toList();
    state = state.copyWith(videoResources: resources);
  }

  //初始化资源
  Future<void> initResources(String keyword) async {
    _clearAllResources();
    state = state.copyWith(
      keyword: keyword,
      userManuallySelected: false,
      isLoading: false,
    );
    final configs = await CrawlConfig.loadAllCrawlConfigs();

    final futures = <Future<void>>[];
    for (var i = 0; i < configs.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      futures.add(_getResources(keyword, configs[i]));
    }
    await Future.wait(futures);
    state = state.copyWith(isLoading: true);
  }

  void _clearAllResources() {
    final clearedResources = state.videoResources
        .map(
          (resource) => ResourcesItem(
            websiteName: resource.websiteName,
            websiteIcon: resource.websiteIcon,
            baseUrl: resource.baseUrl,
            searchUrl: resource.searchUrl,
            episodeResources: [],
            isLoading: false,
            errorMessage: null,
            needsCaptcha: false,
          ),
        )
        .toList();

    state = state.copyWith(videoResources: clearedResources);
  }

  /// 重新请求指定站点的资源
  Future<void> retryResources(String websiteName,{required String keyword}) async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    CrawlConfigItem? config;
    for (final c in configs) {
      if (c.name == websiteName) {
        config = c;
        break;
      }
    }
    if (config == null) return;
    await _getResources(keyword, config);
  }

  Future<void> _getResources(String keyword, CrawlConfigItem config) async {
    try {
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

      final searchList =
          await WebRequest.getSearchSubjectListService(keyword, config);
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

  void _updateResourceStatus(
    String websiteName, {
    bool? isLoading,
    List<EpisodeResourcesItem>? episodeResources,
    String? errorMessage,
    bool? needsCaptcha,
    AntiCrawlerConfig? antiCrawlerConfig,
  }) {
    final updatedResources = state.videoResources.map((resource) {
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

    state = state.copyWith(videoResources: updatedResources);
  }

  void setWebSite({
    required String title,
    required String iconUrl,
    required String videoUrl,
    bool isManual = false,
  }) {
    state = state.copyWith(
      webSiteTitle: title,
      webSiteIcon: iconUrl,
      videoUrl: videoUrl,
      userManuallySelected: isManual ? true : state.userManuallySelected,
    );
  }

  void setSelectedWebsiteIndex(int index) {
    state = state.copyWith(selectedWebsiteIndex: index);
  }

  void setUserManuallySelected(bool value) {
    state = state.copyWith(userManuallySelected: value);
  }

  int _findFirstResourceIndex(List<ResourcesItem> dataSource) {
    for (var i = 0; i < dataSource.length; i++) {
      if (dataSource[i].episodeResources.isNotEmpty) {
        return i;
      }
    }
    return 0;
  }

  void autoSelectFirstResource(
    List<ResourcesItem> resources, {
    bool force = false,
  }) {
    if (state.userManuallySelected) {
      return;
    }
    if (!force && state.webSiteTitle.isNotEmpty) {
      return;
    }
    final hasResource = resources.any((r) => r.episodeResources.isNotEmpty);
    if (!hasResource) {
      return;
    }

    final firstResourceIndex = _findFirstResourceIndex(resources);
    final selectedResource = resources[firstResourceIndex];

    if (selectedResource.episodeResources.isEmpty) {
      return;
    }

    Future<void>.microtask(() {
      _autoLoadFirstResource(selectedResource, force: force);
    });
  }

  Future<void> _autoLoadFirstResource(
    ResourcesItem resource, {
    bool force = false,
  }) async {
    if (state.userManuallySelected) {
      return;
    }
    if (!force && state.webSiteTitle.isNotEmpty) {
      return;
    }

    final episodeIndex = _episodesState.episodeIndex.value;
    for (final resourceItem in resource.episodeResources) {
      final matchingEpisodes = resourceItem.episodes.where(
        (ep) => ep.episodeSort == episodeIndex,
      );
      if (matchingEpisodes.isNotEmpty) {
        final currentEpisode = matchingEpisodes.first;
        setWebSite(
          title: resource.websiteName,
          iconUrl: resource.websiteIcon,
          videoUrl: resource.baseUrl + currentEpisode.like,
        );
        await loadVideoPage(resource.baseUrl + currentEpisode.like);
        return;
      }
    }
  }

  Future<void> loadVideoPage(String url) async {
    _videoSourceProvider?.cancel();
    _videoSourceProvider ??= WebViewVideoSourceProvider();

    await _logSubscription?.cancel();
    _logSubscription = _videoSourceProvider!.onLog.listen((log) {
      if (!_logStreamController.isClosed) {
        _logStreamController.add(log);
      }
    });
    var offset = 0;
    final subjectId = _subjectState.subject.value.id;
    final episodeIndex = _episodesState.episodeIndex.value;
    final position = await PlayRepository.getPlayHistory(subjectId);
    if (position != null &&
        position.position > 0 &&
        position.episodeSort == episodeIndex) {
      offset = position.position;
    }
    try {
      final source = await _videoSourceProvider!.resolve(
        url,
        useLegacyParser: true,
        offset: offset,
      );

      await ref.read(playController.notifier).init(
            PlayInitParams(videoRrl: source.url, offset: source.offset),
          );
    } catch (e) {
      _logger.e('加载视频页面失败', error: e);
    }
  }
}

/// 与 [PlayController] 一致：便于 `ref.watch(videoSourceController)`。
final videoSourceController = videoSourceControllerProvider;
