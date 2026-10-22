import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/player_snapshot.dart';
import 'package:anime_flow/core/async/serial_operation_queue.dart';

/// 播放器基础协调层。
class PlaybackCoordinator {
  PlaybackCoordinator({
    required this.engineFactory,
    required this.adBlocker,
    required bool hardwareDecoder,
    this.reportError,
  }) : _hardwareDecoder = hardwareDecoder;

  final PlayerEngineFactory engineFactory;
  final bool adBlocker;
  bool _hardwareDecoder;
  bool get hardwareDecoder => _hardwareDecoder;
  final void Function(String message, Object error, StackTrace stackTrace)?
      reportError;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  StreamSubscription<PlayerEvent>? _engineSubscription;
  PlayerEngine? _engine;
  bool _disposed = false;
  late final _operations = SerialOperationQueue(ensureReady: _ensureReady);
  Future<void>? _disposal;
  Future<void>? _initialization;

  PlayerEngine get _activeEngine =>
      _engine ?? (throw StateError('PlaybackCoordinator has no active engine'));
  PlayerEngine get engine => _activeEngine;

  PlayerKernel get kernel => _activeEngine.kernel;
  Stream<PlayerEvent> get events => _events.stream;
  PlayerCapabilities get capabilities => _activeEngine.capabilities;

  Future<void> initialize({PlayerKernel kernel = PlayerKernel.mediaKit}) {
    if (_disposed) {
      return Future<void>.error(StateError('PlaybackCoordinator is disposed'));
    }
    return _initialization ??= _initialize(kernel);
  }

  Future<void> _initialize(PlayerKernel kernel) async {
    final engine = engineFactory(kernel,
        adBlocker: adBlocker, hardwareDecoder: hardwareDecoder);
    _engine = engine;
    await engine.initialize();
    if (_disposed) return;
    _subscribeToEngine(engine);
  }

  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) =>
      _run(() => _activeEngine.open(
            source,
            startPosition: startPosition,
            autoPlay: autoPlay,
          ));

  Future<void> play() => _run(() => _activeEngine.play());
  Future<void> pause() => _run(() => _activeEngine.pause());
  Future<void> stop() => _run(() => _activeEngine.stop());
  Future<void> seek(Duration position) =>
      _run(() => _activeEngine.seek(position));
  Future<void> setVolume(double volume) =>
      _run(() => _activeEngine.setVolume(volume));
  Future<void> setRate(double rate) => _run(() => _activeEngine.setRate(rate));
  Future<Uint8List?> screenshot() =>
      _run<Uint8List?>(() => _activeEngine.screenshot());
  Future<void> setShaders(String shaderList) =>
      _run(() => _activeEngine.setShaders(shaderList));

  Future<T?> _run<T>(Future<T> Function() command) async {
    try {
      return await _operations.run(command);
    } catch (_) {
      // 页面退出后，静默取消尚未执行的控制命令。
      if (!_disposed) rethrow;
      return null;
    }
  }

  /// 切换内核并恢复快照；提交前失败时保留原内核，提交后由新内核承接异常。
  Future<bool> switchKernel(PlayerKernel target, PlayerSnapshot snapshot,
          {bool force = false, String? shaders, bool? hardwareDecoder}) async =>
      await _run(() async {
        if (!force && target == _activeEngine.kernel) return true;

        final current = _activeEngine;
        final source = snapshot.source;
        PlayerEngine? next;
        try {
          if (source != null) await current.pause();
          _ensureReady();
          next = engineFactory(target,
              adBlocker: adBlocker,
              hardwareDecoder: hardwareDecoder ?? this.hardwareDecoder);
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
        } catch (error, stackTrace) {
          await _cleanup(next?.dispose);
          if (_disposed) return false;
          reportError?.call('准备播放器内核失败', error, stackTrace);
          next = null;
        }

        if (next != null) {
          // 提交后只清理旧内核；准备失败时继续保留原内核。
          final previousSubscription = _engineSubscription;
          _engine = next;
          _hardwareDecoder = hardwareDecoder ?? _hardwareDecoder;
          _subscribeToEngine(next);
          await _cleanup(previousSubscription?.cancel);
          await _cleanup(current.dispose);
        }
        if (!_disposed && source != null && snapshot.wasPlaying) {
          try {
            await _activeEngine.play();
          } catch (error, stackTrace) {
            if (!_disposed) _events.add(PlayerError(error, stackTrace));
          }
        }
        return !_disposed && next != null;
      }) ??
      false;

  Future<void> _cleanup(Future<void> Function()? action) async {
    try {
      await action?.call();
    } catch (error, stackTrace) {
      reportError?.call('清理播放器资源失败', error, stackTrace);
    }
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    // 初始化异常由调用方处理，清理仍等待初始化和已提交的原生操作完成。
    if (_engineSubscription == null) {
      await _initialization?.catchError((Object _) {});
    }
    await _operations.drained;
    await _cleanup(_engineSubscription?.cancel);
    await _cleanup(_engine?.dispose);
    _engine = null;
    await _cleanup(_events.close);
  }

  void _subscribeToEngine(PlayerEngine engine) {
    _engineSubscription = engine.events.listen((event) {
      if (_disposed || engine != _engine || _events.isClosed) return;
      _events.add(event);
    });
  }

  void _ensureReady() {
    if (_engineSubscription == null || _disposed) {
      throw StateError('PlaybackCoordinator is not initialized');
    }
  }
}
