import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_operation_queue.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitEngine implements PlayerEngine {
  final bool adBlocker;
  late Player _player;
  final ValueNotifier<VideoController?> _videoController = ValueNotifier(null);
  final Player Function() _playerFactory;
  final VideoController Function(Player) _controllerFactory;
  late final _operations = PlayerOperationQueue(ensureReady: _ensureReady);
  bool _opened = false;
  bool _released = true;
  double _volume = 100;
  double _rate = 1;
  String _shaders = '';
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _initialized = false;
  bool _disposed = false;

  MediaKitEngine({
    required this.adBlocker,
    bool hardwareDecoder = true,
    Player Function()? playerFactory,
    VideoController Function(Player)? controllerFactory,
  })  : _playerFactory = playerFactory ??
            (() => Player(
                configuration: PlayerConfiguration(adBlocker: adBlocker))),
        _controllerFactory = controllerFactory ??
            ((player) => VideoController(
                  player,
                  configuration: VideoControllerConfiguration(
                    enableHardwareAcceleration: hardwareDecoder,
                    hwdec: hardwareDecoder ? null : 'no',
                  ),
                )) {
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
    _player = _playerFactory();
    _released = false;
    _videoController.value = _controllerFactory(_player);
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
    return ValueListenableBuilder<VideoController?>(
      valueListenable: _videoController,
      builder: (context, controller, child) => controller == null
          ? const ColoredBox(color: Colors.black, child: SizedBox.expand())
          : Video(
              key: ObjectKey(controller),
              controller: controller,
              fit: fit,
              controls: NoVideoControls,
            ),
    );
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) =>
      _enqueue(() async {
        if (_opened) {
          await _releasePlayer();
          _ensureReady();
          _createPlayer();
          await _player.setVolume(_volume);
          await _player.setRate(_rate);
          if (_shaders.isNotEmpty) await _applyShaders(_shaders);
        }
        _opened = true;
        _ensureReady();
        await _player.open(
          Media(
            source.uri.toString(),
            start: startPosition,
            httpHeaders: source.headers.isEmpty ? null : source.headers,
          ),
          play: false,
        );
        _ensureReady();
        if (autoPlay) await _player.play();
      });

  @override
  Future<void> play() => _enqueue(() => _player.play());

  @override
  Future<void> pause() => _enqueue(() => _player.pause());

  @override
  Future<void> stop() => _enqueue(() => _player.stop());

  @override
  Future<void> seek(Duration position) =>
      _enqueue(() => _player.seek(position));

  @override
  Future<void> setVolume(double volume) => _enqueue(() async {
        await _player.setVolume(volume);
        _volume = volume;
      });

  @override
  Future<void> setRate(double rate) => _enqueue(() async {
        await _player.setRate(rate);
        _rate = rate;
      });

  @override
  Future<Uint8List?> screenshot() => _enqueue(() => _player.screenshot());

  @override
  Future<void> setShaders(String shaderList) => _enqueue(() async {
        await _applyShaders(shaderList);
        _shaders = shaderList;
      });

  Future<void> _applyShaders(String shaderList) async {
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
    await _operations.drained;
    await _releasePlayer();
    _videoController.dispose();
    await _events.close();
  }

  Future<void> _releasePlayer() async {
    if (_released) return;
    _released = true;
    _videoController.value = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _player.dispose();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) =>
      _operations.run(operation);

  void _ensureReady() {
    if (!_initialized || _disposed) {
      throw StateError('MediaKitEngine is not initialized');
    }
  }

  void _emit(PlayerEvent event) {
    if (!_disposed && !_events.isClosed) _events.add(event);
  }
}
