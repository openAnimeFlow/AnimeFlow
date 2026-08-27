import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// 电池图标
class BatteryIcon extends StatelessWidget {
  final int battery;
  final BatteryState batteryState;
  final double? size;
  /// 旋转角度（度数，0-360）
  final double? angle;

  const BatteryIcon(
      {super.key,
        this.size = 16,
        this.angle,
        required this.battery,
        required this.batteryState});

  @override
  Widget build(BuildContext context) {
    final isCharging = batteryState == BatteryState.charging;

    IconData iconData;
    Color iconColor;

    if (isCharging) {
      // 充电状态
      iconData = Icons.battery_charging_full;
      iconColor = Colors.greenAccent;
    } else {
      // 非充电状态
      if (battery <= 10) {
        iconData = Icons.battery_0_bar;
        iconColor = Colors.redAccent;
      } else if (battery <= 20) {
        iconData = Icons.battery_1_bar;
        iconColor = Colors.orangeAccent;
      } else if (battery <= 50) {
        iconData = Icons.battery_3_bar;
        iconColor = Colors.white;
      } else if (battery <= 80) {
        iconData = Icons.battery_5_bar;
        iconColor = Colors.white;
      } else {
        iconData = Icons.battery_full;
        iconColor = battery >= 90 ? Colors.greenAccent : Colors.white;
      }
    }

    final icon = Icon(iconData, color: iconColor, size: size);

    if (angle != null && angle != 0) {
      return Transform.rotate(
        angle: angle! * 3.141592653589793 / 180, // 将角度转换为弧度
        child: icon,
      );
    }

    return icon;
  }
}


@Preview(
  name: '电池',
  group: 'Battery Icon',
  size: Size(240, 140),
)
Widget batteryChargingPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: BatteryIcon(
          battery: 80,
          batteryState: BatteryState.charging,
          angle: 90,
          size: 64,
        ),
      ),
    ),
  );
}