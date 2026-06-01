/// 播放页传给 [PlayPage] 的参数集。
class PlayRouteExtra {
  final PlayExtra playExtra;
  final int? continueEpisode;

  const PlayRouteExtra({
    required this.playExtra,
    this.continueEpisode,
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