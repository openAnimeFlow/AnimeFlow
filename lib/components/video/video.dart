import 'package:anime_flow/components/video/controls/index_controls.dart';
import 'package:anime_flow/controllers/video/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoView extends StatefulWidget {
  final Subject subject;

  const VideoView({super.key, required this.subject});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late final player = Player();
  late final controller = VideoController(player);
  late VideoSourceController videoSourceController;
  late VideoUiStateController videoUiStateController;

  @override
  void initState() {
    super.initState();
    videoSourceController = Get.find<VideoSourceController>();
    videoUiStateController = Get.put(VideoUiStateController(player));
    // videoSourceController.videoRul.listen((url) {
    //   player.open(Media(url));
    // });
    player.open(Media(
        "https://vod.skr0.cc:666/skr.php?t=0b07c4aabfdc28bb8236e195c401e1b2&ad=1&td=46&id=214289&link=https://vip.ffzy-online1.com/20251208/58771_3f14abec/index.m3u8"));
    Get.put(VideoStateController(player));
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
            subject: widget.subject,
          ),
        ),
      ],
    );
  }
}
