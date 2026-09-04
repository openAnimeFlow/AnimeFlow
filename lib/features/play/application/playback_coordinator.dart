import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/player_snapshot.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:flutter/material.dart';


/// 播放器基础协调层，负责内核实例生命周期和内核切换。
class PlaybackCoordinator {
  PlaybackCoordinator({
    required this.engineFactory,
    required this.adBlocker,
  });

  final PlayerEngineFactory engineFactory;
  final bool adBlocker;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  StreamSubscription<PlayerEvent>? _engineSubscription;
  late PlayerEngine _engine;
  bool _initialized = false;
  bool _disposed = false;

  PlayerEngine get engine => _engine;
  PlayerKernel get kernel => _engine.kernel;
  Stream<PlayerEvent> get events => _events.stream;
  PlayerCapabilities get capabilities => _engine.capabilities;

  Future<void> initialize({PlayerKernel kernel = PlayerKernel.mediaKit}) async {
    if (_initialized) return;
    _engine = engineFactory.create(kernel, adBlocker: adBlocker);
    await _engine.initialize();
    _subscribeToEngine(_engine);
    _initialized = true;
  }

  Widget buildVideoSurface({required BoxFit fit}) {
    _ensureReady();
    return _engine.buildVideoSurface(fit: fit);
  }

  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) =>
      _engine.open(
        source,
        startPosition: startPosition,
        autoPlay: autoPlay,
      );

  Future<void> play() => _engine.play();
  Future<void> pause() => _engine.pause();
  Future<void> stop() => _engine.stop();
  Future<void> seek(Duration position) => _engine.seek(position);
  Future<void> setVolume(double volume) => _engine.setVolume(volume);
  Future<void> setRate(double rate) => _engine.setRate(rate);
  Future<Uint8List?> screenshot() => _engine.screenshot();
  Future<void> setShaders(String shaderList) => _engine.setShaders(shaderList);

  /// 切换内核并恢复快照。失败时保留原内核，并恢复原播放状态。
  Future<bool> switchKernel(
    PlayerKernel target,
    PlayerSnapshot snapshot,
  ) async {
    _ensureReady();
    if (target == _engine.kernel) return true;

    final current = _engine;
    PlayerEngine? next;
    try {
      await current.pause();
      next = engineFactory.create(target, adBlocker: adBlocker);
      await next.initialize();
      await next.open(
        snapshot.source,
        startPosition: snapshot.position,
        autoPlay: false,
      );
      await next.setVolume(snapshot.volume);
      await next.setRate(snapshot.rate);

      await _engineSubscription?.cancel();
      _engine = next;
      _subscribeToEngine(next);
      await current.dispose();
      if (snapshot.wasPlaying) await next.play();
      return true;
    } catch (_) {
      await next?.dispose();
      if (snapshot.wasPlaying) unawaited(current.play());
      return false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _engineSubscription?.cancel();
    await _engine.dispose();
    await _events.close();
  }

  void _subscribeToEngine(PlayerEngine engine) {
    _engineSubscription = engine.events.listen((event) {
      if (!_disposed && !_events.isClosed) _events.add(event);
    });
  }

  void _ensureReady() {
    if (!_initialized || _disposed) {
      throw StateError('PlaybackCoordinator is not initialized');
    }
  }
}
