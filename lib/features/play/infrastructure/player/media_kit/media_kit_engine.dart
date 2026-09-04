import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';


class MediaKitEngine implements PlayerEngine {
  final bool adBlocker;
  late final Player _player;
  late final VideoController _videoController;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _initialized = false;
  bool _disposed = false;

  MediaKitEngine({required this.adBlocker}) {
    _createPlayer();
  }

  @override
  PlayerKernel get kernel => PlayerKernel.mediaKit;

  @override
  PlayerCapabilities get capabilities => const PlayerCapabilities(
        supportsScreenshot: true,
        supportsShader: true,
        supportsHardwareDecoder: true,
        supportsAudioOnly: true,
      );

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _createPlayer();
  }

  void _createPlayer() {
    if (_initialized) return;
    _player = Player(
      configuration: PlayerConfiguration(adBlocker: adBlocker),
    );
    _videoController = VideoController(_player);
    _subscriptions.addAll([
      _player.stream.playing.listen(
        (value) => _emit(PlayerPlayingChanged(value)),
      ),
      _player.stream.position.listen(
        (value) => _emit(PlayerPositionChanged(value)),
      ),
      _player.stream.duration.listen(
        (value) => _emit(PlayerDurationChanged(value)),
      ),
      _player.stream.buffer.listen(
        (value) => _emit(PlayerBufferedChanged(value)),
      ),
      _player.stream.buffering.listen(
        (value) => _emit(PlayerBufferingChanged(value)),
      ),
      _player.stream.volume.listen(
        (value) => _emit(PlayerVolumeChanged(value)),
      ),
      _player.stream.rate.listen(
        (value) => _emit(PlayerRateChanged(value)),
      ),
      _player.stream.completed.listen((value) {
        if (value) _emit(const PlayerCompleted());
      }),
    ]);
    _initialized = true;
  }

  @override
  Widget buildVideoSurface({required BoxFit fit}) {
    return Video(
      controller: _videoController,
      fit: fit,
      controls: NoVideoControls,
    );
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) async {
    _ensureReady();
    await _player.open(
      Media(
        source.uri.toString(),
        httpHeaders: source.headers.isEmpty ? null : source.headers,
      ),
      play: false,
    );
    if (startPosition != null && startPosition > Duration.zero) {
      await _player.seek(startPosition);
    }
    if (autoPlay) await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<Uint8List?> screenshot() => _player.screenshot();

  @override
  Future<void> setShaders(String shaderList) async {
    _ensureReady();
    final nativePlayer = _player.platform as NativePlayer;
    await nativePlayer.waitForPlayerInitialization;
    await nativePlayer.waitForVideoControllerInitializationIfAttached;
    await nativePlayer.command([
      'change-list',
      'glsl-shaders',
      shaderList.isEmpty ? 'clr' : 'set',
      shaderList,
    ]);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _events.close();
    _player.dispose();
  }

  void _ensureReady() {
    if (!_initialized || _disposed) {
      throw StateError('MediaKitEngine is not initialized');
    }
  }

  void _emit(PlayerEvent event) {
    if (!_disposed && !_events.isClosed) _events.add(event);
  }
}
