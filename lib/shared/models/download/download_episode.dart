import 'package:hive_ce/hive.dart';

part 'download_episode.g.dart';

@HiveType(typeId: 11)
class DownloadEpisode {
  @HiveField(0)
  String episodeUrl;

  @HiveField(1)
  int bangumiEpisodeId;

  @HiveField(2)
  double episodeSort;

  @HiveField(3)
  int episodeIndex;

  @HiveField(4)
  String episodeTitle;

  @HiveField(5)
  int lineIndex;

  @HiveField(6)
  String sourceName;

  @HiveField(7)
  int status;

  @HiveField(8)
  double progressPercent;

  @HiveField(9)
  int totalSegments;

  @HiveField(10)
  int downloadedSegments;

  @HiveField(11)
  int totalBytes;

  @HiveField(12)
  String networkMediaUrl;

  @HiveField(13)
  String localMediaPath;

  @HiveField(14)
  String mediaType;

  @HiveField(15)
  String downloadDirectory;

  @HiveField(16)
  DateTime? completedAt;

  @HiveField(17)
  String errorMessage;

  @HiveField(18)
  bool danmakuDownloaded;

  @HiveField(19)
  String localDanmakuPath;

  @HiveField(20)
  int danDanBangumiID;

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
  });
}
