import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';

/// 应用持久化配置的统一访问入口。
///
/// 各功能的配置都应通过此类访问，避免默认值、类型转换和存储逻辑分散。
abstract final class AppSettings {
  static const bool defaultAutoPlayNext = true;
  static const bool defaultEpisodesProgress = true;
  static const double defaultFastForwardSpeed = 2.0;
  static const bool defaultAdBlocker = false;
  static const int defaultSkipDuration = 85;
  static const bool defaultHardwareDecoder = true;
  static const String defaultPreferredPlayerKernel = 'mediaKit';
  static const bool defaultDanmakuOn = true;
  static const double defaultDanmakuFontSize = 16.0;
  static const double defaultDanmakuArea = 0.25;
  static const double defaultDanmakuOpacity = 1.0;
  static const double defaultDanmakuDuration = 8.0;
  static const double defaultDanmakuLineHeight = 1.6;
  static const int defaultDanmakuFontWeight = 4;
  static const bool defaultDanmakuMassiveMode = false;
  static const bool defaultDanmakuBorder = true;
  static const bool defaultDanmakuColor = true;
  static const bool defaultDanmakuUseSystemFont = false;
  static const bool defaultDanmakuHideScroll = false;
  static const bool defaultDanmakuHideTop = false;
  static const bool defaultDanmakuHideBottom = false;
  static const bool defaultDanmakuPlatformEnabled = true;
  static const String defaultDanmakuChineseMode = 'none';

  static bool get danmakuOn =>
      _readBool(DanmakuKey.danmakuOn, defaultDanmakuOn);

  static Future<void> setDanmakuOn(bool value) =>
      Storage.setting.put(DanmakuKey.danmakuOn, value);

  static double get danmakuFontSize =>
      _readDouble(DanmakuKey.danmakuFontSize, defaultDanmakuFontSize);
  static double get danmakuArea =>
      _readDouble(DanmakuKey.danmakuArea, defaultDanmakuArea);
  static double get danmakuOpacity =>
      _readDouble(DanmakuKey.danmakuOpacity, defaultDanmakuOpacity);
  static double get danmakuDuration =>
      _readDouble(DanmakuKey.danmakuDuration, defaultDanmakuDuration);
  static double get danmakuLineHeight =>
      _readDouble(DanmakuKey.danmakuLineHeight, defaultDanmakuLineHeight);
  static int get danmakuFontWeight =>
      _readInt(DanmakuKey.danmakuFontWeight, defaultDanmakuFontWeight);

  static bool get danmakuMassiveMode =>
      _readBool(DanmakuKey.danmakuMassiveMode, defaultDanmakuMassiveMode);
  static bool get danmakuBorder =>
      _readBool(DanmakuKey.danmakuBorder, defaultDanmakuBorder);
  static bool get danmakuColor =>
      _readBool(DanmakuKey.danmakuColor, defaultDanmakuColor);
  static bool get danmakuUseSystemFont =>
      _readBool(DanmakuKey.danmakuUseSystemFont, defaultDanmakuUseSystemFont);
  static bool get danmakuHideScroll =>
      _readBool(DanmakuKey.danmakuHideScroll, defaultDanmakuHideScroll);
  static bool get danmakuHideTop =>
      _readBool(DanmakuKey.danmakuHideTop, defaultDanmakuHideTop);
  static bool get danmakuHideBottom =>
      _readBool(DanmakuKey.danmakuHideBottom, defaultDanmakuHideBottom);
  static bool get danmakuPlatformBilibili => _readBool(
      DanmakuKey.danmakuPlatformBilibili, defaultDanmakuPlatformEnabled);
  static bool get danmakuPlatformGamer =>
      _readBool(DanmakuKey.danmakuPlatformGamer, defaultDanmakuPlatformEnabled);
  static bool get danmakuPlatformDanDanPlay => _readBool(
        DanmakuKey.danmakuPlatformDanDanPlay,
        defaultDanmakuPlatformEnabled,
      );
  static String get danmakuChineseMode =>
      Storage.setting.get(DanmakuKey.danmakuChineseMode,
          defaultValue: defaultDanmakuChineseMode) as String? ??
      defaultDanmakuChineseMode;

  static Future<void> setDanmakuValue(String key, Object? value) =>
      Storage.setting.put(key, value);

  static Future<void> setDanmakuChineseMode(String value) =>
      setDanmakuValue(DanmakuKey.danmakuChineseMode, value);

  static bool get autoPlayNext => _readBool(
        PlaybackKey.autoPlayNext,
        defaultAutoPlayNext,
      );

  static Future<void> setAutoPlayNext(bool value) =>
      Storage.setting.put(PlaybackKey.autoPlayNext, value);

  static bool get episodesProgress => _readBool(
        PlaybackKey.episodesProgress,
        defaultEpisodesProgress,
      );

  static Future<void> setEpisodesProgress(bool value) =>
      Storage.setting.put(PlaybackKey.episodesProgress, value);

  static double get fastForwardSpeed {
    final value = Storage.setting.get(
      PlaybackKey.fastForwardSpeed,
      defaultValue: defaultFastForwardSpeed,
    );
    return value is num ? value.toDouble() : defaultFastForwardSpeed;
  }

  static Future<void> setFastForwardSpeed(double value) =>
      Storage.setting.put(PlaybackKey.fastForwardSpeed, value);

  static bool get adBlocker => _readBool(
        PlaybackKey.adBlocker,
        defaultAdBlocker,
      );

  static Future<void> setAdBlocker(bool value) =>
      Storage.setting.put(PlaybackKey.adBlocker, value);

  static int get skipDuration => _readInt(
        PlaybackKey.skipDuration,
        defaultSkipDuration,
      );

  static Future<void> setSkipDuration(int value) =>
      Storage.setting.put(PlaybackKey.skipDuration, value);

  static bool get hardwareDecoder => _readBool(
        PlaybackKey.hardwareDecoder,
        defaultHardwareDecoder,
      );

  static Future<void> setHardwareDecoder(bool value) =>
      Storage.setting.put(PlaybackKey.hardwareDecoder, value);

  static String get preferredPlayerKernelName =>
      Storage.setting.get(
        PlaybackKey.preferredPlayerKernel,
        defaultValue: defaultPreferredPlayerKernel,
      ) as String? ??
      defaultPreferredPlayerKernel;

  static Future<void> setPreferredPlayerKernel(String value) =>
      Storage.setting.put(PlaybackKey.preferredPlayerKernel, value);

  static bool _readBool(String key, bool fallback) {
    final value = Storage.setting.get(key, defaultValue: fallback);
    return value is bool ? value : fallback;
  }

  static int _readInt(String key, int fallback) {
    final value = Storage.setting.get(key, defaultValue: fallback);
    return value is num ? value.toInt() : fallback;
  }

  static double _readDouble(String key, double fallback) {
    final value = Storage.setting.get(key, defaultValue: fallback);
    return value is num ? value.toDouble() : fallback;
  }
}
