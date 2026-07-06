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
    this.isSearchCompleted = false,
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
  final bool isSearchCompleted;
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
    bool? isSearchCompleted,
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
      isSearchCompleted: isSearchCompleted ?? this.isSearchCompleted,
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
class VideoSourceNotifier extends _$VideoSourceNotifier {
  WebViewVideoSourceProvider? _webViewVideoProvider;
  final LiggLogger _logger = LiggLogger();

  static const _maxSearchItems = 5;
  static const _maxConcurrentSearches = 5;

  Future<List<CrawlConfigItem>>? _crawlConfigsFuture;
  int _searchSessionId = 0;
  final Map<String, int> _websiteRequestTokens = {};
  bool _isAutoSelecting = false;
  int _autoSelectEpoch = 0;
  int? _autoSelectEpisodeIndex;
  String? _preferredAutoSelectWebsiteName;
  int _videoPageLoadToken = 0;
  final Set<String> _attemptedAutoLoadUrls = {};

  int get currentEpisodeIndex => state.currentEpisodeIndex;
  List<ResourcesItem> get videoResources => state.videoResources;
  String get webSiteTitle => state.webSiteTitle;
  String get webSiteIcon => state.webSiteIcon;
  String get videoUrl => state.videoUrl;
  String get keyword => state.keyword;
  bool get isSearchCompleted => state.isSearchCompleted;
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
    _crawlConfigsFuture = null;
    _websiteRequestTokens.clear();
    _attemptedAutoLoadUrls.clear();
  }

  Future<void> initVideoResources() async {
    if (state.videoResources.isNotEmpty) {
      return;
    }
    final configs = await _getCrawlConfigs();
    if (state.videoResources.isNotEmpty) {
      return;
    }
    state = state.copyWith(videoResources: _buildInitialResources(configs));
  }

  Future<void> initResources(String keyword) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return;
    }

    final configs = await _getCrawlConfigs();
    final sessionId = ++_searchSessionId;
    _resetAutoSelectionAttempts();
    _ensureVideoResourcesInitialized(configs);
    _clearAllResources(configs);
    state = state.copyWith(
      keyword: normalizedKeyword,
      userManuallySelected: false,
      isSearchCompleted: false,
      selectedWebsiteIndex: 0,
      webSiteTitle: '',
      webSiteIcon: '',
      videoUrl: '',
    );

    final eligibleConfigs = <CrawlConfigItem>[];
    for (final config in configs) {
      if (config.antiCrawlerConfig.enabled) {
        if (CookieManager.instance.hasCookies(config.name)) {
          eligibleConfigs.add(config);
        } else {
          _updateResourceStatus(
            config.name,
            needsCaptcha: true,
            antiCrawlerConfig: config.antiCrawlerConfig,
          );
        }
        continue;
      }

      eligibleConfigs.add(config);
    }

    await _runSearchPool(
      configs: eligibleConfigs,
      keyword: normalizedKeyword,
      sessionId: sessionId,
    );

    if (_searchSessionId != sessionId) {
      return;
    }
    state = state.copyWith(isSearchCompleted: true);
    autoSelectAvailableResource(preferCurrentWebsite: true);
  }

  List<ResourcesItem> _buildInitialResources(List<CrawlConfigItem> configs) {
    return configs.map((config) {
      return ResourcesItem(
        websiteName: config.name,
        websiteIcon: config.iconUrl,
        baseUrl: config.baseUrl,
        searchUrl: config.searchUrl,
        needsCaptcha: _requiresCaptcha(config),
        episodeResources: const [],
      );
    }).toList(growable: false);
  }

  void _ensureVideoResourcesInitialized(List<CrawlConfigItem> configs) {
    if (state.videoResources.isNotEmpty) {
      return;
    }
    state = state.copyWith(videoResources: _buildInitialResources(configs));
  }

  void _clearAllResources(List<CrawlConfigItem> configs) {
    final configsByName = {
      for (final config in configs) config.name: config,
    };

    final clearedResources = state.videoResources.map((resource) {
      final config = configsByName[resource.websiteName];
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
    final configs = await _getCrawlConfigs();
    _ensureVideoResourcesInitialized(configs);
    final config = _firstConfigWhere(configs, (c) => c.name == websiteName);
    if (config == null) {
      return;
    }
    final fallbackKeyword = ref.read(playExtraProvider).playExtra.subjectName;
    final retryKeyword = state.keyword.trim().isNotEmpty
        ? state.keyword.trim()
        : fallbackKeyword.trim();
    if (retryKeyword.isEmpty) {
      return;
    }

    final sessionId = _searchSessionId;
    _updateResourceStatus(
      websiteName,
      isLoading: false,
      episodeResources: const [],
      errorMessage: null,
      needsCaptcha: _requiresCaptcha(config),
      antiCrawlerConfig:
          config.antiCrawlerConfig.enabled ? config.antiCrawlerConfig : null,
    );
    await _getResources(
      retryKeyword,
      config,
      sessionId: sessionId,
      requestToken: _nextWebsiteRequestToken(websiteName),
    );
  }

  Future<void> _getResources(
    String keyword,
    CrawlConfigItem config, {
    required int sessionId,
    required int requestToken,
  }) async {
    try {
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

      final aliases = ref.read(playExtraProvider).playExtra.subjectAliases;
      final rawSearchList =
          await WebRequest.getSearchSubjectListService(keyword, config);
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }

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
        if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
          return;
        }

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

      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }
      _updateResourceStatus(
        config.name,
        isLoading: false,
        episodeResources: allEpisodesList,
        needsCaptcha: false,
      );
      autoSelectAvailableResource(preferCurrentWebsite: true);
    } on CaptchaRequiredException {
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }
      _updateResourceStatus(
        config.name,
        isLoading: false,
        needsCaptcha: true,
        antiCrawlerConfig: config.antiCrawlerConfig,
        errorMessage: null,
      );
    } catch (e) {
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }
      _updateResourceStatus(
        config.name,
        isLoading: false,
        errorMessage: '解析失败: $e',
      );
    }
  }

  void updateSearchCompleted(bool isSearchCompleted) {
    state = state.copyWith(isSearchCompleted: isSearchCompleted);
  }

  Future<List<CrawlConfigItem>> _getCrawlConfigs() async {
    final existingFuture = _crawlConfigsFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = CrawlConfig.loadAllCrawlConfigs();
    _crawlConfigsFuture = future;
    try {
      return await future;
    } catch (_) {
      if (identical(_crawlConfigsFuture, future)) {
        _crawlConfigsFuture = null;
      }
      rethrow;
    }
  }

  Future<void> _runSearchPool({
    required List<CrawlConfigItem> configs,
    required String keyword,
    required int sessionId,
  }) async {
    if (configs.isEmpty) {
      return;
    }

    var nextIndex = 0;
    final workerCount = configs.length < _maxConcurrentSearches
        ? configs.length
        : _maxConcurrentSearches;

    Future<void> worker() async {
      while (true) {
        if (_searchSessionId != sessionId) {
          return;
        }
        final currentIndex = nextIndex++;
        if (currentIndex >= configs.length) {
          return;
        }
        final config = configs[currentIndex];
        await _getResources(
          keyword,
          config,
          sessionId: sessionId,
          requestToken: _nextWebsiteRequestToken(config.name),
        );
      }
    }

    await Future.wait(List.generate(workerCount, (_) => worker()));
  }

  int _nextWebsiteRequestToken(String websiteName) {
    final nextToken = (_websiteRequestTokens[websiteName] ?? 0) + 1;
    _websiteRequestTokens[websiteName] = nextToken;
    return nextToken;
  }

  bool _isRequestCurrent(String websiteName, int sessionId, int requestToken) {
    return _searchSessionId == sessionId &&
        _websiteRequestTokens[websiteName] == requestToken;
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

  List<_AutoLoadCandidate> _buildAutoLoadCandidates(
    List<ResourcesItem> resources, {
    String? preferredWebsiteName,
  }) {
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
            resourceItem: resourceItem,
            episode: episode,
          ),
        );
      }
    }

    candidates.sort((a, b) {
      if (preferredWebsiteName != null && preferredWebsiteName.isNotEmpty) {
        final aPreferred = a.resource.websiteName == preferredWebsiteName;
        final bPreferred = b.resource.websiteName == preferredWebsiteName;
        if (aPreferred != bPreferred) {
          return aPreferred ? -1 : 1;
        }
      }
      final matchRatioCompare =
          b.resourceItem.matchRatio.compareTo(a.resourceItem.matchRatio);
      if (matchRatioCompare != 0) {
        return matchRatioCompare;
      }
      return a.websiteIndex.compareTo(b.websiteIndex);
    });

    return candidates;
  }

  void autoSelectFirstResource(
    List<ResourcesItem> resources, {
    bool force = false,
  }) {
    autoSelectAvailableResource(force: force, preferCurrentWebsite: true);
  }

  void autoSelectAvailableResource({
    bool force = false,
    bool preferCurrentWebsite = false,
  }) {
    if (state.userManuallySelected) {
      return;
    }
    if (!force && state.webSiteTitle.isNotEmpty) {
      return;
    }
    if (_isAutoSelecting) {
      return;
    }

    Future.microtask(() {
      final preferredWebsiteName = state.webSiteTitle.isNotEmpty
          ? state.webSiteTitle
          : _preferredAutoSelectWebsiteName;
      _autoLoadAvailableResource(
        force: force,
        preferredWebsiteName:
            preferCurrentWebsite ? preferredWebsiteName : null,
      );
    });
  }

  void _resetAutoSelectionAttempts() {
    _autoSelectEpoch++;
    _isAutoSelecting = false;
    _autoSelectEpisodeIndex = state.currentEpisodeIndex;
    _preferredAutoSelectWebsiteName = null;
    _attemptedAutoLoadUrls.clear();
  }

  void resetAutoSelectionForCurrentEpisode() {
    final preferredWebsiteName =
        state.webSiteTitle.isNotEmpty ? state.webSiteTitle : null;
    _resetAutoSelectionAttempts();
    _preferredAutoSelectWebsiteName = preferredWebsiteName;
    state = state.copyWith(webSiteTitle: '', webSiteIcon: '', videoUrl: '');
  }

  void _syncAutoSelectionEpisode() {
    if (_autoSelectEpisodeIndex == state.currentEpisodeIndex) {
      return;
    }
    _autoSelectEpoch++;
    _autoSelectEpisodeIndex = state.currentEpisodeIndex;
    _attemptedAutoLoadUrls.clear();
  }

  Future<void> _autoLoadAvailableResource({
    bool force = false,
    String? preferredWebsiteName,
  }) async {
    if (state.userManuallySelected) {
      return;
    }
    if (!force && state.webSiteTitle.isNotEmpty) {
      return;
    }
    if (_isAutoSelecting) {
      return;
    }

    _syncAutoSelectionEpisode();
    final epoch = _autoSelectEpoch;
    _isAutoSelecting = true;

    try {
      while (true) {
        if (epoch != _autoSelectEpoch || state.userManuallySelected) {
          return;
        }
        if (!force && state.webSiteTitle.isNotEmpty) {
          return;
        }

        final candidates = _buildAutoLoadCandidates(
          state.videoResources,
          preferredWebsiteName: preferredWebsiteName,
        ).where((candidate) {
          final url = candidate.resource.baseUrl + candidate.episode.like;
          return !_attemptedAutoLoadUrls.contains(url);
        }).toList(growable: false);

        if (candidates.isEmpty) {
          return;
        }

        final candidate = candidates.first;
        final candidateUrl =
            candidate.resource.baseUrl + candidate.episode.like;
        _attemptedAutoLoadUrls.add(candidateUrl);

        state = state.copyWith(selectedWebsiteIndex: candidate.websiteIndex);
        setWebSite(
          title: candidate.resource.websiteName,
          iconUrl: candidate.resource.websiteIcon,
          videoUrl: candidateUrl,
        );

        final loaded = await loadVideoPage(
          candidateUrl,
          shouldUseResult: () => epoch == _autoSelectEpoch,
        );
        if (loaded) {
          _preferredAutoSelectWebsiteName = null;
          return;
        }

        if (epoch != _autoSelectEpoch || state.userManuallySelected) {
          return;
        }
        setWebSite(title: '', iconUrl: '', videoUrl: '');
      }
    } finally {
      if (epoch == _autoSelectEpoch) {
        _isAutoSelecting = false;
      }
    }
  }

  Future<bool> loadVideoPage(
    String url, {
    bool Function()? shouldUseResult,
  }) async {
    if (shouldUseResult != null && !shouldUseResult()) {
      return false;
    }
    final loadToken = ++_videoPageLoadToken;
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
      final canUseResult = loadToken == _videoPageLoadToken &&
          (shouldUseResult == null || shouldUseResult());
      if (!canUseResult) {
        if (loadToken == _videoPageLoadToken) {
          ref.read(playStateProvider.notifier).setIsParsing(false);
        }
        return false;
      }

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
      if (loadToken == _videoPageLoadToken) {
        ref.read(playStateProvider.notifier).setIsParsing(false);
        ref.read(playStateProvider.notifier).setParseResult('视频解析超时，请重试');
      }
    } on VideoSourceNotFoundException {
      if (loadToken == _videoPageLoadToken) {
        ref.read(playStateProvider.notifier).setIsParsing(false);
        ref.read(playStateProvider.notifier).setParseResult('未找到视频资源，请切换数据源重试');
      }
    } catch (e) {
      if (loadToken == _videoPageLoadToken) {
        ref.read(playStateProvider.notifier).setIsParsing(false);
        ref
            .read(playStateProvider.notifier)
            .setParseResult('视频解析失败: ${e.toString()}');
        _logger.e(e);
      }
    }
    return false;
  }
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
    required this.resourceItem,
    required this.episode,
  });

  final int websiteIndex;
  final ResourcesItem resource;
  final EpisodeResourcesItem resourceItem;
  final Episode episode;
}
