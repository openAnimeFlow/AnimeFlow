import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:fvp/mdk.dart' as fvp;
import 'package:flutter/material.dart';

/// FVP backend player adapter.
///
/// This intentionally uses the backend API instead of fvp.registerWith(), so
/// MediaKit and FVP can coexist as explicitly selected engines.
class FvpEngine implements PlayerEngine {
  FvpEngine({fvp.Player Function()? playerFactory})
      : _playerFactory = playerFactory ?? fvp.Player.new;

  final fvp.Player Function() _playerFactory;
  // FVP defaults to a 4-second decoded-data buffer. On longer videos that is
  // only a few pixels on the progress bar, so keep a visible, practical
  // buffer for on-demand playback.
  static const int _bufferRangeMinMilliseconds = 1000;
  static const int _bufferRangeMaxMilliseconds = 60 * 1000;

  late final fvp.Player _player;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _pollTimer;
  bool _initialized = false;
  bool _disposed = false;
  bool _hasMedia = false;
  bool _acceptMediaStatus = false;
  Size? _videoSize;

  @override
  PlayerKernel get kernel => PlayerKernel.fvp;

  @override
  PlayerCapabilities get capabilities => const PlayerCapabilities(
        supportsScreenshot: true,
        supportsHardwareDecoder: true,
        supportsAudioOnly: true,
      );

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _player = _playerFactory();
    _player.setBufferRange(
      min: _bufferRangeMinMilliseconds,
      max: _bufferRangeMaxMilliseconds,
    );
    _subscriptions.addAll([
      _player.onStateChanged.listen((_) {
        _emitPlayingState();
      }),
      _player.onMediaStatus.listen((change) {
        if (!_acceptMediaStatus) return;
        _emitBufferingState();
        if (_hasMedia &&
            !change.oldValue.test(fvp.MediaStatus.end) &&
            change.newValue.test(fvp.MediaStatus.end) &&
            _player.mediaStatus.test(fvp.MediaStatus.end)) {
          _emit(const PlayerCompleted());
        }
      }),
      _player.onEvent.listen((event) {
        // 部分 MDK 事件复用 error 字段传递状态值，而不是错误码：
        // reader.buffering 是缓冲进度，thread.* 是线程状态，
        // render.video 是渲染时间戳。
        if (event.category == 'reader.buffering') {
          // FVP updates its buffered duration alongside this event. Reading
          // it here mirrors the package's official video_player backend and
          // avoids missing short-lived buffer updates between polling ticks.
          _emitBufferedPosition();
          _emitBufferingState();
          return;
        }

        final isStatusEvent = event.category == 'render.video' ||
            event.category.startsWith('thread.');
        if (!isStatusEvent && event.error != 0) {
          _emit(PlayerError(
            StateError('${event.category}: ${event.detail}'),
          ));
        }
      }),
    ]);
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _emitCurrentMetrics(),
    );
    _initialized = true;
  }

  @override
  Widget buildVideoSurface({required BoxFit fit}) {
    _ensureReady();
    return ColoredBox(
      color: Colors.black,
      child: ValueListenableBuilder<int?>(
        valueListenable: _player.textureId,
        builder: (context, textureId, child) {
          if (textureId == null || textureId < 0) {
            return const SizedBox.expand();
          }
          final size = _videoSize;
          final video = Texture(textureId: textureId);
          if (size == null || size.width <= 0 || size.height <= 0) {
            return SizedBox.expand(child: video);
          }
          return SizedBox.expand(
            child: FittedBox(
              fit: fit,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: video,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) async {
    _ensureReady();
    await stop();
    _videoSize = null;
    final headers = <String, String>{
      ...source.headers,
      if (source.referer != null) 'Referer': source.referer!,
    };
    if (headers.isNotEmpty) {
      _player.setProperty(
        'avio.headers',
        headers.entries
            .map((entry) => '${entry.key}: ${entry.value}\r\n')
            .join(),
      );
    }
    if (source.userAgent != null) {
      _player.setProperty('avio.user_agent', source.userAgent!);
    }
    _acceptMediaStatus = true;
    try {
      _player.media = source.uri.toString();
      final result = await _player.prepare(
        position: startPosition?.inMilliseconds ?? 0,
      );
      if (result < 0) {
        throw StateError('FVP prepare failed: $result');
      }
      final texture = await _player.updateTexture();
      if (texture < 0) {
        throw StateError('FVP video texture creation failed: $texture');
      }
      final video = _player.mediaInfo.video?.firstOrNull;
      if (video != null) {
        _videoSize = Size(
          video.codec.width.toDouble(),
          video.codec.height.toDouble(),
        );
      }
      _hasMedia = true;
      _emitCurrentMetrics();
      if (autoPlay) await play();
    } catch (_) {
      _acceptMediaStatus = false;
      _hasMedia = false;
      _emit(const PlayerBufferingChanged(false));
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    _ensureReady();
    _player.state = fvp.PlaybackState.playing;
  }

  @override
  Future<void> pause() async {
    _ensureReady();
    _player.state = fvp.PlaybackState.paused;
  }

  @override
  Future<void> stop() async {
    _ensureReady();
    _hasMedia = false;
    _acceptMediaStatus = false;
    _player.state = fvp.PlaybackState.stopped;
    // MDK state requests are asynchronous and are not queued. Do not prepare
    // another episode until the previous media has actually stopped. Poll
    // without blocking the isolate so native callbacks can still be handled.
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!_player.waitFor(fvp.PlaybackState.stopped, timeout: 0)) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('FVP timed out waiting for playback to stop');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      _ensureReady();
    }
    _emitPlayingState();
    // The shared state infers buffering from position and buffered position.
    // Clear both before clearing buffering, otherwise the previous episode's
    // metrics can keep the loading indicator alive during source resolution.
    _emit(const PlayerPositionChanged(Duration.zero));
    _emit(const PlayerBufferedChanged(Duration.zero));
    _emit(const PlayerDurationChanged(Duration.zero));
    _emit(const PlayerBufferingChanged(false));
  }

  @override
  Future<void> seek(Duration position) async {
    _ensureReady();
    final result = await _player.seek(position: position.inMilliseconds);
    if (result < 0) throw StateError('FVP seek failed: $result');
    _emitCurrentMetrics();
  }

  @override
  Future<void> setVolume(double volume) async {
    _ensureReady();
    _player.volume = (volume / 100).clamp(0.0, 1.0);
    _emit(PlayerVolumeChanged(volume.clamp(0.0, 100.0)));
  }

  @override
  Future<void> setRate(double rate) async {
    _ensureReady();
    _player.playbackRate = rate;
    _emit(PlayerRateChanged(rate));
  }

  @override
  Future<Uint8List?> screenshot() async {
    _ensureReady();
    return _player.snapshot();
  }

  @override
  Future<void> setShaders(String shaderList) async {
    throw UnsupportedError('FVP does not support MPV GLSL shader chains');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
    await _events.close();
  }

  void _emitCurrentMetrics() {
    if (!_hasMedia || _disposed) return;
    _emitPlayingState();
    final position = _player.position;
    _emit(PlayerPositionChanged(Duration(milliseconds: position)));

    // FVP's buffered() value is the amount of media buffered after the
    // current position. The shared playback state stores the absolute end
    // position used by the progress bar, so convert it before emitting.
    _emitBufferedPosition(position: position);
    _emitBufferingState();

    final duration = _player.mediaInfo.duration;
    if (duration > 0) {
      _emit(PlayerDurationChanged(Duration(milliseconds: duration)));
    }
  }

  void _emitBufferingState() {
    if (!_acceptMediaStatus || _disposed) return;
    // Native mediaStatus is authoritative; queued callbacks may still describe
    // the previous source or a buffering phase that has already finished.
    final status = _player.mediaStatus;
    final buffering =
        status.test(fvp.MediaStatus.buffering | fvp.MediaStatus.stalled) &&
            !status.test(fvp.MediaStatus.buffered |
                fvp.MediaStatus.end |
                fvp.MediaStatus.unloaded |
                fvp.MediaStatus.invalid);
    _emit(PlayerBufferingChanged(buffering));
  }

  void _emitPlayingState() {
    if (_disposed) return;
    // Player.state is a Dart cache updated by both commands and delayed native
    // callbacks. A zero-timeout waitFor reads the native state, so a late event
    // from the previous episode cannot overwrite the current playback state.
    _emit(PlayerPlayingChanged(
      _player.waitFor(fvp.PlaybackState.playing, timeout: 0),
    ));
  }

  void _emitBufferedPosition({int? position}) {
    if (!_hasMedia || _disposed) return;
    final currentPosition = position ?? _player.position;
    final bufferLength = _player.buffered();
    if (bufferLength < 0) return;

    _emit(PlayerBufferedChanged(
      Duration(milliseconds: currentPosition + bufferLength),
    ));
  }

  void _ensureReady() {
    if (!_initialized || _disposed) {
      throw StateError('FvpEngine is not initialized');
    }
  }

  void _emit(PlayerEvent event) {
    if (!_disposed && !_events.isClosed) _events.add(event);
  }
}
