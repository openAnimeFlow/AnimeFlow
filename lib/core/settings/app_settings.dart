import 'dart:io';

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';

/// 应用持久化配置的统一访问入口。
abstract final class AppSettings {
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final value = Storage.setting.get(key, defaultValue: defaultValue);
    return value is T ? value : defaultValue;
  }

  static Future<void> setSetting(String key, Object? value) =>
      Storage.setting.put(key, value);

  static Future<void> deleteSetting(String key) => Storage.setting.delete(key);

  static bool get echImageLoading =>
      getSetting<bool>(SettingKey.echImageLoading, defaultValue: true) ?? true;

  static Future<void> setEchImageLoading(bool value) =>
      setSetting(SettingKey.echImageLoading, value);

  static const defaultEchImageHost = 'wsrv.nl';

  static String get echImageHost {
    final host = getSetting<String>(
      SettingKey.echImageHost,
      defaultValue: defaultEchImageHost,
    )?.trim().toLowerCase();
    return host != null && isValidEchImageHost(host)
        ? host
        : defaultEchImageHost;
  }

  static List<String> get echImageFixedIps {
    final saved = getSetting<String>(SettingKey.echImageFixedIp) ?? '';
    return List.unmodifiable(
      parseEchImageFixedIps(saved).where(
        (ip) => InternetAddress.tryParse(ip) != null,
      ),
    );
  }

  static List<String> parseEchImageFixedIps(String value) => value
      .split(RegExp(r'[\s,，;；]+'))
      .map((ip) => ip.trim())
      .where((ip) => ip.isNotEmpty)
      .toSet()
      .toList();

  static bool isValidEchImageHost(String value) {
    final host = value.trim().toLowerCase();
    if (host.isEmpty || host.length > 253) return false;
    final label = RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$');
    return host.split('.').every(
          (part) => part.length <= 63 && label.hasMatch(part),
        );
  }

  static Future<void> setEchImageRoute({
    required String host,
    List<String> fixedIps = const [],
  }) =>
      Storage.setting.putAll({
        SettingKey.echImageHost: host.trim().toLowerCase(),
        SettingKey.echImageFixedIp: fixedIps.join('\n'),
      });

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
  static const double defaultDanmakuStrokeWidth = 1.5;
  static const bool defaultDanmakuColor = true;
  static const bool defaultDanmakuHideScroll = false;
  static const bool defaultDanmakuHideTop = false;
  static const bool defaultDanmakuHideBottom = true;
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
  static String? get danmakuFontFamily =>
      Storage.setting.get(DanmakuKey.danmakuFontFamily) as String?;

  static bool get danmakuMassiveMode =>
      _readBool(DanmakuKey.danmakuMassiveMode, defaultDanmakuMassiveMode);
  static double get danmakuStrokeWidth {
    final value = Storage.setting.get(DanmakuKey.danmakuBorder);
    if (value is bool) {
      // 兼容旧版本的开关配置。
      return value ? defaultDanmakuStrokeWidth : 0.0;
    }
    if (value is num) {
      return value.toDouble().clamp(0.0, 3.0).toDouble();
    }
    return defaultDanmakuStrokeWidth;
  }

  static bool get danmakuColor =>
      _readBool(DanmakuKey.danmakuColor, defaultDanmakuColor);
  static bool get danmakuUseFont => _readBool(DanmakuKey.danmakuUseFont, true);
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
