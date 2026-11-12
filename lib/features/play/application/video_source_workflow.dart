import 'package:anime_flow/features/play/domain/play_request.dart';
import 'package:anime_flow/core/utils/source_url.dart' show resolveSourceUrl;
import 'package:anime_flow/features/play/application/search_result_rank_service.dart';
import 'package:anime_flow/features/play/application/chapter_collection_service.dart';
import 'package:anime_flow/core/video_source/domain/episode_source_matcher.dart';
import 'package:anime_flow/core/video_source/domain/selected_video_source.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/core/video_source/domain/video_source.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';
import 'package:anime_flow/core/logger/app_log.dart';

import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/application/video_source_state.dart';
import 'package:anime_flow/features/play/domain/play_source_repository.dart';
import 'package:anime_flow/shared/models/player/play/video/captcha_challenge.dart';
import 'package:anime_flow/core/crawler/rule_exceptions.dart';

typedef SourceSubject = ({
  int subjectId,
  String subjectName,
  String subjectCover,
  List<String> subjectAliases
});
typedef SourceEpisode = ({int index, int sort, int id});

mixin VideoSourceWorkflow {
  VideoSourceState get state;
  set state(VideoSourceState value);
  bool get active;
  SourceSubject get subject;
  SourceEpisode get episode;
  PlaySourceRepository get sourceRepository;
  PlayHistoryService get history;
  IVideoSourceProvider get resolver;
  Future<void> Function(PlayRequest request) get openPlayback;
  void setPlaybackPhase(PlaybackPhase phase, {String? message});

  static const _maxSearchItems = 5;
  static const _maxConcurrentSearches = 5;

  int _searchSessionId = 0;
  final Map<String, int> _websiteRequestTokens = {};
  bool _isAutoSelecting = false;
  int _autoSelectEpoch = 0;
  int? _autoSelectEpisodeIndex;
  String? _preferredAutoSelectWebsiteName;
  int _videoPageLoadToken = 0;
  VideoSourceCancellation? _resolution;
  final Set<String> _attemptedAutoLoadUrls = {};

  bool _requiresCaptcha(PlayWebsite config) {
    return config.antiCrawlerConfig.enabled &&
        !sourceRepository.hasCookies(config.name);
  }

  void disposeSearch() {
    _resolution?.cancel();
    _resolution = null;
    _searchSessionId++;
    _videoPageLoadToken++;
    _websiteRequestTokens.clear();
    _attemptedAutoLoadUrls.clear();
  }

  Future<void> initVideoResources() async {
    final configs = await _loadSources();
    if (!active) return;
    _syncVideoResources(configs);
  }

  void setManualSearchDraft(String value) {
    if (state.manualSearchDraft == value) return;
    state = state.copyWith(manualSearchDraft: value);
  }

  Future<void> initResources(
    String keyword, {
    bool preserveCurrentPlayback = false,
  }) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return;
    }

    final configs = await _loadSources();
    if (!active) return;
    final sessionId = ++_searchSessionId;
    _resetAutoSelectionAttempts();
    _syncVideoResources(configs);
    _clearAllResources(configs);
    state = state.copyWith(
      keyword: normalizedKeyword,
      userManuallySelected:
          preserveCurrentPlayback ? state.userManuallySelected : false,
      isSearchCompleted: false,
      selectedWebsiteIndex: 0,
      selectedSource: preserveCurrentPlayback ? state.selectedSource : null,
    );

    final eligibleConfigs = <PlayWebsite>[];
    for (final config in configs) {
      if (config.antiCrawlerConfig.enabled) {
        if (sourceRepository.hasCookies(config.name)) {
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

    if (!active) return;
    if (_searchSessionId != sessionId) {
      return;
    }
    state = state.copyWith(isSearchCompleted: true);
    autoSelectAvailableResource(preferCurrentWebsite: true);
  }

  void _syncVideoResources(List<PlayWebsite> configs) {
    final previousResources = {
      for (final resource in state.videoResources)
        resource.websiteName: resource,
    };
    final selectedWebsiteName = state.selectedWebsiteIndex >= 0 &&
            state.selectedWebsiteIndex < state.videoResources.length
        ? state.videoResources[state.selectedWebsiteIndex].websiteName
        : null;

    final syncedResources = configs.map((config) {
      final previous = previousResources[config.name];
      if (previous == null) {
        return ResourcesItem(
          websiteName: config.name,
          websiteIcon: config.iconUrl,
          baseUrl: config.baseUrl,
          searchUrl: config.searchUrl,
          needsCaptcha: _requiresCaptcha(config),
          episodeResources: const [],
        );
      }

      return previous.copyWith(
        websiteIcon: config.iconUrl,
        baseUrl: config.baseUrl,
        searchUrl: config.searchUrl,
        needsCaptcha:
            config.antiCrawlerConfig.enabled ? previous.needsCaptcha : false,
        antiCrawlerConfig:
            config.antiCrawlerConfig.enabled ? config.antiCrawlerConfig : null,
      );
    }).toList(growable: false);
    final selectedIndex = selectedWebsiteName == null
        ? 0
        : syncedResources.indexWhere(
            (resource) => resource.websiteName == selectedWebsiteName,
          );

    state = state.copyWith(
      videoResources: syncedResources,
      selectedWebsiteIndex: selectedIndex < 0 ? 0 : selectedIndex,
    );
  }

  void _clearAllResources(List<PlayWebsite> configs) {
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
            !sourceRepository.hasCookies(resource.websiteName),
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

  Future<void> retryResources(
    String websiteName, {
    String? keyword,
  }) async {
    final configs = await _loadSources();
    if (!active) return;
    _syncVideoResources(configs);
    final config = _firstConfigWhere(configs, (c) => c.name == websiteName);
    if (config == null) {
      return;
    }
    final fallbackKeyword = subject.subjectName;
    final customKeyword = keyword?.trim() ?? '';
    final retryKeyword = customKeyword.isNotEmpty
        ? customKeyword
        : state.keyword.trim().isNotEmpty
            ? state.keyword.trim()
            : fallbackKeyword.trim();
    if (retryKeyword.isEmpty) {
      return;
    }

    final searchUrl = renderKeywordUrl(config.searchUrl, retryKeyword);
    final requiresCaptcha = config.antiCrawlerConfig.enabled &&
        !await sourceRepository.hasUsableCookies(config.name, searchUrl);
    if (!active) return;
    if (requiresCaptcha) {
      _updateResourceStatus(
        websiteName,
        isLoading: false,
        episodeResources: const [],
        errorMessage: null,
        needsCaptcha: true,
        antiCrawlerConfig: config.antiCrawlerConfig,
      );
      return;
    }

    final sessionId = _searchSessionId;
    _updateResourceStatus(
      websiteName,
      isLoading: false,
      episodeResources: const [],
      errorMessage: null,
      needsCaptcha: false,
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
    PlayWebsite config, {
    required int sessionId,
    required int requestToken,
  }) async {
    if (!active) return;
    try {
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }
      _updateResourceStatus(config.name, isLoading: true, errorMessage: null);

      final aliases = subject.subjectAliases;
      final rawSearchList = await config.search(keyword);
      if (!active) return;
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }

      final names =
          rawSearchList.map((item) => item.name).toList(growable: false);
      final rankService = SearchResultRankService(
        searchTerm: keyword,
        aliases: aliases,
      );
      final sortedResult = await rankService.rankInIsolate(names: names);
      if (!active) return;

      final searchEntries = sortedResult.indices
          .take(_maxSearchItems)
          .map((i) => (
                item: rawSearchList[i],
                matchRatio: sortedResult.matchRatios[i],
              ))
          .toList(growable: false);

      final collection =
          await ChapterCollectionService(fetcher: config.chapters).collect(
        candidates: [
          for (final entry in searchEntries)
            ChapterCandidate(
              name: entry.item.name,
              link: entry.item.link,
              matchRatio: entry.matchRatio,
            ),
        ],
        websiteName: config.name,
        isActive: () =>
            active && _isRequestCurrent(config.name, sessionId, requestToken),
      );

      if (!active) return;
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }

      // 只有全部候选都失败才报错；个别条目失败不影响已拿到的来源。
      if (collection.allFailed) {
        final cause = collection.lastError;
        if (cause is ChapterErrorException) throw cause;
        throw ChapterErrorException(config.name, cause: cause);
      }

      _updateResourceStatus(
        config.name,
        isLoading: false,
        episodeResources: collection.resources,
        needsCaptcha: false,
      );
      autoSelectAvailableResource(preferCurrentWebsite: true);
    } on CaptchaRequiredException {
      if (!active) return;
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
    } on NoResultException {
      // 解析成功但没有匹配结果：保持空列表，由列表页展示「无结果」状态。
      if (!active) return;
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }
      _updateResourceStatus(
        config.name,
        isLoading: false,
        episodeResources: const [],
        needsCaptcha: false,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      if (!active) return;
      if (!_isRequestCurrent(config.name, sessionId, requestToken)) {
        return;
      }
      // 失败不只写进抽屉状态：同时落到错误日志，避免关掉界面后无从排查。
      logError(
        'VideoSource: ${config.name} 解析失败',
        error: e,
        stackTrace: stackTrace,
      );
      _updateResourceStatus(
        config.name,
        isLoading: false,
        errorMessage: '解析失败: $e',
      );
    }
  }

  Future<List<PlayWebsite>> _loadSources() {
    return sourceRepository.websites();
  }

  Future<void> _runSearchPool({
    required List<PlayWebsite> configs,
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
    CaptchaChallenge? antiCrawlerConfig,
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

  void _selectSource(SelectedVideoSource? source) {
    state = state.copyWith(selectedSource: source);
  }

  void bindManualSourceForCurrentEpisode({
    required String websiteName,
    required String websiteIcon,
    required String resourceTitle,
    required String lineName,
    required String videoUrl,
  }) {
    final source = SelectedVideoSource(
      websiteName: websiteName,
      websiteIcon: websiteIcon,
      resourceTitle: resourceTitle,
      lineName: lineName,
      videoUrl: videoUrl,
    );
    final episodeId = _currentEpisodeId;
    state = state.copyWith(
      selectedSource: source,
      userManuallySelected: true,
      manualEpisodeSources: episodeId > 0
          ? {...state.manualEpisodeSources, episodeId: source}
          : state.manualEpisodeSources,
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

  int get _currentEpisodeIndex => episode.index;

  int get _currentEpisodeId => episode.id;

  SelectedVideoSource? _manualSourceForCurrentEpisode() {
    final episodeId = _currentEpisodeId;
    if (episodeId <= 0) {
      return null;
    }
    return state.manualEpisodeSources[episodeId];
  }

  Future<bool> _loadManualSourceForCurrentEpisode() async {
    if (!active) return false;
    final manualSource = _manualSourceForCurrentEpisode();
    if (manualSource == null) {
      return false;
    }

    _selectSource(manualSource);
    return loadVideoPage(manualSource.videoUrl);
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
      if (!active) return;
      final manualSource = _manualSourceForCurrentEpisode();
      if (manualSource != null) {
        _loadManualSourceForCurrentEpisode();
        return;
      }
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
    _autoSelectEpisodeIndex = _currentEpisodeIndex;
    _preferredAutoSelectWebsiteName = null;
    _attemptedAutoLoadUrls.clear();
  }

  void resetAutoSelectionForCurrentEpisode() {
    final preferredWebsiteName =
        state.webSiteTitle.isNotEmpty ? state.webSiteTitle : null;
    _resetAutoSelectionAttempts();
    _preferredAutoSelectWebsiteName = preferredWebsiteName;
    _selectSource(null);
  }

  void _syncAutoSelectionEpisode() {
    if (_autoSelectEpisodeIndex == _currentEpisodeIndex) {
      return;
    }
    _autoSelectEpoch++;
    _autoSelectEpisodeIndex = _currentEpisodeIndex;
    _attemptedAutoLoadUrls.clear();
  }

  Future<void> _autoLoadAvailableResource({
    bool force = false,
    String? preferredWebsiteName,
  }) async {
    if (!active) return;
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

        final candidates = EpisodeSourceMatcher.buildCandidates(
          state.videoResources,
          episodeIndex: _currentEpisodeIndex,
          preferredWebsiteName: preferredWebsiteName,
        ).where((candidate) {
          final url = resolveSourceUrl(
              candidate.resource.baseUrl, candidate.episode.like);
          return !_attemptedAutoLoadUrls.contains(url);
        }).toList(growable: false);

        if (candidates.isEmpty) {
          return;
        }

        final candidate = candidates.first;
        final candidateUrl = resolveSourceUrl(
            candidate.resource.baseUrl, candidate.episode.like);
        _attemptedAutoLoadUrls.add(candidateUrl);

        state = state.copyWith(
          selectedWebsiteIndex: candidate.websiteIndex,
          selectedSource: SelectedVideoSource(
            websiteName: candidate.resource.websiteName,
            websiteIcon: candidate.resource.websiteIcon,
            resourceTitle: candidate.resourceItem.subjectsTitle,
            lineName: candidate.resourceItem.lineNames,
            videoUrl: candidateUrl,
          ),
        );

        final loaded = await loadVideoPage(
          candidateUrl,
          shouldUseResult: () => epoch == _autoSelectEpoch,
        );
        if (!active) return;
        if (loaded) {
          _preferredAutoSelectWebsiteName = null;
          return;
        }

        if (epoch != _autoSelectEpoch || state.userManuallySelected) {
          return;
        }
        _selectSource(null);
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
    if (!active) return false;
    final loadToken = ++_videoPageLoadToken;
    _resolution?.cancel();
    final cancellation = _resolution = VideoSourceCancellation();
    final webViewVideoProvider = resolver;

    final startPlayback = openPlayback;
    setPlaybackPhase(
      PlaybackPhase.resolving,
      message: '正在解析视频源...',
    );

    if (!active || loadToken != _videoPageLoadToken) return false;

    final (
      subjectId: subjectId,
      subjectName: subjectName,
      subjectCover: subjectCover,
      subjectAliases: subjectAlias
    ) = subject;
    final (index: episodeIndex, sort: episodeSort, id: episodeId) = episode;
    try {
      final offset = await history.resumePosition(subjectId, episodeId);
      if (!active || loadToken != _videoPageLoadToken) return false;
      final source = await webViewVideoProvider.resolve(
          VideoSourceResolveRequest(
              episodeUrl: url,
              offset: offset,
              cancellation: cancellation,
              timeout: const Duration(seconds: 15)));
      if (!active) return false;
      final canUseResult = loadToken == _videoPageLoadToken &&
          (shouldUseResult == null || shouldUseResult());
      if (!canUseResult) {
        if (loadToken == _videoPageLoadToken) {
          setPlaybackPhase(
            PlaybackPhase.idle,
          );
        }
        return false;
      }

      setPlaybackPhase(
        PlaybackPhase.resolved,
        message: '资源解析成功，准备播放',
      );
      await startPlayback(
        PlayRequest(
          videoUrl: source.url,
          offset: source.offset,
          subjectId: subjectId,
          subjectName: subjectName,
          subjectCover: subjectCover,
          episodeIndex: episodeIndex,
          episodeSort: episodeSort,
          alias: subjectAlias,
          episodeId: episodeId,
        ),
      );
      if (!active) return false;
      return true;
    } on VideoSourceTimeoutException {
      if (!active) return false;
      if (loadToken == _videoPageLoadToken) {
        setPlaybackPhase(
          PlaybackPhase.error,
          message: '视频解析超时，请重试',
        );
      }
    } on VideoSourceNotFoundException {
      if (!active) return false;
      if (loadToken == _videoPageLoadToken) {
        setPlaybackPhase(
          PlaybackPhase.error,
          message: '未找到视频资源，请切换数据源重试',
        );
      }
    } catch (e) {
      if (!active) return false;
      if (loadToken == _videoPageLoadToken) {
        setPlaybackPhase(
          PlaybackPhase.error,
          message: '视频解析失败: ${e.toString()}',
        );
        logError(e);
      }
    }
    return false;
  }
}

PlayWebsite? _firstConfigWhere(
  List<PlayWebsite> configs,
  bool Function(PlayWebsite config) test,
) {
  for (final config in configs) {
    if (test(config)) return config;
  }
  return null;
}
