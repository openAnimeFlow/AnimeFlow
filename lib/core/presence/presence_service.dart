import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

/// 应用级在线状态服务。
class PresenceService with WidgetsBindingObserver {
  PresenceService._();

  static final PresenceService instance = PresenceService._();
  static const Uuid _uuid = Uuid();

  static const _heartbeatInterval = Duration(minutes: 1);

  Timer? _timer;
  String? _visitorId;
  String? _presenceId;
  String? _appVersion;
  int? _subjectId;
  int? _episodeId;
  int? _positionSeconds;
  String _status = 'online';
  bool _started = false;
  Future<void> _presenceRequestTail = Future<void>.value();

  Future<void> start({required String appVersion}) async {
    if (_started) return;
    _started = true;
    _appVersion = appVersion;
    _visitorId = await _getOrCreateId(StorageKey.visitorId, 'v');
    _presenceId = await _getOrCreateId(StorageKey.presenceId, 'p');
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
    await _sendHeartbeat();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
    await _sendOffline();
  }

  /// 在登录、登出等身份变化后立即刷新一次在线身份口径。
  Future<void> heartbeatNow() => _sendHeartbeat();

  /// 更新当前播放上下文。实际网络请求仍由应用级心跳定时器统一发送。
  void setPlaybackContext({
    required int subjectId,
    required int episodeId,
    required bool watching,
    int? positionSeconds,
  }) {
    if (subjectId <= 0 || episodeId <= 0) return;
    final nextStatus = watching ? 'watching' : 'paused';
    final changed = _subjectId != subjectId ||
        _episodeId != episodeId ||
        _status != nextStatus;
    _subjectId = subjectId;
    _episodeId = episodeId;
    _positionSeconds = positionSeconds;
    _status = nextStatus;
    if (changed && _started) {
      unawaited(_sendHeartbeat());
    }
  }

  void clearPlaybackContext() {
    final changed =
        _subjectId != null || _episodeId != null || _status != 'online';
    _subjectId = null;
    _episodeId = null;
    _positionSeconds = null;
    _status = 'online';
    if (changed && _started) {
      unawaited(_sendHeartbeat());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _timer ??= Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
        unawaited(_sendHeartbeat());
      case AppLifecycleState.inactive:
        // 桌面端窗口失去焦点仍可能在播放，不能视为离线。
        _timer ??= Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
        unawaited(_sendHeartbeat());
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _timer?.cancel();
        _timer = null;
        unawaited(_sendOffline());
    }
  }

  Future<void> _sendHeartbeat() async {
    if (!_started || _visitorId == null || _presenceId == null) return;
    await _enqueuePresenceRequest(() async {
      // stop() may have been called while an earlier request was in flight.
      if (!_started || _visitorId == null || _presenceId == null) return;
      try {
        await FlowApi.presenceHeartbeat(
          visitorId: _visitorId!,
          presenceId: _presenceId!,
          clientType: Platform.operatingSystem.toUpperCase(),
          appVersion: _appVersion,
          subjectId: _subjectId,
          episodeId: _episodeId,
          positionSeconds: _positionSeconds,
          status: _status,
        );
      } catch (error, stackTrace) {
        LiggLogger().w('在线状态心跳失败', error: error, stackTrace: stackTrace);
      }
    });
  }

  Future<void> _sendOffline() async {
    final presenceId = _presenceId;
    if (presenceId == null) return;
    await _enqueuePresenceRequest(() async {
      try {
        await FlowApi.presenceOffline(presenceId: presenceId);
      } catch (error, stackTrace) {
        LiggLogger().w('结束在线状态失败', error: error, stackTrace: stackTrace);
      }
    });
  }

  /// 心跳和下线共用一个队列，保证下线请求不会与旧心跳并发发送。
  Future<void> _enqueuePresenceRequest(
    Future<void> Function() request,
  ) {
    final pending = _presenceRequestTail.then((_) => request());
    // 单次请求失败不能阻塞后续的心跳或下线请求。
    _presenceRequestTail = pending.catchError((_) {});
    return pending;
  }

  Future<String> _getOrCreateId(String key, String prefix) async {
    final existing = AppSettings.getSetting<String>(key);
    if (existing is String && existing.isNotEmpty) return existing;
    final value = '${prefix}_${_uuid.v4()}';
    await AppSettings.setSetting(key, value);
    return value;
  }
}
