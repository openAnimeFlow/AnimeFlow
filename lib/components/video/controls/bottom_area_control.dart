import 'package:anime_flow/components/video/controls/video_ui_components.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

class BottomAreaControl extends StatelessWidget {
  final VideoUiStateController videoUiStateController;
  final VideoStateController videoStateController;

  const BottomAreaControl(
      {super.key,
      required this.videoUiStateController,
      required this.videoStateController});

  @override
  Widget build(BuildContext context) {
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
                decoration: BoxDecoration(
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
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: VideoTimeDisplay(
                            videoController: videoUiStateController),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 播放按钮
                          Obx(() => IconButton(
                              padding: EdgeInsets.all(0),
                              key: ValueKey<bool>(
                                  videoStateController.playing.value),
                              onPressed: () => {
                                    videoStateController.playOrPauseVideo(),
                                    videoUiStateController.updateIndicatorType(
                                        VideoControlsIndicatorType
                                            .playStatusIndicator),
                                    videoUiStateController.showIndicator()
                                  },
                              icon: Icon(
                                videoStateController.playing.value
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 33,
                                color: Colors.white.withValues(alpha: 0.8),
                              ))),

                          // 进度条
                          Expanded(
                            child: VideoProgressBar(
                                videoUiStateController: videoUiStateController),
                          ),

                          // 全屏按钮
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            child: IconButton(
                              //使用media_kit_video提供的全屏方法
                              onPressed: () => toggleFullscreen(context),
                              padding: EdgeInsets.all(0),
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
