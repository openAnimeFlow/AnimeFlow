import 'dart:async';

import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';

typedef SetEpisodeWatchedCallback = void Function({
  required int subjectId,
  required int episodeId,
  required bool watched,
});

/// 播放进度采集器与播放记录写入协调器。
class PlaybackProgressManager {
  PlaybackProgressManager({required this.onEpisodeWatched});

  static const watchedProgressThreshold = 0.90;
  static const saveDebounce = Duration(seconds: 3);

  final SetEpisodeWatchedCallback onEpisodeWatched;
  Future<void> _saveQueue = Future<void>.value();
  final Set<int> _autoWatchedEpisodeIds = {};
  final Set<int> _autoWatchedEpisodeUpdatesInFlight = {};
  Timer? _saveTimer;
  Duration? _pendingSeekPosition;

  int subjectId = 0;
  int episodeId = 0;
  int episodeSort = 0;
  String? subjectName;
  String? subjectCover;
  List<String> alias = [];
  bool isLocalPlayback = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  void setPlaybackContext({
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

  void updatePlaybackState({
    required Duration position,
    required Duration duration,
    required bool playing,
    required bool isLoggedIn,
  }) {
    this.position = position;
    this.duration = duration;
    if (!isLoggedIn) return;
    if (!playing || duration <= Duration.zero) return;
    if (isLocalPlayback || subjectId <= 0 || episodeId <= 0) return;
    if (subjectName == null || subjectCover == null) return;
    if (!AppSettings.episodesProgress) {
      return;
    }

    final progress = position.inMilliseconds / duration.inMilliseconds;
    if (progress < watchedProgressThreshold ||
        _autoWatchedEpisodeIds.contains(episodeId) ||
        _autoWatchedEpisodeUpdatesInFlight.contains(episodeId)) {
      return;
    }

    _autoWatchedEpisodeUpdatesInFlight.add(episodeId);
    unawaited(_autoUpdateEpisodeWatched(episodeId));
  }

  /// 合并暂停和开始播放产生的连续保存事件。
  void saveAfterPlaybackChange() {
    _scheduleSave();
  }

  /// 拖动期间只保留最后一个位置，停止拖动一小段时间后再提交。
  void saveAfterSeek(Duration position) {
    _pendingSeekPosition = position;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () {
      _saveTimer = null;
      final pendingPosition = _takePendingSeekPosition();
      unawaited(save(
        position: pendingPosition,
        eventType: pendingPosition == null
            ? PlayHistoryEventType.defaults
            : PlayHistoryEventType.forceOverwrite,
      ));
    });
  }

  Future<void> save({
    Duration? position,
    PlayHistoryEventType eventType = PlayHistoryEventType.defaults,
  }) async {
    final pendingSeekPosition = _takePendingSeekPosition();
    if (duration <= Duration.zero ||
        subjectId <= 0 ||
        episodeId <= 0 ||
        subjectName == null ||
        subjectCover == null) {
      return;
    }
    final savedPosition = position ?? pendingSeekPosition ?? this.position;
    final effectiveEventType = pendingSeekPosition != null &&
            eventType == PlayHistoryEventType.defaults
        ? PlayHistoryEventType.forceOverwrite
        : eventType;
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
        await PlayHistoryService.save(
          playHistory,
          eventType: effectiveEventType,
        );
      } catch (e) {
        LiggLogger().e('保存播放进度失败: $e');
      }
    });
    await _saveQueue;
  }

  Duration? _takePendingSeekPosition() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final position = _pendingSeekPosition;
    _pendingSeekPosition = null;
    return position;
  }

  Future<void> _autoUpdateEpisodeWatched(int targetEpisodeId) async {
    try {
      await FlowApi.updateEpisodeWatchedService(targetEpisodeId, watched: true);
      _autoWatchedEpisodeIds.add(targetEpisodeId);
      onEpisodeWatched(
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
