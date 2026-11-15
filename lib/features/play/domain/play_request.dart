import 'player/playback_source.dart';

/// 打开一集视频所需的播放地址与剧集上下文。
class PlayRequest {
  /// 播放源
  final PlaybackSource source;

  /// 播放偏移
  final int offset;

  /// 番剧id
  final int subjectId;

  ///番剧名称
  final String subjectName;

  ///番剧封面
  final String subjectCover;

  /// 别名
  final List<String> alias;

  /// 集数
  final int episodeIndex;

  /// Bangumi 剧集 sort
  final int episodeSort;

  ///剧集id
  final int episodeId;

  final String? localDanmakuPath;

  const PlayRequest({
    required this.source,
    required this.offset,
    required this.subjectId,
    required this.episodeIndex,
    required this.episodeSort,
    required this.episodeId,
    required this.subjectName,
    required this.subjectCover,
    required this.alias,
    this.localDanmakuPath,
  });
}
