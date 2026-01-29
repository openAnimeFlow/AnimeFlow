import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class RightAreaControl extends StatefulWidget {
  const RightAreaControl({super.key});

  @override
  State<RightAreaControl> createState() => _RightAreaControlState();
}

class _RightAreaControlState extends State<RightAreaControl> {
  late VideoStateController videoStateController;
  late VideoUiStateController videoUiStateController;
  late PlayController playController;

  @override
  void initState() {
    super.initState();
    videoStateController = Get.find<VideoStateController>();
    videoUiStateController = Get.find<VideoUiStateController>();
    playController = Get.find<PlayController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final fullscreen = playController.isFullscreen.value;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: videoUiStateController.isShowControlsUi.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    key: ValueKey<bool>(
                        videoUiStateController.isShowControlsUi.value),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(
                        () => videoStateController.position.value >
                                    Duration.zero &&
                                (playController.isWideScreen.value ||
                                    fullscreen)
                            ? InkWell(
                                onTap: () async {
                                  try {
                                    final uint8List = await videoStateController
                                        .player
                                        .screenshot();
                                    if (uint8List != null) {
                                      await SystemUtil.saveImageBytes(uint8List,
                                          name: 'video_screenshot');
                                    } else {
                                      Get.snackbar('提示', '截图失败，无法获取截图数据',
                                          maxWidth: 500);
                                    }
                                  } catch (e) {
                                    Logger().e(e);
                                    Get.snackbar('提示', '截图失败: $e',
                                        maxWidth: 500);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        width: 1,
                                        color: Colors.white10,
                                      )),
                                  child: const Icon(Icons.camera_alt_outlined,
                                      color: Colors.white70, size: 30),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                )
              : SizedBox.shrink(
                  key: ValueKey<bool>(
                      videoUiStateController.isShowControlsUi.value),
                ),
        );
      },
    );
  }
}
