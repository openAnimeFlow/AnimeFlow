import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/play/episode_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/play_content/episodes_view.dart';
import 'package:anime_flow/widget/video/ui/danmaku/danmaku_setting.dart';
import 'package:anime_flow/widget/video/ui/button/rate_button.dart';
import 'package:anime_flow/widget/video/ui/video_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import 'button/shader_button.dart';

/// 底部区域控件
class BottomAreaControl extends StatelessWidget {
  const BottomAreaControl({super.key});

  @override
  Widget build(BuildContext context) {
    final videoUiStateController = Get.find<VideoUiStateController>();
    final videoStateController = Get.find<VideoStateController>();
    final playController = Get.find<PlayController>();
    final episodesState = Get.find<EpisodesState>();
    final episodeController = Get.find<EpisodeController>();
    final paddingLeft = MediaQuery.of(context).padding.left;
    return Obx(() {
      // 全屏状态，
      final fullscreen = playController.isFullscreen.value;

      final danmakuOn = playController.danmakuOn.value;
      final isWideScreen = playController.isWideScreen.value;
      final isShowControlsUi = videoUiStateController.isShowControlsUi.value;
      final isContentExpanded = playController.isContentExpanded.value;
      final hasNextEpisode = episodeController.hasNextEpisode(episodesState);

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
                      left: MediaQuery.of(context).padding.left,
                      right: 5,
                      bottom: Utils.isDesktop
                          ? 10
                          : isWideScreen
                              ? MediaQuery.of(context).padding.bottom
                              : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 时间显示
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: VideoTimeDisplay(
                          videoUiStateController: videoUiStateController,
                          videoStateController: videoStateController,
                        ),
                      ),
                      // 进度条
                      if (fullscreen || isWideScreen)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: paddingLeft == 0 ? 10 : 0,
                              vertical: 5),
                          child: const VideoProgressBar(),
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
                                color: Colors.white70,
                              ),
                            ),
                            // 下一集
                            if (hasNextEpisode)
                              InkWell(
                                onTap: () {
                                  episodeController
                                      .switchToNextEpisode(episodesState);
                                },
                                child: const Icon(
                                  Icons.skip_next_rounded,
                                  size: 33,
                                  color: Colors.white70,
                                ),
                              ),
                            //弹幕开关
                            InkWell(
                              onTap: () => playController.toggleDanmaku(),
                              child: Icon(
                                  danmakuOn
                                      ? Icons.subtitles_outlined
                                      : Icons.subtitles_off_outlined,
                                  color: Colors.white70,
                                  size: 25),
                            ),
                            //弹幕设置
                            if (danmakuOn)
                              InkWell(
                                onTap: () => Get.bottomSheet(
                                  const DanmakuSetting(),
                                  ignoreSafeArea: false,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: SvgPicture.asset(
                                    'assets/icons/danmaku_setting.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: ColorFilter.mode(
                                        Colors.white.withValues(alpha: 0.8),
                                        BlendMode.srcIn),
                                  ),
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
                                  : const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: VideoProgressBar(),
                                    ),
                            ),
                            //选集
                            if (fullscreen || !isContentExpanded)
                              TextButton(
                                  onPressed: () {
                                    Get.generalDialog(
                                        barrierDismissible: true,
                                        barrierLabel: "episodesDrawer",
                                        barrierColor: Colors.black54,
                                        transitionDuration:
                                            const Duration(milliseconds: 300),
                                        transitionBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1, 0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOut,
                                            )),
                                            child: child,
                                          );
                                        },
                                        pageBuilder: (context, animation,
                                            secondaryAnimation) {
                                          return const EpisodesView();
                                        });
                                  },
                                  child: const Text("选集")),

                            //超分辨率
                            if (isWideScreen || fullscreen)
                              const ShaderButton(),

                            //倍速按钮
                            if (isWideScreen || fullscreen) const RateButton(),

                            // 全屏按钮
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              child: IconButton(
                                  onPressed: () {
                                    playController.toggleFullScreen();
                                  },
                                  padding: const EdgeInsets.all(0),
                                  icon: Icon(
                                    fullscreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    size: 33,
                                    color: Colors.white70,
                                  )),
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
