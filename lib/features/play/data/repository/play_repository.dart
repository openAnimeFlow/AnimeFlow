import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';
import 'package:anime_flow/shared/models/player/play/play_history_item.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:hive_ce/hive.dart';

class PlayRepository {
  static final playHistoryStorage = Storage.playHistory;

  /// 保存播放记录
  static Future<void> savePlayHistory(
    PlayHistory playHistory, {
    PlayHistoryEventType eventType = PlayHistoryEventType.defaults,
  }) async {
    playHistory.isSyncedToServer = false;
    await playHistoryStorage.put(playHistory.subjectId, playHistory);
    await _trimToLimit<PlayHistory>(
      playHistoryStorage,
      (a, b) => b.updateAt.compareTo(a.updateAt),
    );

    await syncPlayHistory(playHistory, eventType: eventType);
  }

  /// 将单条本地播放记录同步到服务器。
  static Future<bool> syncPlayHistory(
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
  static Future<PlayHistorySyncResult> syncPendingPlayHistories() async {
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
      if (await syncPlayHistory(history)) {
        synced++;
      }
    }
    return PlayHistorySyncResult(
      total: pendingHistories.length,
      synced: synced,
    );
  }

  /// 从服务器拉取播放记录并合并到本地。
  static Future<PlayHistoryPullResult> syncPlayHistoriesFromServer() async {
    if (await FlowTokenStorage.instance.getToken() == null) {
      return const PlayHistoryPullResult(requiresLogin: true);
    }

    const limit = 50;
    final remoteRecords = <PlayHistoryItem>[];
    var offset = 0;
    while (true) {
      final page = await FlowApi.getPlayHistoryService(
        limit: limit,
        offset: offset,
      );
      remoteRecords.addAll(page);
      if (page.length < limit) break;
      offset += limit;
    }

    var imported = 0;
    var updated = 0;
    var skipped = 0;
    for (final remote in remoteRecords) {
      final local = await getPlayHistory(remote.subjectId);
      if (local != null && !local.isSyncedToServer) {
        skipped++;
        continue;
      }
      if (local != null && !remote.lastPlayedAt.isAfter(local.updateAt)) {
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

  ///获取播放记录列表
  static Future<List<PlayHistory>> getPlayHistoryList() async {
    return playHistoryStorage.values.toList();
  }

  /// 清空本地播放记录。
  static Future<void> clearLocalPlayHistories() async {
    await playHistoryStorage.clear();
  }

  /// 读取播放记录
  static Future<PlayHistory?> getPlayHistory(int subjectId) async {
    return playHistoryStorage.get(subjectId);
  }

  /// 删除播放记录中的播放进度
  static Future<void> deletePlayHistoryByPosition(int subjectId) async {
    final playHistory = await getPlayHistory(subjectId);
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
