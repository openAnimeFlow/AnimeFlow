import 'dart:async';

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';

typedef SetEpisodeWatched = void Function({
  required int subjectId,
  required int episodeId,
  required bool watched,
});

/// 播放历史和观看进度协调器。
class PlaybackProgressManager {
  PlaybackProgressManager({required this.setEpisodeWatched});

  static const watchedProgressThreshold = 0.90;
  static const pauseSaveThrottle = Duration(seconds: 1);

  final SetEpisodeWatched setEpisodeWatched;
  Future<void> _saveQueue = Future<void>.value();
  final Set<int> _autoWatchedEpisodeIds = {};
  final Set<int> _autoWatchedEpisodeUpdatesInFlight = {};
  DateTime? _lastPauseSavedAt;

  int subjectId = 0;
  int episodeId = 0;
  int episodeSort = 0;
  String? subjectName;
  String? subjectCover;
  List<String> alias = [];
  bool isLocalPlayback = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  void updateContext({
    required int subjectId,
    required int episodeId,
    required int episodeSort,
    required String? subjectName,
    required String? subjectCover,
    required List<String> alias,
    required bool isLocalPlayback,
  }) {
    this.subjectId = subjectId;
    this.episodeId = episodeId;
    this.episodeSort = episodeSort;
    this.subjectName = subjectName;
    this.subjectCover = subjectCover;
    this.alias = List<String>.from(alias);
    this.isLocalPlayback = isLocalPlayback;
  }

  void handleState({
    required Duration position,
    required Duration duration,
    required bool playing,
  }) {
    this.position = position;
    this.duration = duration;
    if (!playing || duration <= Duration.zero) return;
    if (isLocalPlayback || subjectId <= 0 || episodeId <= 0) return;
    if (subjectName == null || subjectCover == null) return;
    if (!Storage.setting
        .get(PlaybackKey.episodesProgress, defaultValue: true)) {
      return;
    }

    final progress = position.inMilliseconds / duration.inMilliseconds;
    if (progress < watchedProgressThreshold ||
        _autoWatchedEpisodeIds.contains(episodeId) ||
        _autoWatchedEpisodeUpdatesInFlight.contains(episodeId)) {
      return;
    }

    final targetEpisodeId = episodeId;
    _autoWatchedEpisodeUpdatesInFlight.add(targetEpisodeId);
    unawaited(_autoUpdateEpisodeWatched(targetEpisodeId));
  }

  void saveOnPause() {
    final now = DateTime.now();
    if (_lastPauseSavedAt != null &&
        now.difference(_lastPauseSavedAt!) < pauseSaveThrottle) {
      return;
    }
    _lastPauseSavedAt = now;
    unawaited(save());
  }

  Future<void> save({
    Duration? position,
    PlayHistoryEventType eventType = PlayHistoryEventType.defaults,
  }) async {
    if (duration <= Duration.zero ||
        subjectId <= 0 ||
        episodeId <= 0 ||
        subjectName == null ||
        subjectCover == null) {
      return;
    }
    final savedPosition = position ?? this.position;
    final playHistory = PlayHistory(
      subjectId: subjectId,
      subjectName: subjectName!,
      episodeId: episodeId,
      episodeSort: episodeSort,
      cover: subjectCover!,
      updateAt: DateTime.now(),
      position: savedPosition.inSeconds,
      duration: duration.inSeconds,
      alias: List<String>.from(alias),
    );
    _saveQueue = _saveQueue.then((_) async {
      try {
        await PlayHistoryService.save(playHistory, eventType: eventType);
      } catch (e) {
        LiggLogger().e('保存播放进度失败: $e');
      }
    });
    await _saveQueue;
  }

  Future<void> _autoUpdateEpisodeWatched(int targetEpisodeId) async {
    try {
      await FlowApi.updateEpisodeWatchedService(targetEpisodeId, watched: true);
      _autoWatchedEpisodeIds.add(targetEpisodeId);
      setEpisodeWatched(
        subjectId: subjectId,
        episodeId: targetEpisodeId,
        watched: true,
      );
    } catch (e) {
      LiggLogger().e('自动更新观看进度失败: $e');
    } finally {
      _autoWatchedEpisodeUpdatesInFlight.remove(targetEpisodeId);
    }
  }
}
