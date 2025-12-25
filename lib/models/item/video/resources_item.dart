import 'package:anime_flow/models/item/video/episode_resources_item.dart';

class ResourcesItem {
  final String websiteName;
  final String websiteIcon;
  final String baseUrl;
  final List<EpisodeResourcesItem> episodeResources;
  final bool isLoading; // 是否正在解析中
  final String? errorMessage; // 解析失败时的错误信息

  ResourcesItem({
    required this.websiteName,
    required this.websiteIcon,
    required this.episodeResources,
    this.errorMessage,
    required this.baseUrl,
    this.isLoading = false,
  });

  // 创建一个副本并更新指定字段
  ResourcesItem copyWith({
    String? websiteName,
    String? websiteIcon,
    String? baseUrl,
    List<EpisodeResourcesItem>? episodeResources,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ResourcesItem(
      websiteName: websiteName ?? this.websiteName,
      websiteIcon: websiteIcon ?? this.websiteIcon,
      episodeResources: episodeResources ?? this.episodeResources,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}
