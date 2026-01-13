import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/widget/video/ui/danmaku/danmaku_setting.dart';
import 'package:anime_flow/widget/video/ui/rate_button.dart';
import 'package:anime_flow/widget/video/ui/video_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

/// 底部区域控件
class BottomAreaControl extends StatelessWidget {
  const BottomAreaControl({super.key});

  @override
  Widget build(BuildContext context) {
    final videoUiStateController = Get.find<VideoUiStateController>();
    final videoStateController = Get.find<VideoStateController>();
    final playPageController = Get.find<PlayController>();

    return Obx(() {
      // 使用自定义全屏状态，
      final fullscreen = playPageController.isFullscreen.value;
      final danmakuOn = playPageController.danmakuOn.value;
      final isWideScreen = playPageController.isWideScreen.value;
      final isShowControlsUi = videoUiStateController.isShowControlsUi.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: isShowControlsUi
            ? Container(
                key: ValueKey<bool>(isShowControlsUi),
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
                      if (fullscreen || isWideScreen)
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
                            //弹幕开关
                            IconButton(
                              onPressed: () {
                                playPageController.toggleDanmaku();
                              },
                              icon: SvgPicture.asset(
                                danmakuOn
                                    ? 'assets/icons/danmaku_on.svg'
                                    : 'assets/icons/danmaku_off.svg',
                                width: 25,
                                height: 25,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                            ),
                            //弹幕设置
                            if (danmakuOn)
                              IconButton(
                                onPressed: () {
                                  Get.bottomSheet(
                                    const DanmakuSetting(),
                                    ignoreSafeArea: false,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                  );
                                },
                                icon: SvgPicture.asset(
                                  'assets/icons/danmaku_setting.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            Expanded(
                              child: fullscreen || isWideScreen
                                  ? danmakuOn
                                      // 弹幕输入框
                                      ? const DanmakuTextField(
                                          iconColor: Colors.white,
                                          textColor: Colors.white,
                                        )
                                      : const SizedBox.shrink()
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
                            if (isWideScreen || fullscreen)
                              const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 0),
                                  child: RateButton()),

                            // 全屏按钮
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              child: IconButton(
                                // 使用自定义全屏方法，
                                onPressed: () {
                                  playPageController.toggleFullScreen();
                                },
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
                key: ValueKey<bool>(isShowControlsUi),
              ),
      );
    });
  }
}
