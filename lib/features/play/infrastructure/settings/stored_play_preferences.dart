import 'package:anime_flow/core/settings/player_shortcut_settings.dart';
import 'package:anime_flow/features/play/domain/play_preferences.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage_key.dart';

class StoredPlayPreferences implements PlayPreferences {
  @override
  Set<int> shortcutIds(PlayerShortcutAction action) =>
      action.readBindings().map((binding) => binding.id).toSet();
  @override
  bool get danmakuOn => AppSettings.danmakuOn;
  @override
  double get danmakuFontSize => AppSettings.danmakuFontSize;
  @override
  double get danmakuArea => AppSettings.danmakuArea;
  @override
  double get danmakuOpacity => AppSettings.danmakuOpacity;
  @override
  double get danmakuDuration => AppSettings.danmakuDuration;
  @override
  double get danmakuLineHeight => AppSettings.danmakuLineHeight;
  @override
  int get danmakuFontWeight => AppSettings.danmakuFontWeight;
  @override
  bool get danmakuMassiveMode => AppSettings.danmakuMassiveMode;
  @override
  double get danmakuStrokeWidth => AppSettings.danmakuStrokeWidth;
  @override
  bool get danmakuColor => AppSettings.danmakuColor;
  @override
  bool get danmakuHideScroll => AppSettings.danmakuHideScroll;
  @override
  bool get danmakuHideTop => AppSettings.danmakuHideTop;
  @override
  bool get danmakuHideBottom => AppSettings.danmakuHideBottom;
  @override
  bool get danmakuPlatformBilibili => AppSettings.danmakuPlatformBilibili;
  @override
  bool get danmakuPlatformGamer => AppSettings.danmakuPlatformGamer;
  @override
  bool get danmakuPlatformDanDanPlay => AppSettings.danmakuPlatformDanDanPlay;
  @override
  String get danmakuChineseMode => AppSettings.danmakuChineseMode;
  @override
  double get fastForwardSpeed => AppSettings.fastForwardSpeed;
  @override
  double get shortcutSpeedStep => AppSettings.shortcutSpeedStep;
  @override
  int get shortcutSeekBackwardSeconds =>
      AppSettings.shortcutSeekBackwardSeconds;
  @override
  int get shortcutSeekForwardSeconds => AppSettings.shortcutSeekForwardSeconds;
  @override
  bool get episodesProgress => AppSettings.episodesProgress;
  @override
  bool get adBlocker => AppSettings.adBlocker;
  @override
  int get skipDuration => AppSettings.skipDuration;
  @override
  bool get hardwareDecoder => AppSettings.hardwareDecoder;
  @override
  bool get showMiniProgressBar => AppSettings.showMiniProgressBar;
  @override
  String get preferredPlayerKernelName => AppSettings.preferredPlayerKernelName;
  @override
  Future<void> setHardwareDecoder(bool value) =>
      AppSettings.setHardwareDecoder(value);
  @override
  Future<void> setPreferredPlayerKernel(String value) =>
      AppSettings.setPreferredPlayerKernel(value);
  @override
  Future<void> setDanmakuOn(bool value) => AppSettings.setDanmakuOn(value);
  @override
  Future<void> setDanmakuChineseMode(String value) =>
      AppSettings.setDanmakuChineseMode(value);
  @override
  Future<void> setDanmakuHideScroll(bool value) =>
      AppSettings.setSetting(DanmakuKey.danmakuHideScroll, value);
  @override
  Future<void> setDanmakuHideTop(bool value) =>
      AppSettings.setSetting(DanmakuKey.danmakuHideTop, value);
  @override
  Future<void> setDanmakuHideBottom(bool value) =>
      AppSettings.setSetting(DanmakuKey.danmakuHideBottom, value);
  @override
  Future<void> setDanmakuMassiveMode(bool value) =>
      AppSettings.setSetting(DanmakuKey.danmakuMassiveMode, value);
  @override
  Future<void> setDanmakuFontSize(double value) =>
      AppSettings.setSetting(DanmakuKey.danmakuFontSize, value);
  @override
  Future<void> setDanmakuBorder(double value) =>
      AppSettings.setSetting(DanmakuKey.danmakuBorder, value);
  @override
  Future<void> setDanmakuDuration(double value) =>
      AppSettings.setSetting(DanmakuKey.danmakuDuration, value);
  @override
  Future<void> setDanmakuOpacity(double value) =>
      AppSettings.setSetting(DanmakuKey.danmakuOpacity, value);
  @override
  Future<void> setDanmakuFontWeight(int value) =>
      AppSettings.setSetting(DanmakuKey.danmakuFontWeight, value);
  @override
  Future<void> setDanmakuArea(double value) =>
      AppSettings.setSetting(DanmakuKey.danmakuArea, value);
}
