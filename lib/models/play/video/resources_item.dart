import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';

import 'episode_resources_item.dart';

class ResourcesItem {
  final String websiteName;
  final String websiteIcon;
  final String baseUrl;
  final String searchUrl;
  final List<EpisodeResourcesItem> episodeResources;
  final bool isLoading;
  final String? errorMessage;
  final bool needsCaptcha;
  final AntiCrawlerConfig? antiCrawlerConfig;

  ResourcesItem({
    required this.websiteName,
    required this.websiteIcon,
    required this.episodeResources,
    this.errorMessage,
    required this.baseUrl,
    this.searchUrl = '',
    this.isLoading = false,
    this.needsCaptcha = false,
    this.antiCrawlerConfig,
  });

  ResourcesItem copyWith({
    String? websiteName,
    String? websiteIcon,
    String? baseUrl,
    String? searchUrl,
    List<EpisodeResourcesItem>? episodeResources,
    bool? isLoading,
    String? errorMessage,
    bool? needsCaptcha,
    AntiCrawlerConfig? antiCrawlerConfig,
  }) {
    return ResourcesItem(
      websiteName: websiteName ?? this.websiteName,
      websiteIcon: websiteIcon ?? this.websiteIcon,
      episodeResources: episodeResources ?? this.episodeResources,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      baseUrl: baseUrl ?? this.baseUrl,
      searchUrl: searchUrl ?? this.searchUrl,
      needsCaptcha: needsCaptcha ?? this.needsCaptcha,
      antiCrawlerConfig: antiCrawlerConfig ?? this.antiCrawlerConfig,
    );
  }
}
