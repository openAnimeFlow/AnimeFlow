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
  late final fvp.Player _player;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _pollTimer;
  bool _initialized = false;
  bool _disposed = false;
  bool _hasMedia = false;
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
    _player = fvp.Player();
    _subscriptions.addAll([
      _player.onStateChanged.listen((change) {
        final state = change.newValue;
        _emit(PlayerPlayingChanged(state == fvp.PlaybackState.playing));
      }),
      _player.onMediaStatus.listen((change) {
        final status = change.newValue;
        _emit(PlayerBufferingChanged(status.test(fvp.MediaStatus.buffering)));
        if (status.test(fvp.MediaStatus.end)) {
          _emit(const PlayerCompleted());
        }
      }),
      _player.onEvent.listen((event) {
        if (event.error != 0) {
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
    return ValueListenableBuilder<int?>(
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
        return FittedBox(
          fit: fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: video,
          ),
        );
      },
    );
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) async {
    _ensureReady();
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
    _player.state = fvp.PlaybackState.stopped;
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
    _emit(PlayerPositionChanged(
      Duration(milliseconds: _player.position),
    ));
    final duration = _player.mediaInfo.duration;
    if (duration > 0) {
      _emit(PlayerDurationChanged(Duration(milliseconds: duration)));
    }
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
