import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/utils/exceptions/storage_exception.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RightAreaControl extends StatefulWidget {
  const RightAreaControl({super.key});

  @override
  State<RightAreaControl> createState() => _RightAreaControlState();
}

class _RightAreaControlState extends State<RightAreaControl> {
  final videoUiStateController = Get.find<VideoUiStateController>();
  final playController = Get.find<PlayController>();

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
                        () => playController.position.value > Duration.zero &&
                                (playController.isWideScreen.value ||
                                    fullscreen)
                            ? InkWell(
                                onTap: () async {
                                  try {
                                    final uint8List = await playController
                                        .player
                                        .screenshot();
                                    if (uint8List != null) {
                                      final message =
                                          await SystemUtil.saveImageBytes(
                                        uint8List,
                                        name: 'video_screenshot',
                                      );
                                      NotificationToast.show('提示', message,
                                          align: Alignment.topCenter,
                                          maxWidth: 500);
                                    } else {
                                      NotificationToast.show(
                                          align: Alignment.topCenter,
                                          '提示',
                                          '截图失败，无法获取截图数据',
                                          maxWidth: 500);
                                    }
                                  } on StoragePermissionDeniedException catch (e) {
                                    LiggLogger().e(e);
                                    NotificationToast.show('提示', e.message,
                                        align: Alignment.topCenter,
                                        maxWidth: 500);
                                  } catch (e) {
                                    LiggLogger().e(e);
                                    NotificationToast.show('提示', '截图失败: $e',
                                        align: Alignment.topCenter,
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
