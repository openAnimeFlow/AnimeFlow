import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/video/controls/bottom_area_control.dart';
import 'package:anime_flow/widget/video/controls/desktop_gesture_detector.dart';
import 'package:anime_flow/widget/video/controls/middle_area_control.dart';
import 'package:anime_flow/widget/video/controls/top_area_control.dart';
import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'mobile_gesture_detector.dart';

///播放器控件
class VideoControlsUiView extends StatefulWidget {
  final SubjectBasicData subjectBasicData;

  const VideoControlsUiView({super.key, required this.subjectBasicData});

  @override
  State<VideoControlsUiView> createState() => _VideoControlsUiViewState();
}

class _VideoControlsUiViewState extends State<VideoControlsUiView> {
  late VideoUiStateController videoUiStateController;
  late PlayController playPageController;
  late VideoStateController videoStateController;
  late EpisodesController episodesController;

  @override
  void initState() {
    videoUiStateController = Get.find<VideoUiStateController>();
    playPageController = Get.find<PlayController>();
    videoStateController = Get.find<VideoStateController>();
    episodesController = Get.find<EpisodesController>();
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
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: TopAreaControl(
          subjectName: widget.subjectBasicData.name,
        ),
      ),

      ///底部
      const Positioned(bottom: 0, left: 0, right: 0, child: BottomAreaControl()),
    ]);
  }
}
