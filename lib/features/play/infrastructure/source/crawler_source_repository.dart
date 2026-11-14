import 'package:anime_flow/features/play/domain/play_source_repository.dart';
import 'package:anime_flow/shared/models/player/play/video/captcha_challenge.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/search_resources_item.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_engine.dart';
import 'package:anime_flow/core/crawler/cookie_manager.dart';
import 'package:anime_flow/core/crawler/captcha_page_url.dart';

class CrawlerSourceRepository implements PlaySourceRepository {
  CrawlerSourceRepository(this.loadConfigs);
  final Future<List<CrawlConfigItem>> Function() loadConfigs;
  final _engine = RuleEngine();
  @override
  Future<List<PlayWebsite>> websites() async =>
      [for (final config in await loadConfigs()) _Website(config, _engine)];
  @override
  bool hasCookies(String name) => CookieManager.instance.hasCookies(name);
  @override
  Future<bool> hasUsableCookies(String name, String url) =>
      CookieManager.instance.hasUsableCookies(name, url);
}

class _Website implements PlayWebsite {
  _Website(this.config, this.engine);
  final CrawlConfigItem config;
  final RuleEngine engine;
  @override
  String get name => config.name;
  @override
  String get baseUrl => config.baseUrl;
  @override
  String get iconUrl => config.iconUrl;
  @override
  String get searchUrl => captchaPageTemplate(config);
  @override
  CaptchaChallenge get antiCrawlerConfig => config.antiCrawlerConfig;
  @override
  Future<List<SearchResourcesItem>> search(String keyword) =>
      engine.search(keyword: keyword, config: config);
  @override
  Future<List<CrawlerEpisodeResourcesItem>> chapters(String link) =>
      engine.fetchEpisodeResources(sourceUrl: link, config: config);
}
