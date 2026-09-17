import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/application/danmaku_canvas.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_dispatch_scheduler.dart';
import 'package:anime_flow/features/play/application/danmaku_state.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter/material.dart';

class DanmakuPlaybackSnapshot {
  const DanmakuPlaybackSnapshot({
    required this.position,
    required this.duration,
    required this.playing,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
}

/// 管理当前播放会话的弹幕数据、请求、画布和进度分发。
class DanmakuSession {
  DanmakuSession({
    required DanmakuStore store,
    required this.converter,
    required DanmakuChineseMode initialChineseMode,
    required this.readPlayback,
    required this.currentUserId,
  })  : _store = store,
        _chineseMode = initialChineseMode;

  final DanmakuStore _store;
  final DanmakuChineseConverter converter;
  final DanmakuPlaybackSnapshot Function() readPlayback;
  final int? Function() currentUserId;
  DanmakuChineseMode _chineseMode;
  int _chineseModeRevision = 0;
  int _requestId = 0;
  bool _disposed = false;
  int _subjectId = 0;
  int _episode = 0;
  bool _isLocalPlayback = false;
  DanmakuCanvas? _canvas;
  late final DanmakuDispatchScheduler _scheduler = DanmakuDispatchScheduler(
    readSnapshot: () {
      final playback = readPlayback();
      final state = _store.value;
      return DanmakuDispatchSnapshot(
        position: playback.position,
        playing: playback.playing,
        danmakuOn: state.enabled,
        danmakus: state.danmakus,
        epoch: state.epoch,
      );
    },
    onDanmaku: _dispatch,
  );

  DanmakuCanvas? get canvas => _canvas;
  set canvas(DanmakuCanvas? value) {
    if (identical(_canvas, value)) return;
    _scheduler.stop();
    _canvas = value;
    if (value != null && !_disposed) _scheduler.start();
  }

  void _dispatch(Danmaku danmaku) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(danmaku.source);
    final platform = match?.group(1) ?? '弹弹Play';
    if (isPlatformHidden(platform)) return;
    _canvas?.addDanmaku(
      danmaku,
      currentUserId(),
      color: AppSettings.danmakuColor ? null : Colors.white,
    );
  }

  void onPlaybackChanged(bool playing) => _canvas?.syncPlayback(playing);
  void onSeek() => _scheduler.invalidate();
  void clearCanvas() => _canvas?.clear();

  /// 新的视频请求开始时立即废弃旧请求及待显示弹幕。
  void beginPlaybackChange() {
    _requestId++;
    _scheduler.invalidate();
    _store.setLoadStatus(DanmakuLoadStatus.waitingForVideo);
  }

  void setPlaybackContext({
    required int subjectId,
    required int episode,
    required bool isLocalPlayback,
  }) {
    _subjectId = subjectId;
    _episode = episode;
    _isLocalPlayback = isLocalPlayback;
  }

  int get requestId => _requestId;

  Future<void> loadEpisode({
    required int subjectId,
    required int episode,
    required bool isLocalPlayback,
    required String? localPath,
    required int expectedRequestId,
    required bool Function() isPlaybackCurrent,
  }) async {
    if (_disposed || expectedRequestId != _requestId) return;
    if (episode == 0) {
      _store.setLoadStatus(DanmakuLoadStatus.idle);
      return;
    }
    final requestId = ++_requestId;
    bool isCurrent() =>
        !_disposed && isPlaybackCurrent() && requestId == _requestId;
    _store.setLoadStatus(DanmakuLoadStatus.loading);
    var failed = false;
    try {
      final List<Danmaku> danmakus;
      if (isLocalPlayback) {
        danmakus = await _loadLocal(localPath);
      } else {
        final bangumiId =
            await FlowApi.getDanDanBangumiIDByBgmBangumiID(subjectId);
        if (!isCurrent() || bangumiId == null) return;
        danmakus = await FlowApi.getDanDanmaku(bangumiId, episode);
      }
      if (danmakus.isEmpty) return;
      while (isCurrent()) {
        final revision = _chineseModeRevision;
        final converted =
            await converter.convertDanmakus(danmakus, _chineseMode);
        if (!isCurrent()) return;
        if (revision != _chineseModeRevision) continue;
        addAll(converted);
        return;
      }
    } catch (error) {
      failed = true;
      LiggLogger().e(error);
    } finally {
      if (isCurrent()) {
        _store.setLoadStatus(
          failed ? DanmakuLoadStatus.failed : DanmakuLoadStatus.idle,
        );
      }
    }
  }

  Future<bool> switchEpisode(int episodeId) async {
    final requestId = ++_requestId;
    bool isCurrent() => !_disposed && requestId == _requestId;
    _store.setLoadStatus(DanmakuLoadStatus.switching);
    try {
      final items = await FlowApi.getDanDanmakuByEpisodeID(episodeId);
      while (isCurrent()) {
        final revision = _chineseModeRevision;
        final converted = await converter.convertDanmakus(items, _chineseMode);
        if (!isCurrent()) return false;
        if (revision != _chineseModeRevision) continue;
        clear();
        addAll(converted);
        _store.setLoadStatus(DanmakuLoadStatus.idle);
        return true;
      }
    } catch (error) {
      LiggLogger().e(error);
      if (isCurrent()) _store.setLoadStatus(DanmakuLoadStatus.failed);
    }
    return false;
  }

  void addAll(List<Danmaku> items) {
    final grouped = <int, List<Danmaku>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.time.toInt(), () => []).add(item);
    }
    _store.setDanmakus(grouped);
  }

  Future<void> applyChineseMode(DanmakuChineseMode mode) async {
    if (_chineseMode == mode) return;
    _chineseMode = mode;
    final revision = ++_chineseModeRevision;
    final all = _store.value.danmakus.values.expand((items) => items).toList();
    if (all.isEmpty) return;
    _store.incrementEpoch();
    clearCanvas();
    final converted = await converter.convertDanmakus(all, mode);
    if (_disposed || revision != _chineseModeRevision) return;
    addAll(converted);
  }

  Future<bool> send(
    String message, {
    required int bgmUserId,
    Color? color,
    int type = 1,
  }) async {
    if (_isLocalPlayback) return false;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return false;
    final subjectId = _subjectId;
    final episode = _episode;
    final requestId = _requestId;
    final bangumiId =
        await FlowApi.getDanDanBangumiIDByBgmBangumiID(subjectId);
    if (bangumiId == null || _disposed || requestId != _requestId) return false;
    final playback = readPlayback();
    if (playback.duration == Duration.zero &&
        playback.position == Duration.zero &&
        episode <= 0) {
      return false;
    }
    final item = Danmaku(
      message: trimmed,
      time: playback.position.inMicroseconds / Duration.microsecondsPerSecond,
      type: type,
      color: color ?? Colors.white,
      bgmUserId: bgmUserId,
      source: 'AnimeFlow',
    );
    _canvas?.addDanmaku(item, bgmUserId);
    await FlowApi.sendDanmaku(
      bangumiId,
      episode,
      message: item.message,
      time: item.time,
      type: item.type,
      color: item.color,
    );
    return true;
  }

  Future<List<Danmaku>> _loadLocal(String? path) async {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return const [];
    final file = File(trimmed);
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      final items = switch (decoded) {
        List<dynamic> value => value,
        {'data': final List<dynamic> value} => value,
        {'comments': final List<dynamic> value} => value,
        _ => const <dynamic>[],
      };
      return items
          .whereType<Map<String, dynamic>>()
          .map(Danmaku.fromJson)
          .toList();
    } catch (error) {
      LiggLogger().e('加载本地弹幕失败: $error');
      return const [];
    }
  }

  void clear() {
    _scheduler.invalidate();
    _store.incrementEpoch();
    _requestId++;
    _chineseModeRevision++;
    clearCanvas();
    _store.clearDanmakus();
  }

  void toggleEnabled() {
    _store.toggleEnabled();
    AppSettings.setDanmakuOn(_store.value.enabled);
    if (!_store.value.enabled) clearCanvas();
  }

  void togglePlatformVisibility(String platform) {
    _store.toggleHiddenPlatform(platform);
    clearCanvas();
  }

  bool isPlatformHidden(String platform) =>
      _store.value.hiddenPlatforms.contains(platform);

  void syncPlatformVisibility(Set<String> hiddenPlatforms) {
    _store.setHiddenPlatforms(hiddenPlatforms);
    clearCanvas();
  }

  void dispose() {
    _disposed = true;
    _requestId++;
    _chineseModeRevision++;
    _scheduler.stop();
    clearCanvas();
    _canvas = null;
  }
}
