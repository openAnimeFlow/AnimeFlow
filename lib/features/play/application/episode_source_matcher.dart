import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';

/// 剧集对应和候选排序的统一入口。
class EpisodeSourceMatcher {
  static bool matchesEpisode(Episode episode, int episodeIndex) =>
      episode.episodeSort == episodeIndex;

  static Episode? findEpisode(List<Episode> episodes, int episodeIndex) {
    for (final episode in episodes) {
      if (matchesEpisode(episode, episodeIndex)) return episode;
    }
    return null;
  }

  static List<EpisodeSourceCandidate> buildCandidates(
    List<ResourcesItem> resources, {
    required int episodeIndex,
    String? preferredWebsiteName,
  }) {
    final candidates = <EpisodeSourceCandidate>[];
    for (var websiteIndex = 0;
        websiteIndex < resources.length;
        websiteIndex++) {
      final resource = resources[websiteIndex];
      for (final resourceItem in resource.episodeResources) {
        final episode = findEpisode(resourceItem.episodes, episodeIndex);
        if (episode == null) continue;
        candidates.add(EpisodeSourceCandidate(
          websiteIndex: websiteIndex,
          resource: resource,
          resourceItem: resourceItem,
          episode: episode,
        ));
      }
    }

    candidates.sort((a, b) {
      if (preferredWebsiteName != null && preferredWebsiteName.isNotEmpty) {
        final aPreferred = a.resource.websiteName == preferredWebsiteName;
        final bPreferred = b.resource.websiteName == preferredWebsiteName;
        if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
      }
      final matchRatioCompare =
          b.resourceItem.matchRatio.compareTo(a.resourceItem.matchRatio);
      if (matchRatioCompare != 0) return matchRatioCompare;
      return a.websiteIndex.compareTo(b.websiteIndex);
    });
    return candidates;
  }
}

class EpisodeSourceCandidate {
  const EpisodeSourceCandidate({
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
