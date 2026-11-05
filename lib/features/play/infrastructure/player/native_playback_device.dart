import 'package:anime_flow/features/play/domain/playback_device.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/vibrate.dart' as haptic;
import 'package:battery_plus/battery_plus.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class NativePlaybackDevice implements PlaybackDevice {
  @override
  bool get isMobile => SystemUtil.isMobile;
  @override
  bool get isDesktop => SystemUtil.isDesktop;
  @override
  bool get isWindows => Platform.isWindows;
  @override
  String clockTime() => SystemUtil.getCurrentTimeWithoutSeconds();
  @override
  Future<void> enterFullScreen() => SystemUtil.enterFullScreen();
  @override
  Future<void> exitFullScreen() => SystemUtil.exitFullScreen();
  @override
  Future<bool> isFullScreen() => windowManager.isFullScreen();
  @override
  void Function() observeWindow(
      {required void Function() onRestore,
      required void Function(bool) onFullscreen}) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return () {};
    }
    final listener = _WindowEvents(onRestore, onFullscreen);
    windowManager.addListener(listener);
    onRestore();
    return () => windowManager.removeListener(listener);
  }

  @override
  Stream<bool> get chargingChanges => SystemUtil.batteryStateStream
      .map((state) => state == BatteryState.charging);
  @override
  Future<bool> isCharging() async =>
      await SystemUtil.getBatteryState() == BatteryState.charging;
  @override
  Future<int> batteryLevel() => SystemUtil.getBatteryLevel();
  @override
  Future<double> brightness() => ScreenBrightnessPlatform.instance.application;
  @override
  Future<void> setBrightness(double value) =>
      ScreenBrightnessPlatform.instance.setApplicationScreenBrightness(value);
  @override
  Future<void> resetBrightness() =>
      ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
  @override
  Future<void> keepScreenOn(bool enabled) =>
      WakelockPlus.toggle(enable: enabled);
  @override
  Future<String> saveScreenshot(Uint8List bytes) =>
      SystemUtil.saveImageBytes(bytes, name: 'video_screenshot');
  @override
  void vibrateHeavy() => haptic.vibrateHeavy();
  @override
  void vibrateMedium() => haptic.vibrateMedium();
}

class _WindowEvents with WindowListener {
  _WindowEvents(this.restore, this.fullscreen);
  final void Function() restore;
  final void Function(bool) fullscreen;
  @override
  void onWindowRestore() => restore();
  @override
  void onWindowEnterFullScreen() => fullscreen(true);
  @override
  void onWindowLeaveFullScreen() => fullscreen(false);
}
