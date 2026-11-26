import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/video_validation_exception.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_video_surface.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/serial_operation_queue.dart';
import 'package:fvp/mdk.dart' as fvp;
import 'package:material_ui/material_ui.dart';

/// FVP backend player adapter.
///
/// This intentionally uses the backend API instead of fvp.registerWith(), so
/// MediaKit and FVP can coexist as explicitly selected engines.
class FvpEngine implements PlayerEngine, PlayerVideoSurface {
  FvpEngine({this.hardwareDecoder = true});

  final bool hardwareDecoder;

  // FVP defaults to a 4-second undecoded packet buffer. On longer videos that is
  // only a few pixels on the progress bar, so keep a visible, practical
  // buffer for on-demand playback.
  static const int _bufferRangeMinMilliseconds = 1000;
  static const int _bufferRangeMaxMilliseconds = 60 * 1000;

  // 与待解码队列分开：保留已读取的数据包，供向后跳转复用。
  // 这是可缓存区间的数量，不是秒数；MDK 按 LRU 淘汰旧区间。
  static const int _demuxCacheRanges = 8;

  fvp.Player? _player;
  PlaybackSource? _pendingSource;
  final ValueNotifier<int?> _textureId = ValueNotifier<int?>(null);
  double _volume = 1;
  double _rate = 1;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _pollTimer;
  bool _initialized = false;
  bool _disposed = false;
  bool _hasMedia = false;
  bool _acceptMediaStatus = false;
  bool _completionEmitted = false;
  Size? _videoSize;
  late final _operations = SerialOperationQueue(ensureReady: _ensureReady);

  @override
  PlayerKernel get kernel => PlayerKernel.fvp;

  @override
  PlayerCapabilities get capabilities => const PlayerCapabilities(
        supportsScreenshot: true,
        supportsHardwareDecoder: true,
      );

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (_disposed) throw StateError('FvpEngine is disposed');
    if (_initialized) return;
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _emitCurrentMetrics(),
    );
    _initialized = true;
  }

  void _createPlayer() {
    final player = _FvpPlayer();
    _player = player;
    player.setProperty('demux.buffer.ranges', '$_demuxCacheRanges');
    // Follow FVP 0.38.1's platform priorities with software fallback.
    player.videoDecoders = [
      if (hardwareDecoder) ..._preferredDecoders(),
      'FFmpeg',
      'dav1d',
    ];
    player.volume = _volume;
    player.playbackRate = _rate;
    player.textureId.addListener(_updateTextureId);
    player.setBufferRange(
      min: _bufferRangeMinMilliseconds,
      max: _bufferRangeMaxMilliseconds,
    );
    _subscriptions.addAll([
      player.onStateChanged.listen((change) {
        _emitPlayingState();
        // MediaStatus.end only means EOF was read; buffered frames may still
        // be playing. Complete only after native playback has actually stopped.
        // _stop clears _hasMedia before requesting a stop, excluding commands.
        if (!_disposed &&
            _hasMedia &&
            !_completionEmitted &&
            change.newValue == fvp.PlaybackState.stopped &&
            player.waitFor(fvp.PlaybackState.stopped, timeout: 0) &&
            player.mediaStatus.test(fvp.MediaStatus.end)) {
          _completionEmitted = true;
          _emit(const PlayerCompleted());
        }
      }),
      player.onMediaStatus.listen((_) {
        if (!_acceptMediaStatus) return;
        _emitBufferingState();
      }),
      player.onEvent.listen((event) {
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

        if (event.category == 'cache.ranges') {
          // error 字段在这里是缓存区间数量，不是播放错误。
          _emitBufferedPosition();
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
  }

  void _updateTextureId() => _textureId.value = _player?.textureId.value;

  List<String> _preferredDecoders() {
    if (Platform.isLinux) {
      if (File('/dev/mpp_service').existsSync()) {
        return const ['rockchip', 'rkmpp'];
      }
      if (File('/dev/vchiq').existsSync()) {
        return const ['V4L2M2M', 'FFmpeg:hwcontext=drm'];
      }
      return const ['VAAPI', 'CUDA', 'VDPAU', 'hap'];
    }
    return switch (Platform.operatingSystem) {
      'windows' => const ['MFT:d3d=11', 'D3D11', 'DXVA', 'CUDA', 'hap'],
      'macos' => const ['VT', 'hap'],
      'ios' => const ['VT'],
      'android' => const ['AMediaCodec'],
      'ohos' => const ['OH'],
      _ => const [],
    };
  }

  Future<void> _releasePlayer() async {
    final player = _player;
    if (player == null) return;
    _player = null;
    _pendingSource = null;
    _hasMedia = false;
    _acceptMediaStatus = false;
    _videoSize = null;
    player.textureId.removeListener(_updateTextureId);
    _textureId.value = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    // FVP 声明为 async void，Future.sync 等待实际返回的异步销毁结果。
    await Future<void>.sync(player.dispose);
  }

  @override
  Widget buildVideoSurface({required BoxFit fit}) {
    _ensureReady();
    return ColoredBox(
      color: Colors.black,
      child: ValueListenableBuilder<int?>(
        valueListenable: _textureId,
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
  Future<void> createPlayer(PlaybackSource source) => _operations.run(() async {
        await _stop();
        _ensureReady();
        try {
          _createPlayer();
          _pendingSource = source;
        } catch (_) {
          await _releasePlayer();
          rethrow;
        }
      });

  @override
  Future<void> open({Duration? startPosition, bool autoPlay = false}) =>
      _operations
          .run(() => _open(startPosition: startPosition, autoPlay: autoPlay));

  Future<void> _open({Duration? startPosition, required bool autoPlay}) async {
    final player = _player;
    final source = _pendingSource;
    if (player == null || source == null) {
      throw StateError('FvpEngine has no prepared media');
    }
    _pendingSource = null;
    _completionEmitted = false;
    try {
      final headers = <String, String>{
        ...source.headers,
        if (source.referer != null) 'Referer': source.referer!,
      };
      if (headers.isNotEmpty) {
        player.setProperty(
          'avio.headers',
          headers.entries
              .map((entry) => '${entry.key}: ${entry.value}\r\n')
              .join(),
        );
      }
      if (source.userAgent != null) {
        player.setProperty('avio.user_agent', source.userAgent!);
      }
      _acceptMediaStatus = true;
      player.media = switch (source) {
        LocalFilePlaybackSource(:final path) => path,
        NetworkPlaybackSource(:final uri) => uri.toString(),
      };
      final requestedPosition = startPosition?.inMilliseconds ?? 0;
      final isLocalVideo = source is LocalFilePlaybackSource;
      final preparation = player.prepare(
        // MDK prepare(0) 只保证元数据就绪；正数位置会等待首帧解码结果。
        // 本地视频从 1ms 预加载，避免把仅能解封装误判为可解码。
        position:
            isLocalVideo && requestedPosition == 0 ? 1 : requestedPosition,
        // 默认 flags 包含 KeyFrame，会向前跳到关键帧，导致重建时进度漂移。
        flags: const fvp.SeekFlag(fvp.SeekFlag.fromStart),
      );
      final result = isLocalVideo
          ? await preparation.timeout(VideoValidationException.timeout,
              onTimeout: () => throw const VideoValidationException.timedOut())
          : await preparation;
      _ensureReady();
      if (result < 0) {
        throw StateError('FVP prepare failed: $result');
      }
      final video = player.mediaInfo.video?.firstOrNull;
      if (isLocalVideo &&
          (video == null ||
              video.codec.width <= 0 ||
              video.codec.height <= 0)) {
        throw const VideoValidationException.noVideo();
      }
      if (video != null) {
        _videoSize = Size(
          video.codec.width.toDouble(),
          video.codec.height.toDouble(),
        );
      }
      // Set geometry before updateTexture notifies the video surface.
      final texture = await player.updateTexture();
      _ensureReady();
      if (texture < 0) {
        throw StateError('FVP video texture creation failed: $texture');
      }
      _hasMedia = true;
      _emitCurrentMetrics();
      if (autoPlay) player.state = fvp.PlaybackState.playing;
    } catch (_) {
      await _releasePlayer();
      _resetPlaybackState();
      rethrow;
    }
  }

  @override
  Future<void> play() => _operations.run(() async {
        _player?.state = fvp.PlaybackState.playing;
      });

  @override
  Future<void> pause() => _operations.run(() async {
        _player?.state = fvp.PlaybackState.paused;
      });

  @override
  Future<void> stop() => _operations.run(_stop);

  Future<void> _stop() async {
    final player = _player;
    if (player == null) return;
    _hasMedia = false;
    _acceptMediaStatus = false;
    player.state = fvp.PlaybackState.stopped;
    // MDK state requests are asynchronous and are not queued. Do not prepare
    // another episode until the previous media has actually stopped. Poll
    // without blocking the isolate so native callbacks can still be handled.
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!player.waitFor(fvp.PlaybackState.stopped, timeout: 0)) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('FVP timed out waiting for playback to stop');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      _ensureReady();
    }
    await _releasePlayer();
    _resetPlaybackState();
  }

  void _resetPlaybackState() {
    _emit(const PlayerPlayingChanged(false));
    // The shared state infers buffering from position and buffered position.
    // Clear both before clearing buffering, otherwise the previous episode's
    // metrics can keep the loading indicator alive during source resolution.
    _emit(const PlayerPositionChanged(Duration.zero));
    _emit(const PlayerBufferedChanged(Duration.zero));
    _emit(const PlayerDurationChanged(Duration.zero));
    _emit(const PlayerBufferingChanged(false));
  }

  /// 精确跳转到指定位置，并优先复用已有缓冲。
  @override
  Future<void> seek(Duration position) => _operations.run(() async {
        final player = _player;
        if (player == null) return;
        final result = await player.seek(
          position: position.inMilliseconds,
          flags: const fvp.SeekFlag(
            fvp.SeekFlag.fromStart | fvp.SeekFlag.inCache,
          ),
        );
        _ensureReady();
        if (result < 0) throw StateError('FVP seek failed: $result');
        _completionEmitted = false;
        _emitCurrentMetrics();
      });

  @override
  Future<void> setVolume(double volume) => _operations.run(() async {
        _volume = (volume / 100).clamp(0.0, 1.0);
        _player?.volume = _volume;
        _emit(PlayerVolumeChanged(volume.clamp(0.0, 100.0)));
      });

  @override
  Future<void> setRate(double rate) => _operations.run(() async {
        _rate = rate;
        _player?.playbackRate = _rate;
        _emit(PlayerRateChanged(rate));
      });

  @override
  Future<Uint8List?> screenshot() =>
      _operations.run(() async => _player?.snapshot());

  @override
  Future<void> setUpscalePreset(UpscalePreset preset) async {
    _ensureReady();
    if (!capabilities.supportsUpscalePreset(preset)) {
      throw UnsupportedError('FVP does not support upscaling');
    }
  }

  @override
  Future<double?> readCacheSpeed() async => null;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    // A pending platform texture operation must finish before native disposal.
    await _operations.drained;
    await _releasePlayer();
    _textureId.dispose();
    await _events.close();
  }

  void _emitCurrentMetrics() {
    final player = _player;
    if (player == null || !_hasMedia || _disposed) return;
    _emitPlayingState();
    final position = player.position;
    _emit(PlayerPositionChanged(Duration(milliseconds: position)));

    // 同时考虑待解码队列和可回退缓存，报告当前位置之后连续可用的末端。
    _emitBufferedPosition(position: position);
    _emitBufferingState();

    final duration = player.mediaInfo.duration;
    if (duration > 0) {
      _emit(PlayerDurationChanged(Duration(milliseconds: duration)));
    }
  }

  void _emitBufferingState() {
    final player = _player;
    if (player == null || !_acceptMediaStatus || _disposed) return;
    // Native mediaStatus is authoritative; queued callbacks may still describe
    // the previous source or a buffering phase that has already finished.
    final status = player.mediaStatus;
    final buffering =
        status.test(fvp.MediaStatus.buffering | fvp.MediaStatus.stalled) &&
            !status.test(fvp.MediaStatus.buffered |
                fvp.MediaStatus.end |
                fvp.MediaStatus.unloaded |
                fvp.MediaStatus.invalid);
    _emit(PlayerBufferingChanged(buffering));
  }

  void _emitPlayingState() {
    final player = _player;
    if (player == null || _disposed) return;
    // Player.state is a Dart cache updated by both commands and delayed native
    // callbacks. A zero-timeout waitFor reads the native state, so a late event
    // from the previous episode cannot overwrite the current playback state.
    _emit(PlayerPlayingChanged(
      player.waitFor(fvp.PlaybackState.playing, timeout: 0),
    ));
  }

  void _emitBufferedPosition({int? position}) {
    final player = _player;
    if (player == null || !_hasMedia || _disposed) return;
    final currentPosition = position ?? player.position;
    final bufferLength = player.buffered();
    final ranges = player.bufferedTimeRanges()
      ..sort((a, b) => a.start.compareTo(b.start));
    if (bufferLength < 0 && ranges.isEmpty) return;

    var bufferedEnd = Duration(
      milliseconds: currentPosition + (bufferLength > 0 ? bufferLength : 0),
    );
    for (final range in ranges) {
      // 不能用所有区间的最大终点：跳转形成的空隙仍然需要下载。
      if (range.start > bufferedEnd) break;
      if (range.end > bufferedEnd) bufferedEnd = range.end;
    }

    _emit(PlayerBufferedChanged(bufferedEnd));
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

class _FvpPlayer extends fvp.Player {
  @override
  Future<int> updateTexture(
      {int? width, int? height, bool? tunnel, bool? fit}) {
    // 销毁时若尚未创建纹理，无需等待首帧尺寸。打开失败时尺寸可能一直未就绪。
    if (width == -1 && (textureId.value ?? -1) < 0) return Future.value(-1);
    return super
        .updateTexture(width: width, height: height, tunnel: tunnel, fit: fit);
  }
}
