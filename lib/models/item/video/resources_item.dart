import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';

class ResourcesItem {
  final String websiteName;
  final String websiteIcon;
  final VideoConfig videoConfig;
  final List<EpisodeResourcesItem> episodeResources;
  final bool isLoading; // 是否正在解析中
  final String? errorMessage; // 解析失败时的错误信息

  ResourcesItem({
    required this.websiteName,
    required this.websiteIcon,
    required this.episodeResources,
    required this.videoConfig,
    this.isLoading = false,
    this.errorMessage,
  });

  // 创建一个副本并更新指定字段
  ResourcesItem copyWith({
    String? websiteName,
    String? websiteIcon,
    VideoConfig? videoConfig,
    List<EpisodeResourcesItem>? episodeResources,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ResourcesItem(
      websiteName: websiteName ?? this.websiteName,
      websiteIcon: websiteIcon ?? this.websiteIcon,
      videoConfig: videoConfig ?? this.videoConfig,
      episodeResources: episodeResources ?? this.episodeResources,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
