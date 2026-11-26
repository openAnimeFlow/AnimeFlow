import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_video_surface.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/core/async/serial_operation_queue.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'mpv_upscale_shaders.dart';
import 'media_kit_video_validation.dart';

class MediaKitEngine implements PlayerEngine, PlayerVideoSurface {
  final bool adBlocker;
  final bool hardwareDecoder;
  Player? _player;
  PlaybackSource? _pendingSource;
  final ValueNotifier<VideoController?> _videoController = ValueNotifier(null);
  late final _operations = SerialOperationQueue(ensureReady: _ensureReady);
  double _volume = 100;
  double _rate = 1;
  String _shaderList = '';
  final MpvUpscaleShaders _upscaleShaders;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _initialized = false;
  bool _disposed = false;

  MediaKitEngine({
    required this.adBlocker,
    this.hardwareDecoder = true,
    required Future<Directory> Function() loadShadersDirectory,
  }) : _upscaleShaders = MpvUpscaleShaders(loadShadersDirectory);

  @override
  PlayerKernel get kernel => PlayerKernel.mediaKit;

  @override
  PlayerCapabilities get capabilities => const PlayerCapabilities(
        supportsScreenshot: true,
        supportedUpscalePresets: {
          UpscalePreset.efficiency,
          UpscalePreset.quality,
        },
        supportsHardwareDecoder: true,
      );

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (_disposed) throw StateError('MediaKitEngine is disposed');
    _initialized = true;
  }

  Player _createPlayer() {
    final player =
        Player(configuration: PlayerConfiguration(adBlocker: adBlocker));
    _player = player;
    _videoController.value = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: hardwareDecoder,
        hwdec: hardwareDecoder ? null : 'no',
      ),
    );
    _subscriptions.addAll([
      player.stream.playing.listen(
        (value) => _emit(PlayerPlayingChanged(value)),
      ),
      player.stream.position.listen(
        (value) => _emit(PlayerPositionChanged(value)),
      ),
      player.stream.duration.listen(
        (value) => _emit(PlayerDurationChanged(value)),
      ),
      player.stream.buffer.listen(
        (value) => _emit(PlayerBufferedChanged(value)),
      ),
      player.stream.buffering.listen(
        (value) => _emit(PlayerBufferingChanged(value)),
      ),
      player.stream.volume.listen(
        (value) => _emit(PlayerVolumeChanged(value)),
      ),
      player.stream.rate.listen(
        (value) => _emit(PlayerRateChanged(value)),
      ),
      player.stream.completed.listen((value) {
        if (value) _emit(const PlayerCompleted());
      }),
    ]);
    return player;
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
              // 由 PlaybackCoordinator 统一管理屏幕常亮。
              wakelock: false,
            ),
    );
  }

  @override
  Future<void> createPlayer(PlaybackSource source) => _operations.run(() async {
        await _stop();
        _ensureReady();
        try {
          final player = _createPlayer();
          await player.setVolume(_volume);
          await player.setRate(_rate);
          if (_shaderList.isNotEmpty) await _applyShaders(player, _shaderList);
          _ensureReady();
          _pendingSource = source;
        } catch (_) {
          await _releasePlayer();
          rethrow;
        }
      });

  @override
  Future<void> open({Duration? startPosition, bool autoPlay = false}) =>
      _operations.run(() async {
        final player = _player;
        final source = _pendingSource;
        if (player == null || source == null) {
          throw StateError('MediaKitEngine has no prepared media');
        }
        _pendingSource = null;
        try {
          Future<void> openMedia() => player.open(
                Media(
                  source.uri.toString(),
                  start: startPosition,
                  httpHeaders: source.headers.isEmpty ? null : source.headers,
                ),
                play: false,
              );
          if (source is LocalFilePlaybackSource) {
            await openMediaKitVideo(
              tracks: player.stream.tracks,
              videoParams: player.stream.videoParams,
              open: openMedia,
            );
          } else {
            await openMedia();
          }
          _ensureReady();
          if (autoPlay) await player.play();
        } catch (_) {
          await _releasePlayer();
          _resetPlaybackState();
          rethrow;
        }
      });

  @override
  Future<void> play() => _operations.run(() async => _player?.play());

  @override
  Future<void> pause() => _operations.run(() async => _player?.pause());

  @override
  Future<void> stop() => _operations.run(_stop);

  Future<void> _stop() async {
    final player = _player;
    if (player == null) return;
    await player.stop();
    await _releasePlayer();
    _resetPlaybackState();
  }

  @override
  Future<void> seek(Duration position) =>
      _operations.run(() async => _player?.seek(position));

  @override
  Future<void> setVolume(double volume) => _operations.run(() async {
        final player = _player;
        await player?.setVolume(volume);
        _volume = volume;
        if (player == null) _emit(PlayerVolumeChanged(volume));
      });

  @override
  Future<void> setRate(double rate) => _operations.run(() async {
        final player = _player;
        await player?.setRate(rate);
        _rate = rate;
        if (player == null) _emit(PlayerRateChanged(rate));
      });

  @override
  Future<Uint8List?> screenshot() =>
      _operations.run(() async => _player?.screenshot());

  @override
  Future<void> setUpscalePreset(UpscalePreset preset) =>
      _operations.run(() async {
        final shaderList = await _upscaleShaders.resolve(preset);
        _ensureReady();
        final player = _player;
        if (player != null) await _applyShaders(player, shaderList);
        _shaderList = shaderList;
      });

  @override
  Future<double?> readCacheSpeed() async {
    final player = _player;
    if (_disposed || player == null) return null;
    try {
      final nativePlayer = player.platform as NativePlayer;
      // mpv 已按约一秒窗口计算 B/s，无需再次除以采样间隔。
      final raw = await nativePlayer.getProperty('cache-speed');
      if (_disposed || !identical(player, _player)) return null;
      final speed = double.tryParse(raw);
      return speed != null && speed.isFinite && speed >= 0 ? speed : null;
    } catch (_) {
      // 输入不支持该属性，或读取期间播放器已释放。
      return null;
    }
  }

  Future<void> _applyShaders(Player player, String shaderList) async {
    final nativePlayer = player.platform as NativePlayer;
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
    final player = _player;
    if (player == null) return;
    _player = null;
    _pendingSource = null;
    _videoController.value = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await player.dispose();
  }

  void _resetPlaybackState() {
    _emit(const PlayerPlayingChanged(false));
    _emit(const PlayerPositionChanged(Duration.zero));
    _emit(const PlayerBufferedChanged(Duration.zero));
    _emit(const PlayerDurationChanged(Duration.zero));
    _emit(const PlayerBufferingChanged(false));
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
