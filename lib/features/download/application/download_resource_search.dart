import 'package:anime_flow/core/crawler/captcha_page_url.dart';
import 'package:anime_flow/core/crawler/cookie_manager.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_engine.dart';
import 'package:anime_flow/core/video_source/application/chapter_collection_service.dart';
import 'package:anime_flow/core/video_source/application/search_result_rank_service.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// 下载选源会话：仅使用已安装的规则，生命周期与弹窗一致。
class DownloadResourceSearch extends ChangeNotifier {
  DownloadResourceSearch({required this.loadConfigs, RuleEngine? engine})
      : _engine = engine ?? RuleEngine();

  final Future<List<CrawlConfigItem>> Function() loadConfigs;
  final RuleEngine _engine;
  List<CrawlConfigItem> _configs = [];
  List<ResourcesItem> resources = [];
  String keyword = '';
  Object? error;
  bool loading = false;
  bool _disposed = false;
  int _generation = 0;
  final _requests = <String, int>{};
  final _cancellations = <String, CancelToken>{};
  final _siteKeywords = <String, String>{};

  Future<void> search(String value) async {
    if (_disposed || value.trim().isEmpty) return;
    final generation = ++_generation;
    _cancelRequests();
    keyword = value.trim();
    error = null;
    loading = true;
    resources = [];
    _siteKeywords.clear();
    notifyListeners();
    try {
      final configs = await loadConfigs();
      if (!_current(generation)) return;
      _configs = configs;
      resources = [
        for (final config in configs)
          ResourcesItem(
            websiteName: config.name,
            websiteIcon: config.iconUrl,
            baseUrl: config.baseUrl,
            searchUrl: captchaPageTemplate(config),
            episodeResources: const [],
            isLoading: true,
            antiCrawlerConfig: config.antiCrawlerConfig,
          ),
      ];
      loading = false;
      notifyListeners();
      var next = 0;
      Future<void> worker() async {
        while (_current(generation) && next < configs.length) {
          final config = configs[next++];
          await _searchWebsite(config, keyword, generation);
        }
      }

      await Future.wait(
          List.generate(configs.length.clamp(0, 5), (_) => worker()));
    } catch (failure) {
      if (!_current(generation)) return;
      error = failure;
    } finally {
      if (_current(generation)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry(String name, {String? keyword}) async {
    if (_disposed) return;
    for (final config in _configs) {
      if (config.name != name) continue;
      final query = keyword?.trim();
      await _searchWebsite(
          config,
          query != null && query.isNotEmpty
              ? query
              : _siteKeywords[name] ?? this.keyword,
          _generation);
      return;
    }
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> _searchWebsite(
      CrawlConfigItem config, String query, int generation) async {
    if (!_current(generation)) return;
    _cancellations.remove(config.name)?.cancel();
    final cancellation = CancelToken();
    _cancellations[config.name] = cancellation;
    final token = (_requests[config.name] ?? 0) + 1;
    _requests[config.name] = token;
    _siteKeywords[config.name] = query;
    bool current() =>
        _current(generation) &&
        _requests[config.name] == token &&
        !cancellation.isCancelled;
    void update(ResourcesItem Function(ResourcesItem) change) {
      if (!current()) return;
      resources = [
        for (final item in resources)
          if (item.websiteName == config.name) change(item) else item
      ];
      notifyListeners();
    }

    update((item) => item.copyWith(
        isLoading: true,
        needsCaptcha: false,
        searchUrl: renderKeywordUrl(captchaPageTemplate(config), query),
        episodeResources: const [],
        errorMessage: null));
    try {
      final searchUrl = renderKeywordUrl(captchaPageTemplate(config), query);
      if (config.antiCrawlerConfig.enabled &&
          !await CookieManager.instance
              .hasUsableCookies(config.name, searchUrl)) {
        throw CaptchaRequiredException(config.name);
      }
      if (!current()) return;
      final results = await _engine.search(
        keyword: query,
        config: config,
        cancelToken: cancellation,
      );
      if (!current()) return;
      final ranked = await SearchResultRankService(searchTerm: query)
          .rankInIsolate(names: results.map((item) => item.name).toList());
      if (!current()) return;
      final collection = await ChapterCollectionService(
        fetcher: (url) => _engine.fetchEpisodeResources(
          sourceUrl: url,
          config: config,
          cancelToken: cancellation,
        ),
      ).collect(
        candidates: [
          for (final i in ranked.indices.take(5))
            ChapterCandidate(
                name: results[i].name,
                link: results[i].link,
                matchRatio: ranked.matchRatios[i])
        ],
        websiteName: config.name,
        isActive: current,
      );
      if (collection.allFailed) {
        throw ChapterErrorException(config.name, cause: collection.lastError);
      }
      update((item) => item.copyWith(
          isLoading: false, episodeResources: collection.resources));
    } on RuleRequestCancelledException {
      // 关闭、重新搜索和单站重试都属于主动取消，不展示为请求失败。
      return;
    } on CaptchaRequiredException {
      update((item) => item.copyWith(isLoading: false, needsCaptcha: true));
    } on NoResultException {
      update((item) => item.copyWith(isLoading: false));
    } catch (failure) {
      update((item) =>
          item.copyWith(isLoading: false, errorMessage: failure.toString()));
    } finally {
      if (identical(_cancellations[config.name], cancellation)) {
        _cancellations.remove(config.name);
      }
    }
  }

  void _cancelRequests() {
    for (final cancellation in _cancellations.values) {
      cancellation.cancel();
    }
    _cancellations.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cancelRequests();
    super.dispose();
  }
}
