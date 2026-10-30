import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/async/serial_operation_queue.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_video_surface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerEngine implements PlayerEngine, PlayerVideoSurface {
  late final _events = StreamController<PlayerEvent>.broadcast(onListen: () {
    _lastValue = null;
    _onChanged();
  });
  final _controller = ValueNotifier<VideoPlayerController?>(null);
  late final _operations = SerialOperationQueue(ensureReady: _ensureReady);
  bool _initialized = false;
  bool _disposed = false;
  bool _completed = false;
  String? _lastError;
  VideoPlayerValue? _lastValue;
  double _volume = 1;
  double _rate = 1;

  @override
  PlayerKernel get kernel => PlayerKernel.videoPlayer;
  @override
  PlayerCapabilities get capabilities => const PlayerCapabilities();
  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (_disposed) throw StateError('VideoPlayerEngine is disposed');
    _initialized = true;
  }

  @override
  Widget buildVideoSurface({required BoxFit fit}) => ColoredBox(
        color: Colors.black,
        child: ValueListenableBuilder<VideoPlayerController?>(
          valueListenable: _controller,
          builder: (context, controller, _) {
            if (controller == null) return const SizedBox.expand();
            return ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (!value.isInitialized || value.size.isEmpty) {
                  return const SizedBox.expand();
                }
                return SizedBox.expand(
                  child: FittedBox(
                    fit: fit,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: value.size.width,
                      height: value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );

  @override
  Future<void> open(PlaybackSource source,
          {Duration? startPosition, bool autoPlay = false}) =>
      _operations.run(() async {
        await _release();
        _ensureReady();
        _resetState();
        final headers = <String, String>{
          ...source.headers,
          if (source.referer != null) 'Referer': source.referer!,
          if (source.userAgent != null) 'User-Agent': source.userAgent!,
        };
        final options = VideoPlayerOptions(
          preventsDisplaySleepDuringVideoPlayback: false,
          // ExoPlayer 保留近期播放过的媒体数据，供向后跳转时复用。
          // 不支持控制回退缓冲的平台会忽略此选项。
          backBufferDurationMs: 60 * 1000,
        );
        final controller = source.isLocal || source.uri.isScheme('file')
            ? VideoPlayerController.file(File(source.uri.toFilePath()),
                videoPlayerOptions: options)
            : VideoPlayerController.networkUrl(source.uri,
                httpHeaders: headers, videoPlayerOptions: options);
        _controller.value = controller;
        controller.addListener(_onChanged);
        try {
          await controller.initialize();
          _ensureReady();
          await controller.setVolume(_volume);
          await controller.setPlaybackSpeed(_rate);
          if (startPosition != null && startPosition > Duration.zero) {
            await controller.seekTo(startPosition);
          }
          if (autoPlay) await controller.play();
        } catch (_) {
          await _release();
          rethrow;
        }
      });

  @override
  Future<void> play() => _operations.run(() async => _controller.value?.play());
  @override
  Future<void> pause() =>
      _operations.run(() async => _controller.value?.pause());
  @override
  Future<void> stop() => _operations.run(() async {
        await _release();
        _resetState();
      });
  @override
  Future<void> seek(Duration position) => _operations.run(() async {
        _completed = false;
        await _controller.value?.seekTo(position);
      });
  @override
  Future<void> setVolume(double volume) => _operations.run(() async {
        _volume = (volume / 100).clamp(0.0, 1.0);
        await _controller.value?.setVolume(_volume);
        _emit(PlayerVolumeChanged(_volume * 100));
      });
  @override
  Future<void> setRate(double rate) => _operations.run(() async {
        _rate = rate;
        await _controller.value?.setPlaybackSpeed(rate);
        _emit(PlayerRateChanged(rate));
      });
  @override
  Future<Uint8List?> screenshot() async => null;
  @override
  Future<void> setShaders(String shaderList) async =>
      throw UnsupportedError('Video Player does not support MPV shaders');
  @override
  Future<double?> readCacheSpeed() async => null;

  void _onChanged() {
    final value = _controller.value?.value;
    if (value == null || _disposed) return;
    final previous = _lastValue;
    _lastValue = value;
    if (previous == null || previous.isPlaying != value.isPlaying) {
      _emit(PlayerPlayingChanged(value.isPlaying));
    }
    if (previous == null || previous.position != value.position) {
      _emit(PlayerPositionChanged(value.position));
    }
    if (previous == null || previous.duration != value.duration) {
      _emit(PlayerDurationChanged(value.duration));
    }
    var buffered = Duration.zero;
    for (final range in value.buffered) {
      if (range.start <= value.position && range.end > buffered) {
        buffered = range.end;
      }
    }
    _emit(PlayerBufferedChanged(buffered));
    if (previous == null || previous.isBuffering != value.isBuffering) {
      _emit(PlayerBufferingChanged(value.isBuffering));
    }
    if (value.isCompleted && !_completed) {
      _completed = true;
      _emit(const PlayerCompleted());
    } else if (!value.isCompleted) {
      _completed = false;
    }
    if (value.hasError && value.errorDescription != _lastError) {
      _lastError = value.errorDescription;
      _emit(PlayerError(
          StateError(value.errorDescription ?? 'Video playback failed')));
    }
  }

  void _resetState() {
    _completed = false;
    _lastError = null;
    _lastValue = null;
    _emit(const PlayerPlayingChanged(false));
    _emit(const PlayerPositionChanged(Duration.zero));
    _emit(const PlayerBufferedChanged(Duration.zero));
    _emit(const PlayerDurationChanged(Duration.zero));
    _emit(const PlayerBufferingChanged(false));
  }

  Future<void> _release() async {
    final controller = _controller.value;
    if (controller == null) return;
    controller.removeListener(_onChanged);
    _controller.value = null;
    await controller.dispose();
  }

  void _ensureReady() {
    if (!_initialized || _disposed) {
      throw StateError('VideoPlayerEngine is not initialized');
    }
  }

  void _emit(PlayerEvent event) {
    if (!_disposed && !_events.isClosed) _events.add(event);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _operations.drained;
    await _release();
    _controller.dispose();
    await _events.close();
  }
}
