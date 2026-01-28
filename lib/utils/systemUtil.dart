import 'package:battery_plus/battery_plus.dart';

/// 系统信息工具类
class SystemUtil {
  static final Battery _battery = Battery();

  /// 获取电池电量（0-100）
  static Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 0;
    }
  }

  /// 获取电池充电状态
  static Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (e) {
      return BatteryState.unknown;
    }
  }

  /// 获取电池状态流（监听电池状态变化）
  static Stream<BatteryState> get batteryStateStream =>
      _battery.onBatteryStateChanged;

  /// 获取当前时间字符串
  /// 返回格式：HH:MM:SS
  static String getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  /// 获取当前时间字符串
  /// 返回格式：HH:MM
  static String getCurrentTimeWithoutSeconds() {
    DateTime now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }
}

