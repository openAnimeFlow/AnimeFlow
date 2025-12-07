import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';

class ResourcesItem {
  final String websiteName;
  final String websiteIcon;
  final VideoConfig videoConfig;
  final List<EpisodeResourcesItem> episodeResources;

  ResourcesItem({
    required this.websiteName,
    required this.websiteIcon,
    required this.episodeResources,
    required this.videoConfig,
  });
}
