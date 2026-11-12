/// A snapshot of a downloaded episode available for offline playback.
typedef OfflineEpisode = ({
  int lineIndex,
  int episodeIndex,
  double episodeSort,
  String episodeUrl,
  int bangumiEpisodeId,
  String episodeTitle,
  String localMediaPath,
  String localDanmakuPath
});
