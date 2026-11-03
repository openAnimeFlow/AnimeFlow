import 'dart:typed_data';

import 'player_capabilities.dart';
import 'player_event.dart';
import 'player_kernel.dart';
import 'playback_source.dart';
import 'upscale_preset.dart';

abstract interface class PlayerEngine {
  PlayerKernel get kernel;
  PlayerCapabilities get capabilities;
  Stream<PlayerEvent> get events;

  Future<void> initialize();
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setRate(double rate);
  Future<Uint8List?> screenshot();

  /// 应用超分档位，并在后续 open 重建底层播放器时恢复。
  /// 所有内核均须接受 off；不支持的启用档位应抛出 UnsupportedError。
  Future<void> setUpscalePreset(UpscalePreset preset);

  /// 当前媒体输入速度（B/s）；内核不支持或数据不可用时返回 null。
  Future<double?> readCacheSpeed();

  Future<void> dispose();
}

/// Injects engine creation without requiring a separate factory class.
typedef PlayerEngineFactory = PlayerEngine Function(
  PlayerKernel kernel, {
  required bool adBlocker,
  required bool hardwareDecoder,
});
