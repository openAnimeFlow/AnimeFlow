import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// iOS 风格的电池图标。
///
/// [batteryLevel] 使用 0 至 100 的百分比，并在电池主体中间显示。
class IosBatteryIcon extends StatelessWidget {
  const IosBatteryIcon({
    super.key,
    required this.batteryLevel,
    this.width = 56,
    this.borderColor = const Color(0xFF9E9E9E),
    this.levelColor = const Color(0xFF34C759),
    this.levelTextColor = const Color(0xFF1A1A1A),
  });

  /// 电量百分比，超出范围的值会被限制在 0 至 100。
  final num batteryLevel;

  /// 图标总宽度（包含右侧电池头）。
  final double width;
  final Color borderColor;
  final Color levelColor;

  /// 电池主体中间的电量文字颜色。
  final Color levelTextColor;

  @override
  Widget build(BuildContext context) {
    final iconWidth = math.max(1.0, width);
    final level = (batteryLevel.clamp(0, 100)).toDouble() / 100;

    return Semantics(
      label: '电量 ${batteryLevel.clamp(0, 100)}%',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(iconWidth, iconWidth * _IosBatteryPainter.aspectRatio),
          painter: _IosBatteryPainter(
            level: level,
            borderColor: borderColor,
            levelColor: levelColor,
            levelTextColor: levelTextColor,
            levelText: '${batteryLevel.clamp(0, 100)}',
          ),
        ),
      ),
    );
  }
}

class _IosBatteryPainter extends CustomPainter {
  const _IosBatteryPainter({
    required this.level,
    required this.borderColor,
    required this.levelColor,
    required this.levelTextColor,
    required this.levelText,
  });

  static const aspectRatio = 0.5;

  final double level;
  final Color borderColor;
  final Color levelColor;
  final Color levelTextColor;
  final String levelText;

  @override
  void paint(Canvas canvas, Size size) {
    // 主体预留右侧电池头的位置；坐标均按宽度比例计算，任意尺寸下比例一致。
    final bodyRect = Rect.fromLTWH(
      size.width * .03,
      size.height * .12,
      size.width * .82,
      size.height * .76,
    );
    final strokeWidth = size.width * .035;
    final bodyRadius = bodyRect.height * .38;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyRadius)),
      borderPaint,
    );

    // 电池头
    final terminal = Path()
      ..moveTo(size.width * .88, size.height * .40)
      ..cubicTo(
        size.width * .896,
        size.height * .42,
        size.width * .912,
        size.height * .46,
        size.width * .912,
        size.height * .50,
      )
      ..cubicTo(
        size.width * .912,
        size.height * .54,
        size.width * .896,
        size.height * .58,
        size.width * .88,
        size.height * .60,
      )
      ..close();
    canvas.drawPath(terminal, Paint()..color = borderColor);

    // 先跨过描边的一半，再额外向内缩进 gap，确保绿色电量不会碰到灰色外框。
    final frameGap = size.width * .025;
    final contentInset = strokeWidth / 2 + frameGap;
    final contentRect = bodyRect.deflate(contentInset);
    final contentRadius = math.max(0.0, contentRect.height * .30);
    final contentShape = RRect.fromRectAndRadius(
      contentRect,
      Radius.circular(contentRadius),
    );

    canvas.save();
    canvas.clipRRect(contentShape);
    if (level > 0) {
      final fillRect = Rect.fromLTWH(
        contentRect.left,
        contentRect.top,
        contentRect.width * level,
        contentRect.height,
      );
      // 未满电时，右侧的电量末端也保持轻微圆角。
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          fillRect,
          Radius.circular(contentRect.height * .10),
        ),
        Paint()..color = levelColor,
      );
    }
    canvas.restore();

    final textPainter = TextPainter(
      text: TextSpan(
        text: levelText,
        style: TextStyle(
          color: levelTextColor,
          fontSize: size.height * .50,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: contentRect.width);
    textPainter.paint(
      canvas,
      Offset(
        bodyRect.center.dx - textPainter.width / 2,
        bodyRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _IosBatteryPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.levelColor != levelColor ||
        oldDelegate.levelTextColor != levelTextColor ||
        oldDelegate.levelText != levelText;
  }
}

@Preview(
  name: '低电量',
  group: 'iOS Battery Icon',
  size: Size(240, 140),
)
Widget iosBatteryLowPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: IosBatteryIcon(
          levelColor: Colors.redAccent,
          batteryLevel: 80,
          width: 120,
        ),
      ),
    ),
  );
}

@Preview(
  name: '满电',
  group: 'iOS Battery Icon',
  size: Size(240, 140),
)
Widget iosBatteryFullPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: IosBatteryIcon(
          batteryLevel: 90,
          width: 120,
        ),
      ),
    ),
  );
}

@Preview(
  name: '充电中',
  group: 'iOS Battery Icon',
  size: Size(240, 140),
)
Widget iosBatteryChargingPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: IosBatteryIcon(
          batteryLevel: 80,
          width: 120,
        ),
      ),
    ),
  );
}
