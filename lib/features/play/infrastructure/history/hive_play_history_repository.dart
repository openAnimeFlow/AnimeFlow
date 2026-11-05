import 'package:anime_flow/features/play/domain/play_history_repository.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';
import 'package:anime_flow/shared/models/player/play/play_history_item.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:hive_ce/hive.dart';

class HivePlayHistoryRepository implements PlayHistoryRepository {
  static const int _playHistoryMaxPages = 20;
  Box<PlayHistory> get playHistoryStorage => Storage.playHistory;

  @override
  Stream<void> get changes => playHistoryStorage.watch().map((_) {});

  @override
  Future<List<PlaybackRecord>> getAll() async =>
      playHistoryStorage.values.map(_toRecord).toList();

  @override
  Future<PlaybackRecord?> getBySubjectId(int subjectId) async {
    final row = playHistoryStorage.get(subjectId);
    return row == null ? null : _toRecord(row);
  }

  PlaybackRecord _toRecord(PlayHistory row) => PlaybackRecord(
        subjectId: row.subjectId,
        episodeId: row.episodeId,
        episodeSort: row.episodeSort,
        subjectName: row.subjectName,
        cover: row.cover,
        updateAt: row.updateAt,
        position: row.position,
        duration: row.duration,
        alias: List.unmodifiable(row.alias),
        isSyncedToServer: row.isSyncedToServer,
      );

  @override
  Future<void> save(PlaybackRecord record,
      {required PlayHistoryEventType eventType}) async {
    final playHistory = PlayHistory(
      subjectId: record.subjectId,
      episodeId: record.episodeId,
      episodeSort: record.episodeSort,
      subjectName: record.subjectName,
      cover: record.cover,
      updateAt: record.updateAt,
      position: record.position,
      duration: record.duration,
      alias: record.alias,
    );

    playHistory.isSyncedToServer = false;
    await playHistoryStorage.put(playHistory.subjectId, playHistory);
    await _trimToLimit<PlayHistory>(
      playHistoryStorage,
      (a, b) => b.updateAt.compareTo(a.updateAt),
    );

    await _syncPlayHistory(playHistory, eventType: eventType);
  }

  /// 将单条本地播放记录同步到服务器。
  Future<bool> _syncPlayHistory(
    PlayHistory playHistory, {
    PlayHistoryEventType eventType = PlayHistoryEventType.defaults,
  }) async {
    if (await FlowTokenStorage.instance.getToken() == null) {
      return false;
    }

    try {
      await FlowApi.savePlayHistoryService(
        eventType: eventType,
        subjectId: playHistory.subjectId,
        episodeId: playHistory.episodeId,
        episodeSort: playHistory.episodeSort,
        subjectName: playHistory.subjectName,
        cover: playHistory.cover,
        alias: playHistory.alias,
        positionSeconds: playHistory.position,
        durationSeconds: playHistory.duration,
      );
      playHistory.isSyncedToServer = true;
      await playHistoryStorage.put(playHistory.subjectId, playHistory);
      return true;
    } catch (e) {
      playHistory.isSyncedToServer = false;
      await playHistoryStorage.put(playHistory.subjectId, playHistory);
      LiggLogger().e('同步播放记录失败: $e');
      return false;
    }
  }

  /// 批量补同步本地尚未上传的播放记录。
  @override
  Future<PlayHistorySyncResult> syncPending() async {
    final pendingHistories = playHistoryStorage.values
        .where((history) => !history.isSyncedToServer)
        .toList(growable: false);
    if (pendingHistories.isEmpty) {
      return const PlayHistorySyncResult();
    }
    if (await FlowTokenStorage.instance.getToken() == null) {
      return PlayHistorySyncResult(
        total: pendingHistories.length,
        requiresLogin: true,
      );
    }

    var synced = 0;
    for (final history in pendingHistories) {
      if (await _syncPlayHistory(history)) {
        synced++;
      }
    }
    return PlayHistorySyncResult(
      total: pendingHistories.length,
      synced: synced,
    );
  }

  /// 从服务器拉取播放记录并合并到本地。
  @override
  Future<PlayHistoryPullResult> syncFromServer() async {
    if (await FlowTokenStorage.instance.getToken() == null) {
      return const PlayHistoryPullResult(requiresLogin: true);
    }

    const limit = 50;
    final remoteRecords = <PlayHistoryItem>[];
    var offset = 0;
    for (var page = 0; page < _playHistoryMaxPages; page++) {
      final pageData = await FlowApi.getPlayHistoryService(
        limit: limit,
        offset: offset,
      );
      remoteRecords.addAll(pageData);
      if (pageData.length < limit) break;
      offset += limit;
      if (page == _playHistoryMaxPages - 1) {
        LiggLogger().w('播放记录拉取达到最大页数限制: $_playHistoryMaxPages');
      }
    }

    var imported = 0;
    var updated = 0;
    var skipped = 0;
    for (final remote in remoteRecords) {
      final local = await getBySubjectId(remote.subjectId);
      if (local != null && !local.acceptsRemoteUpdate(remote.lastPlayedAt)) {
        skipped++;
        continue;
      }

      final history = PlayHistory(
        subjectId: remote.subjectId,
        episodeId: remote.episodeId,
        episodeSort: remote.episodeSort,
        subjectName: remote.subjectName,
        cover: remote.cover,
        alias: remote.alias,
        position: remote.positionSeconds,
        duration: remote.durationSeconds,
        updateAt: remote.lastPlayedAt,
        isSyncedToServer: true,
      );
      await playHistoryStorage.put(history.subjectId, history);
      if (local == null) {
        imported++;
      } else {
        updated++;
      }
    }

    await _trimToLimit<PlayHistory>(
      playHistoryStorage,
      (a, b) => b.updateAt.compareTo(a.updateAt),
    );
    return PlayHistoryPullResult(
      total: remoteRecords.length,
      imported: imported,
      updated: updated,
      skipped: skipped,
    );
  }

  /// 清空本地播放记录。
  @override
  Future<void> clearLocal() async {
    await playHistoryStorage.clear();
  }

  /// 读取播放记录
  Future<PlayHistory?> _getPlayHistory(int subjectId) async {
    return playHistoryStorage.get(subjectId);
  }

  /// 删除播放记录中的播放进度
  @override
  Future<void> clearPosition(int subjectId) async {
    final playHistory = await _getPlayHistory(subjectId);
    if (playHistory != null) {
      playHistory.position = 0;
      playHistory.duration = 0;
      playHistory.isSyncedToServer = false;
      await playHistoryStorage.put(subjectId, playHistory);
    }

    if (await FlowTokenStorage.instance.getToken() == null) {
      return;
    }

    try {
      await FlowApi.clearPlayHistoryProgressService(subjectId);
      if (playHistory != null) {
        playHistory.isSyncedToServer = true;
        await playHistoryStorage.put(subjectId, playHistory);
      }
    } catch (e) {
      LiggLogger().e('同步播放完成状态失败: $e');
    }
  }

  /// 限制存储数量
  /// [box] 存储盒子
  /// [compare] 比较函数，用于排序（返回负数表示 a < b，正数表示 a > b）
  /// [max] 最大保存数量，默认50条
  static Future<void> _trimToLimit<T extends HiveObject>(
    Box<T> box,
    int Function(T, T) compare, {
    int max = 50,
  }) async {
    final list = box.values.toList();
    if (list.length <= max) {
      return;
    } else {
      list.sort(compare);

      final recordsToDelete = list.skip(max - 20).take(20).toList();

      for (final p in recordsToDelete) {
        await p.delete();
      }
    }
  }
}
