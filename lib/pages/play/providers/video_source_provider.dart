import 'dart:isolate';

import 'package:anime_flow/crawler/cookie_manager.dart';
import 'package:anime_flow/crawler/html_request.dart';
import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/features/search_result_rank_service.dart';
import 'package:anime_flow/models/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/play/video/resources_item.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/providers/video/providers.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_source_provider.g.dart';

class VideoSourceState {
  const VideoSourceState({
    this.currentEpisodeIndex = 0,
    this.videoResources = const [],
    this.webSiteTitle = '',
    this.webSiteIcon = '',
    this.videoUrl = '',
    this.keyword = '',
    this.isLoading = false,
    this.selectedWebsiteIndex = 0,
    this.isInitWebView = false,
    this.userManuallySelected = false,
  });

  final int currentEpisodeIndex;
  final List<ResourcesItem> videoResources;
  final String webSiteTitle;
  final String webSiteIcon;
  final String videoUrl;
  final String keyword;
  final bool isLoading;
  final int selectedWebsiteIndex;
  final bool isInitWebView;
  final bool userManuallySelected;

  VideoSourceState copyWith({
    int? currentEpisodeIndex,
    List<ResourcesItem>? videoResources,
    String? webSiteTitle,
    String? webSiteIcon,
    String? videoUrl,
    String? keyword,
    bool? isLoading,
    int? selectedWebsiteIndex,
    bool? isInitWebView,
    bool? userManuallySelected,
  }) {
    return VideoSourceState(
      currentEpisodeIndex: currentEpisodeIndex ?? this.currentEpisodeIndex,
      videoResources: videoResources ?? this.videoResources,
      webSiteTitle: webSiteTitle ?? this.webSiteTitle,
      webSiteIcon: webSiteIcon ?? this.webSiteIcon,
      videoUrl: videoUrl ?? this.videoUrl,
      keyword: keyword ?? this.keyword,
      isLoading: isLoading ?? this.isLoading,
      selectedWebsiteIndex: selectedWebsiteIndex ?? this.selectedWebsiteIndex,
      isInitWebView: isInitWebView ?? this.isInitWebView,
      userManuallySelected: userManuallySelected ?? this.userManuallySelected,
    );
  }
}

@Riverpod(
  keepAlive: true,
  dependencies: [Episodes, playExtra, PlayStateNotifier, playSession],
)
class VideoSourceController extends _$VideoSourceController {
  WebViewVideoSourceProvider? _webViewVideoProvider;
  final LiggLogger _logger = LiggLogger();

  static const _maxSearchItems = 5;

  int get currentEpisodeIndex => state.currentEpisodeIndex;
  List<ResourcesItem> get videoResources => state.videoResources;
  String get webSiteTitle => state.webSiteTitle;
  String get webSiteIcon => state.webSiteIcon;
  String get videoUrl => state.videoUrl;
  String get keyword => state.keyword;
  bool get isLoading => state.isLoading;
  int get selectedWebsiteIndex => state.selectedWebsiteIndex;
  bool get isInitWebView => state.isInitWebView;
  bool get userManuallySelected => state.userManuallySelected;

  bool _requiresCaptcha(CrawlConfigItem config) {
    return config.antiCrawlerConfig.enabled &&
        !CookieManager.instance.hasCookies(config.name);
  }

  @override
  VideoSourceState build() {
    ref.onDispose(_dispose);
    final currentEpisodeIndex =
        ref.read(episodesProvider).asData?.value.episodeIndex ?? 0;
    ref.listen<AsyncValue<EpisodesData>>(
      episodesProvider,
      (previous, next) {
        final nextEpisodeIndex = next.asData?.value.episodeIndex ?? 0;
        if (state.currentEpisodeIndex != nextEpisodeIndex) {
          state = state.copyWith(currentEpisodeIndex: nextEpisodeIndex);
        }
      },
    );
    return VideoSourceState(currentEpisodeIndex: currentEpisodeIndex);
  }

  void _dispose() {
    _webViewVideoProvider?.dispose();
    _webViewVideoProvider = null;
  }

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
    }).toList(growable: false);

    state = state.copyWith(videoResources: resources);
  }

  Future<void> initResources(String keyword) async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    _clearAllResources(configs);
    state = state.copyWith(
      keyword: keyword,
      userManuallySelected: false,
      isLoading: false,
      selectedWebsiteIndex: 0,
      webSiteTitle: '',
      webSiteIcon: '',
      videoUrl: '',
    );

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
    state = state.copyWith(isLoading: true);
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

    final clearedResources = state.videoResources.map((resource) {
      final config = configFor(resource.websiteName);
      final anti = config?.antiCrawlerConfig;
      final captchaEnabled = anti?.enabled ?? false;

      return resource.copyWith(
        episodeResources: const [],
        isLoading: false,
        errorMessage: null,
        needsCaptcha: captchaEnabled &&
            !CookieManager.instance.hasCookies(resource.websiteName),
        antiCrawlerConfig: captchaEnabled ? anti : null,
      );
    }).toList(growable: false);

    state = state.copyWith(videoResources: clearedResources);
  }

  void markCaptchaVerified(String websiteName) {
    _updateResourceStatus(
      websiteName,
      needsCaptcha: false,
      isLoading: true,
      errorMessage: null,
    );
  }

  Future<void> retryResources(String websiteName) async {
    final configs = await CrawlConfig.loadAllCrawlConfigs();
    final config = _firstConfigWhere(configs, (c) => c.name == websiteName);
    if (config == null) {
      return;
    }
    await _getResources(state.keyword, config);
  }

  Future<void> _getResources(String keyword, CrawlConfigItem config) async {
    try {
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

      final aliases = ref.read(playExtraProvider).playExtra.subjectAliases;
      final rawSearchList =
          await WebRequest.getSearchSubjectListService(keyword, config);

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
    state = state.copyWith(isLoading: isLoading);
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
    }).toList(growable: false);

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
    if (state.selectedWebsiteIndex != index) {
      state = state.copyWith(selectedWebsiteIndex: index);
    }
  }

  void resetManualSelection() {
    if (state.userManuallySelected) {
      state = state.copyWith(userManuallySelected: false);
    }
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
    List<ResourcesItem> resources,
  ) {
    final candidates = <_AutoLoadCandidate>[];

    for (var websiteIndex = 0;
        websiteIndex < resources.length;
        websiteIndex++) {
      final resource = resources[websiteIndex];
      for (final resourceItem in resource.episodeResources) {
        final episode = _firstEpisodeWhere(
          resourceItem.episodes,
          (ep) => ep.episodeSort == state.currentEpisodeIndex,
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

    state = state.copyWith(
      selectedWebsiteIndex: _findFirstResourceIndex(resources),
    );

    Future.microtask(() {
      _autoLoadFirstResource(resources, force: force);
    });
  }

  Future<void> _autoLoadFirstResource(
    List<ResourcesItem> resources, {
    bool force = false,
  }) async {
    if (state.userManuallySelected) {
      return;
    }
    if (!force && state.webSiteTitle.isNotEmpty) {
      return;
    }

    final candidates = _buildAutoLoadCandidates(resources);
    for (final candidate in candidates) {
      if (state.userManuallySelected) {
        return;
      }

      state = state.copyWith(selectedWebsiteIndex: candidate.websiteIndex);
      final candidateUrl = candidate.resource.baseUrl + candidate.episode.like;

      setWebSite(
        title: candidate.resource.websiteName,
        iconUrl: candidate.resource.websiteIcon,
        videoUrl: candidateUrl,
      );

      final loaded = await loadVideoPage(candidateUrl);
      if (!loaded) {
        if (state.userManuallySelected) {
          return;
        }
        setWebSite(title: '', iconUrl: '', videoUrl: '');
        continue;
      }
      return;
    }
  }

  Future<bool> loadVideoPage(String url) async {
    _webViewVideoProvider?.cancel();

    final playController = ref.read(playSessionProvider);
    ref.read(playStateProvider.notifier).setIsParsing(true);

    _webViewVideoProvider ??= WebViewVideoSourceProvider();

    var offset = 0;
    final subject = ref.read(playExtraProvider).playExtra;
    final episodesState =
        ref.read(episodesProvider).asData?.value ?? const EpisodesData();
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
      ref.read(playStateProvider.notifier).setParseResult('正在解析视频源...');

      final source = await _webViewVideoProvider!
          .resolve(url, useLegacyParser: false, offset: offset);

      ref.read(playStateProvider.notifier).setIsParsing(false);
      ref.read(playStateProvider.notifier).setParseResult('视频解析成功');
      await playController.initPlayState(
        PlayRequest(
          videoUrl: source.url,
          offset: source.offset,
          subjectId: subjectId,
          subjectName: subjectName,
          subjectCover: subjectCover,
          episodeIndex: episodeIndex,
          alias: subjectAlias,
          episodeId: episodesState.episodeId,
        ),
      );
      return true;
    } on VideoSourceTimeoutException {
      ref.read(playStateProvider.notifier).setIsParsing(false);
      ref.read(playStateProvider.notifier).setParseResult('视频解析超时，请重试');
    } on VideoSourceNotFoundException {
      ref.read(playStateProvider.notifier).setIsParsing(false);
      ref.read(playStateProvider.notifier).setParseResult('未找到视频资源，请切换数据源重试');
    } catch (e) {
      ref.read(playStateProvider.notifier).setIsParsing(false);
      ref
          .read(playStateProvider.notifier)
          .setParseResult('视频解析失败: ${e.toString()}');
      _logger.e(e);
    }
    return false;
  }

  /// 取消当前视频源解析并销毁 Provider
}

CrawlConfigItem? _firstConfigWhere(
  List<CrawlConfigItem> configs,
  bool Function(CrawlConfigItem config) test,
) {
  for (final config in configs) {
    if (test(config)) return config;
  }
  return null;
}

Episode? _firstEpisodeWhere(
  List<Episode> episodes,
  bool Function(Episode episode) test,
) {
  for (final episode in episodes) {
    if (test(episode)) return episode;
  }
  return null;
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
