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

  /// 为新媒体创建底层播放器，并应用已保存的播放设置。
  /// 若实例仍持有旧媒体，先停止并释放旧资源。
  Future<void> createPlayer(PlaybackSource source);

  /// 打开上一次 [createPlayer] 绑定的媒体。
  Future<void> open({Duration? startPosition, bool autoPlay = false});
  Future<void> play();
  Future<void> pause();

  /// 停止当前媒体并释放底层播放器和渲染资源。可在没有媒体时调用。
  /// 引擎及其播放设置保留，供下一次 [createPlayer] 使用。
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setRate(double rate);
  Future<Uint8List?> screenshot();

  /// 应用超分档位，并在后续创建底层播放器时恢复。
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
