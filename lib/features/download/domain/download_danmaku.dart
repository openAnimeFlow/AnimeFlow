import 'download_episode.dart';

class DownloadDanmakuResult {
  const DownloadDanmakuResult({
    required this.danDanBangumiId,
    required this.localPath,
    required this.hasDanmaku,
  });

  final int danDanBangumiId;
  final String localPath;
  final bool hasDanmaku;
}

abstract interface class IDownloadDanmakuService {
  Future<DownloadDanmakuResult?> download({
    required int subjectId,
    required DownloadEpisode episode,
  });
}
