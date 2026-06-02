import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/pages/play/controller/episode_controller.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/pages/play/video/ui/button/rate_button.dart';
import 'package:anime_flow/pages/play/video/ui/button/shader_button.dart';
import 'package:anime_flow/pages/play/video/ui/danmaku/danmaku_setting.dart';
import 'package:anime_flow/pages/play/video/ui/video_ui_components.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/danmaku_text_field.dart';
import 'package:anime_flow/widget/play_content/episodes_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// 底部区域控件
class BottomAreaControl extends StatefulWidget {
  const BottomAreaControl({super.key});

  @override
  State<BottomAreaControl> createState() => _BottomAreaControlState();
}

class _BottomAreaControlState extends State<BottomAreaControl> {
  final videoUiStateController = Get.find<VideoUiStateController>();
  final playController = Get.find<PlayController>();
  final episodesState = Get.find<EpisodesState>();
  final episodeController = Get.find<EpisodeController>();

  Future<void> onSendDanmaku(String text, int bgmUserId) async {
    final success = await playController.sendDanmaku(
      text,
      bgmUserId: bgmUserId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '弹幕发送成功' : '当前不支持发送弹幕',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 全屏状态，
      final fullscreen = playController.isFullscreen.value;

      final danmakuOn = playController.danmakuOn.value;
      final isWideScreen = playController.isWideScreen.value;
      final isShowControlsUi = videoUiStateController.isShowControlsUi.value;
      final isContentExpanded = playController.isContentExpanded.value;
      final hasNextEpisode = episodeController.hasNextEpisode(episodesState);
      final leftPadding = MediaQuery.of(context).padding.left;
      // 全屏 + 不随键盘压缩 body 时，用 viewInsets 把底部控件顶到键盘上方
      final keyboardLift = fullscreen && SystemUtil.isMobile
          ? MediaQuery.viewInsetsOf(context).bottom
          : 0.0;
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
                      left: leftPadding <= 0 ? 5 : leftPadding,
                      right: 5,
                      bottom: (SystemUtil.isDesktop
                              ? 10
                              : isWideScreen
                                  ? MediaQuery.of(context).padding.bottom
                                  : 0) +
                          keyboardLift),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 时间显示
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: VideoTimeDisplay(
                          videoUiStateController: videoUiStateController,
                          playController: playController,
                        ),
                      ),
                      // 进度条
                      if (fullscreen || isWideScreen)
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          child: VideoProgressBar(),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 播放按钮
                          InkWell(
                            key: ValueKey<bool>(playController.playing.value),
                            onTap: () => {
                              playController.playOrPauseVideo(),
                              videoUiStateController
                                  .updateIndicatorTypeAndShowIndicator(
                                      VideoControlsIndicatorType
                                          .playStatusIndicator),
                            },
                            child: Icon(
                              playController.playing.value
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
                                  AssetsPathConstants.danmakuIcon,
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
                                    ? Consumer(
                                        builder: (context, ref, _) {
                                          final userInfo = ref
                                              .watch(currentUserInfoProvider);
                                          if (userInfo != null) {
                                            return DanmakuTextField(
                                              iconColor: Colors.white,
                                              textColor: Colors.white,
                                              onFocusChange: (hasFocus) {
                                                if (hasFocus) {
                                                  playController.stopPlaying();
                                                  videoUiStateController
                                                      .cancelUiTimer();
                                                } else {
                                                  playController.startPlaying();
                                                }
                                              },
                                              onSend: (content) =>
                                                  onSendDanmaku(
                                                      content, userInfo.id),
                                            );
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.8),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              "登录后才能发送弹幕",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox.shrink()
                                // 进度条
                                : const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5),
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
                                        return EpisodesDialog(
                                          episodes: episodesState
                                              .episodes.value?.data,
                                          selectedEpisode:
                                              episodesState.episodeSort.value,
                                          onEpisodeSelected:
                                              (episode, episodeIndex) {
                                            episodesState.setEpisodeSort(
                                              episodeId: episode.id,
                                              episodeIndex: episodeIndex,
                                              sort: episode.sort,
                                            );
                                            episodesState.setEpisodeTitle(
                                                episode.nameCN.isEmpty
                                                    ? episode.name
                                                    : episode.nameCN);
                                            context.pop();
                                          },
                                        );
                                      });
                                },
                                child: const Text("选集")),

                          //超分辨率
                          if (isWideScreen || fullscreen)
                            ShaderButton(
                              playController: playController,
                              videoUiStateController: videoUiStateController,
                            ),

                          //倍速按钮
                          if (isWideScreen || fullscreen)
                            RateButton(
                              playController: playController,
                              videoUiStateController: videoUiStateController,
                            ),

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
