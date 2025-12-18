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
import 'package:media_kit/media_kit.dart';

import 'mobile_gesture_detector.dart';

///播放器控件
class VideoControlsUiView extends StatefulWidget {
  final SubjectBasicData subjectBasicData;
  final Player player;

  const VideoControlsUiView(this.player, {super.key,  required this.subjectBasicData});

  @override
  State<VideoControlsUiView> createState() => _VideoControlsUiViewState();
}

class _VideoControlsUiViewState extends State<VideoControlsUiView> {
  late VideoUiStateController videoUiStateController;
  late PlayPageController playPageController;
  late VideoStateController videoStateController;
  late EpisodesController episodesController;

  @override
  void initState() {
    videoUiStateController = Get.find<VideoUiStateController>();
    playPageController = Get.find<PlayPageController>();
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
    return Column(children: [
      ///顶部
      TopAreaControl(
        subjectName: widget.subjectBasicData.name,
        playPageController: playPageController,
        videoUiStateController: videoUiStateController,
        episodesController: episodesController,
      ),

      ///中间占满剩余区域
      Expanded(
          child: isMobile
              //移动端手势
              ? MobileGestureDetector(
                  child: MiddleAreaControl(
                  videoUiStateController: videoUiStateController,
                  videoStateController: videoStateController,
                ))
              //桌面端手势
              : DesktopGestureDetector(
                  child: MiddleAreaControl(
                  videoUiStateController: videoUiStateController,
                  videoStateController: videoStateController,
                ))),

      ///底部
      BottomAreaControl(
        videoUiStateController: videoUiStateController,
        videoStateController: videoStateController,
      )
    ]);
  }
}
