import 'package:anime_flow/shared/models/player/play/video/captcha_challenge.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/search_resources_item.dart';

abstract interface class PlayWebsite {
  String get name;
  String get baseUrl;
  String get iconUrl;
  String get searchUrl;
  CaptchaChallenge get antiCrawlerConfig;
  Future<List<SearchResourcesItem>> search(String keyword);
  Future<List<CrawlerEpisodeResourcesItem>> chapters(String link);
}

abstract interface class PlaySourceRepository {
  Future<List<PlayWebsite>> websites();
  bool hasCookies(String name);
  Future<bool> hasUsableCookies(String name, String url);
}
