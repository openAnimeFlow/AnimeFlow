import 'package:anime_flow/pages/play/video/gesture/desktop_gesture_detector.dart';
import 'package:anime_flow/pages/play/video/gesture/mobile_gesture_detector.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';

import 'control/bottom_area_control.dart';
import 'control/middle_area_control.dart';
import 'control/right_area_control.dart';
import 'control/top_area_control.dart';

///播放器ui
class VideoUi extends StatelessWidget {
  const VideoUi({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = SystemUtil.isMobile;
    return Stack(
      children: [
        /// 控件事件
        Positioned.fill(
          child: isMobile
              ? const MobileGestureDetector(child: MiddleAreaControl())
              : const DesktopGestureDetector(child: MiddleAreaControl()),
        ),

        ///顶部
        const Positioned(top: 0, left: 0, right: 0, child: TopAreaControl()),

        ///底部
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BottomAreaControl(),
        ),

        ///右侧
        const Positioned(right: 0, top: 0, bottom: 0, child: RightAreaControl()),
      ],
    );
  }
}