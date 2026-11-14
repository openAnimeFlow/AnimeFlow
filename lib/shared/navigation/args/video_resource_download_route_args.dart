import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';

class VideoResourceDownloadRouteArgs {
  VideoResourceDownloadRouteArgs({
    required this.subjectName,
    required this.subjectCover,
    required List<EpisodeData> episodes,
  }) : episodes = List.unmodifiable(episodes);

  final String subjectName;
  final String subjectCover;
  final List<EpisodeData> episodes;
}
