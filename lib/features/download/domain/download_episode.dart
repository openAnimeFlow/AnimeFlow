class DownloadEpisode {
  String episodeUrl;

  int bangumiEpisodeId;

  double episodeSort;

  int episodeIndex;

  String episodeTitle;

  int lineIndex;

  String sourceName;

  int status;

  double progressPercent;

  int totalSegments;

  int downloadedSegments;

  int totalBytes;

  String networkMediaUrl;

  String localMediaPath;

  String mediaType;

  String downloadDirectory;

  DateTime? completedAt;

  String errorMessage;

  bool danmakuDownloaded;

  String localDanmakuPath;

  int danDanBangumiID;

  int totalSizeBytes;

  DownloadEpisode({
    required this.episodeUrl,
    required this.bangumiEpisodeId,
    required this.episodeSort,
    required this.episodeIndex,
    required this.episodeTitle,
    required this.lineIndex,
    required this.sourceName,
    required this.status,
    this.progressPercent = 0,
    this.totalSegments = 0,
    this.downloadedSegments = 0,
    this.totalBytes = 0,
    this.networkMediaUrl = '',
    this.localMediaPath = '',
    this.mediaType = '',
    this.downloadDirectory = '',
    this.completedAt,
    this.errorMessage = '',
    this.danmakuDownloaded = false,
    this.localDanmakuPath = '',
    this.danDanBangumiID = 0,
    this.totalSizeBytes = 0,
  });
}
