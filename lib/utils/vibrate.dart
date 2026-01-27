import 'package:flutter/services.dart';

/// 轻量级触觉震动
void vibrateLight() {
  HapticFeedback.lightImpact();
}

/// 中量级触觉震动
void vibrateMedium() {
  HapticFeedback.mediumImpact();
}

/// 重量级触觉震动
void vibrateHeavy() {
  HapticFeedback.heavyImpact();
}

/// 点击触觉震动
void vibrateClick() {
  HapticFeedback.selectionClick();
}
