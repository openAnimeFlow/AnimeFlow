import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/widget/video/ui/rate_button.dart';
import 'package:anime_flow/widget/video/ui/video_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// 底部区域控件
class BottomAreaControl extends StatelessWidget {
  const BottomAreaControl({super.key});

  @override
  Widget build(BuildContext context) {
    final videoUiStateController = Get.find<VideoUiStateController>();
    final videoStateController = Get.find<VideoStateController>();
    final playPageController = Get.find<PlayController>();

    //使用media_kit_video提供的全屏判断
    bool fullscreen = isFullscreen(context);
    return Obx(() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: videoUiStateController.isShowControlsUi.value
            ? Container(
                key: ValueKey<bool>(
                    videoUiStateController.isShowControlsUi.value),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.black38,
                    Colors.transparent,
                  ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).padding.left, right: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 时间显示组件
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: VideoTimeDisplay(
                            videoController: videoUiStateController),
                      ),
                      if (fullscreen || playPageController.isWideScreen.value)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                          child: VideoProgressBar(
                              videoUiStateController: videoUiStateController),
                        ),
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 播放按钮
                            InkWell(
                              key: ValueKey<bool>(
                                  videoStateController.playing.value),
                              onTap: () => {
                                videoStateController.playOrPauseVideo(),
                                videoUiStateController
                                    .updateIndicatorTypeAndShowIndicator(
                                        VideoControlsIndicatorType
                                            .playStatusIndicator),
                              },
                              child: Icon(
                                videoStateController.playing.value
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 33,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Expanded(
                              child: fullscreen ||
                                      playPageController.isWideScreen.value
                                  ? const DanmakuTextField(
                                      iconColor: Colors.white,
                                      textColor: Colors.white,
                                    )
                                  // 进度条
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: VideoProgressBar(
                                          videoUiStateController:
                                              videoUiStateController),
                                    ),
                            ),

                            //倍速按钮
                            if (playPageController.isWideScreen.value ||
                                fullscreen)
                              const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 0),
                                  child: RateButton()),

                            // 全屏按钮
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              child: IconButton(
                                //使用media_kit_video提供的全屏方法
                                onPressed: () => toggleFullscreen(context),
                                padding: const EdgeInsets.all(0),
                                icon: fullscreen
                                    ? Icon(
                                        size: 33,
                                        Icons.fullscreen_exit,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      )
                                    : Icon(
                                        size: 33,
                                        Icons.fullscreen,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox.shrink(
                key: ValueKey<bool>(
                    videoUiStateController.isShowControlsUi.value),
              )));
  }
}
