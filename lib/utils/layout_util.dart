import 'package:flutter/cupertino.dart';

class LayoutUtil {
  static int getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 6; // 大屏幕
    } else if (width > 900) {
      return 5; // 中大屏幕
    } else if (width > 600) {
      return 4; // 平板
    } else if (width > 400) {
      return 3; // 较大手机屏
    } else {
      return 3; // 较小手机屏
    }
  }
}