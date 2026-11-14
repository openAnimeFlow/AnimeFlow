import 'dart:typed_data';

abstract interface class PlaybackDevice {
  bool get isMobile;
  bool get isDesktop;
  bool get isWindows;
  String clockTime();
  Future<void> enterFullScreen();
  Future<void> exitFullScreen();
  Future<bool> isFullScreen();
  void Function() observeWindow(
      {required void Function() onRestore,
      required void Function(bool) onFullscreen});
  Stream<bool> get chargingChanges;
  Future<bool> isCharging();
  Future<int> batteryLevel();
  Future<double> brightness();
  Future<void> setBrightness(double value);
  Future<void> resetBrightness();
  Future<void> keepScreenOn(bool enabled);
  Future<String> saveScreenshot(Uint8List bytes);
  void vibrateHeavy();
  void vibrateMedium();
}
