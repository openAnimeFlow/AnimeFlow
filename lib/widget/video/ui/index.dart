import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/widget/video/ui/middle_area_control.dart';
import 'package:anime_flow/widget/video/ui/top_area_control.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bottom_area_control.dart';
import 'desktop_gesture_detector.dart';
import 'mobile_gesture_detector.dart';

///播放器ui
class VideoUi extends StatefulWidget {
  const VideoUi({super.key});

  @override
  State<VideoUi> createState() => _VideoUiState();
}

class _VideoUiState extends State<VideoUi> {
  late VideoUiStateController videoUiStateController;
  late PlayController playPageController;
  late VideoStateController videoStateController;
  late EpisodesState episodesController;

  @override
  void initState() {
    videoUiStateController = Get.find<VideoUiStateController>();
    playPageController = Get.find<PlayController>();
    videoStateController = Get.find<VideoStateController>();
    episodesController = Get.find<EpisodesState>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Utils.isMobile;
    return Stack(children: [
      /// 控件事件
      Positioned.fill(
          child: isMobile
              //移动端手势
              ? const MobileGestureDetector(child: MiddleAreaControl())
              //桌面端手势
              : const DesktopGestureDetector(child: MiddleAreaControl())),

      ///顶部
      const Positioned(top: 0, left: 0, right: 0, child: TopAreaControl()),

      ///底部
      const Positioned(bottom: 0, left: 0, right: 0, child: BottomAreaControl())
    ]);
  }
}
