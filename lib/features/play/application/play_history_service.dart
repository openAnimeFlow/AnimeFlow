import 'package:anime_flow/features/play/data/repository/play_repository.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// 播放历史的业务入口，供 player 内外的页面使用。
class PlayHistoryService {
  const PlayHistoryService._();

  static const Duration _autoSyncMinInterval = Duration(minutes: 1);
  static DateTime? _lastAutoSyncAt;
  static Future<PlayHistoryPullResult>? _autoSyncFuture;

  static ValueListenable<Box<PlayHistory>> listenable() =>
      PlayRepository.playHistoryStorage.listenable();

  static Future<List<PlayHistory>> getAll() =>
      PlayRepository.getPlayHistoryList();

  static Future<PlayHistory?> getBySubjectId(int subjectId) =>
      PlayRepository.getPlayHistory(subjectId);

  static Future<void> save(
    PlayHistory history, {
    PlayHistoryEventType eventType = PlayHistoryEventType.defaults,
  }) =>
      PlayRepository.savePlayHistory(history, eventType: eventType);

  static Future<void> clearPosition(int subjectId) =>
      PlayRepository.deletePlayHistoryByPosition(subjectId);

  static Future<PlayHistorySyncResult> syncPending() =>
      PlayRepository.syncPendingPlayHistories();

  static Future<PlayHistoryPullResult> syncFromServer() =>
      PlayRepository.syncPlayHistoriesFromServer();

  static Future<PlayHistoryPullResult> autoSyncFromServer() {
    final inFlight = _autoSyncFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final now = DateTime.now();
    final lastSyncAt = _lastAutoSyncAt;
    if (lastSyncAt != null &&
        now.difference(lastSyncAt) < _autoSyncMinInterval) {
      return Future.value(const PlayHistoryPullResult());
    }

    _lastAutoSyncAt = now;
    final syncFuture = PlayRepository.syncPlayHistoriesFromServer();
    _autoSyncFuture = syncFuture.whenComplete(() {
      _autoSyncFuture = null;
    });
    return _autoSyncFuture!;
  }

  static Future<void> clearLocal() => PlayRepository.clearLocalPlayHistories();
}
