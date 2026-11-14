import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';

class PlaybackRecord {
  /// 番剧id
  final int subjectId;

  /// 集id
  final int episodeId;

  /// 集数
  final int episodeSort;

  /// 名称
  final String subjectName;

  /// 封面
  final String cover;

  /// 更新时间
  final DateTime updateAt;

  /// 播放进度
  final int position;

  /// 视频总时长
  final int duration;

  /// 别名
  final List<String> alias;

  /// 是否已同步到服务器。
  final bool isSyncedToServer;

  bool acceptsRemoteUpdate(DateTime remoteTime) =>
      isSyncedToServer && remoteTime.isAfter(updateAt);

  const PlaybackRecord({
    required this.subjectId,
    required this.episodeId,
    required this.episodeSort,
    required this.subjectName,
    required this.cover,
    required this.updateAt,
    required this.position,
    required this.duration,
    required this.alias,
    this.isSyncedToServer = false,
  });
}

abstract interface class PlayHistoryRepository {
  Stream<void> get changes;
  Future<List<PlaybackRecord>> getAll();
  Future<PlaybackRecord?> getBySubjectId(int subjectId);
  Future<void> save(PlaybackRecord record,
      {required PlayHistoryEventType eventType});
  Future<void> clearPosition(int subjectId);
  Future<PlayHistorySyncResult> syncPending();
  Future<PlayHistoryPullResult> syncFromServer();
  Future<void> clearLocal();
}

class PlayHistorySyncResult {
  const PlayHistorySyncResult({
    this.total = 0,
    this.synced = 0,
    this.requiresLogin = false,
  });

  final int total;
  final int synced;
  final bool requiresLogin;

  int get failed => total - synced;
}

class PlayHistoryPullResult {
  const PlayHistoryPullResult({
    this.total = 0,
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    this.requiresLogin = false,
  });

  final int total;
  final int imported;
  final int updated;
  final int skipped;
  final bool requiresLogin;

  int get changed => imported + updated;
}
