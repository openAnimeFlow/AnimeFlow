import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/widget/video/controls/index_controls.dart';
import 'package:anime_flow/controllers/video/data/data_source_controller.dart';
import 'package:anime_flow/controllers/video/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoView extends StatefulWidget {
  final SubjectBasicData subjectBasicData;

  const VideoView({super.key, required this.subjectBasicData});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late final player = Player();
  late final controller = VideoController(player);
  late VideoSourceController videoSourceController;
  late VideoUiStateController videoUiStateController;
  late DataSourceController dataSourceController;

  @override
  void initState() {
    super.initState();
    Get.put(VideoStateController(player));
    videoSourceController = Get.find<VideoSourceController>();
    dataSourceController = Get.find<DataSourceController>();
    videoUiStateController = Get.put(VideoUiStateController(player));
    dataSourceController.videoUrl.listen((url) {
      player.open(Media(url));
    });
  }

  @override
  void dispose() {
    Get.delete<VideoUiStateController>();
    Get.delete<VideoStateController>();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Video(
          controller: controller,
          controls: (state) => VideoControlsUiView(
            player,
             subjectBasicData: widget.subjectBasicData,
          ),
        ),
      ],
    );
  }
}
