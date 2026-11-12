import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';

class VideoResourceDownloadRouteArgs {
  VideoResourceDownloadRouteArgs({
    required this.subjectName,
    required List<EpisodeData> episodes,
  }) : episodes = List.unmodifiable(episodes);

  final String subjectName;
  final List<EpisodeData> episodes;
}
