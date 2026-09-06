import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';

/// 播放页传给 [PlayPage] 的参数集。
class PlayRouteExtra {
  final PlayExtra playExtra;
  final int? continueEpisodeId;
  final bool isOfflineMode;
  final String? offlineMediaPath;
  final String? offlineDanmakuPath;
  final String? offlineEpisodeUrl;
  final List<DownloadEpisode> offlineEpisodes;
  final SubjectsInfoItem? subjectInfo;

  const PlayRouteExtra({
    required this.playExtra,
    this.continueEpisodeId,
    this.isOfflineMode = false,
    this.offlineMediaPath,
    this.offlineDanmakuPath,
    this.offlineEpisodeUrl,
    this.offlineEpisodes = const [],
    this.subjectInfo,
  });
}

class PlayExtra {
  final int subjectId;
  final String subjectName;
  final String subjectCover;
  final List<String> subjectAliases;

  const PlayExtra({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCover,
    required this.subjectAliases,
  });
}
