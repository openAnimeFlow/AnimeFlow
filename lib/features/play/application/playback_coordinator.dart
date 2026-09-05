import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/player_snapshot.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_operation_queue.dart';
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
  late final _operations = PlayerOperationQueue(ensureReady: _ensureReady);
  Future<void>? _disposal;

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
    // The first widget build can precede completion of initialize(). The engine
    // already exists at that point and owns its surface readiness checks.
    return _engine.buildVideoSurface(fit: fit);
  }

  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) =>
      _runCommand(() => _engine.open(
            source,
            startPosition: startPosition,
            autoPlay: autoPlay,
          ));

  Future<void> play() => _runCommand(() => _engine.play());
  Future<void> pause() => _runCommand(() => _engine.pause());
  Future<void> stop() => _runCommand(() => _engine.stop());
  Future<void> seek(Duration position) =>
      _runCommand(() => _engine.seek(position));
  Future<void> setVolume(double volume) =>
      _runCommand(() => _engine.setVolume(volume));
  Future<void> setRate(double rate) => _runCommand(() => _engine.setRate(rate));
  Future<Uint8List?> screenshot() =>
      _operations.run(() => _engine.screenshot());
  Future<void> setShaders(String shaderList) =>
      _runCommand(() => _engine.setShaders(shaderList));

  Future<void> _runCommand(Future<void> Function() command) async {
    try {
      await _operations.run(command);
    } catch (_) {
      // Controls already queued when the page exits are cancelled silently.
      if (!_disposed) rethrow;
    }
  }

  /// 切换内核并恢复快照。失败时保留原内核，并恢复原播放状态。
  Future<bool> switchKernel(PlayerKernel target, PlayerSnapshot snapshot,
      {bool force = false, String? shaders}) async {
    try {
      return await _operations.run(() =>
          _switchKernel(target, snapshot, force: force, shaders: shaders));
    } catch (_) {
      if (_disposed) return false;
      rethrow;
    }
  }

  Future<bool> _switchKernel(PlayerKernel target, PlayerSnapshot snapshot,
      {bool force = false, String? shaders}) async {
    _ensureReady();
    if (!force && target == _engine.kernel) return true;

    final current = _engine;
    PlayerEngine? next;
    try {
      final source = snapshot.source;
      if (source != null) await current.pause();
      _ensureReady();
      next = engineFactory.create(target, adBlocker: adBlocker);
      await next.initialize();
      _ensureReady();
      if (source != null) {
        await next.open(
          source,
          startPosition: snapshot.position,
          autoPlay: false,
        );
        _ensureReady();
      }
      await next.setVolume(snapshot.volume);
      _ensureReady();
      await next.setRate(snapshot.rate);
      if (shaders != null && next.capabilities.supportsShader) {
        await next.setShaders(shaders);
      }
      _ensureReady();

      await _engineSubscription?.cancel();
      _ensureReady();
      _engine = next;
      _subscribeToEngine(next);
      await current.dispose();
      _ensureReady();
      if (source != null && snapshot.wasPlaying) await next.play();
      return !_disposed;
    } catch (_) {
      // Once committed, dispose() owns the active engine. Before that, the
      // switching operation owns the candidate and must release it itself.
      if (_disposed) {
        if (next != _engine) await next?.dispose();
        return false;
      }
      await next?.dispose();
      if (snapshot.source != null && snapshot.wasPlaying) {
        unawaited(current.play());
      }
      return false;
    }
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    // Mark cancellation immediately, but let pending native work finish before
    // releasing either engine or closing the shared event stream.
    await _operations.drained;
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
