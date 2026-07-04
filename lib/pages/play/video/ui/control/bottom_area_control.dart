import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/pages/play/video/ui/button/fit_button.dart';
import 'package:anime_flow/pages/play/video/ui/button/rate_button.dart';
import 'package:anime_flow/pages/play/video/ui/button/shader_button.dart';
import 'package:anime_flow/pages/play/video/ui/danmaku/danmaku_setting.dart';
import 'package:anime_flow/pages/play/video/ui/video_ui_components.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/danmaku_text_field.dart';
import 'package:anime_flow/widget/multi_value_listenable_builder.dart';
import 'package:anime_flow/widget/play_content/episodes_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

/// 底部区域控件
class BottomAreaControl extends ConsumerWidget {
  const BottomAreaControl({super.key});

  Future<void> onSendDanmaku(
    BuildContext context,
    PlayController playController,
    String text,
    int bgmUserId,
  ) async {
    final success = await playController.sendDanmaku(
      text,
      bgmUserId: bgmUserId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '弹幕发送成功' : '当前不支持发送弹幕',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playController = ref.read(playControllerProvider);
    final videoUiStateController =
        ref.read(videoUiStateControllerProvider.notifier);
    return MultiValueListenableBuilder(
        listenables: [
          playController.isFullscreen,
          playController.danmakuOn,
          playController.isWideScreen,
          playController.isContentExpanded,
          playController.playing,
        ],
        builder: (context) {
          // 全屏状态，
          final fullscreen = playController.isFullscreen.value;

          final danmakuOn = playController.danmakuOn.value;
          final isWideScreen = playController.isWideScreen.value;
          final isShowControlsUi = ref.watch(
              videoUiStateControllerProvider.select((s) => s.isShowControlsUi));
          final isContentExpanded = playController.isContentExpanded.value;
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
                      gradient: LinearGradient(
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter),
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: VideoTimeDisplay(),
                          ),
                          // 进度条
                          if (fullscreen || isWideScreen)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                              child: VideoProgressBar(),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 播放按钮
                              InkWell(
                                key: ValueKey<bool>(
                                    playController.playing.value),
                                onTap: () {
                                  playController.playOrPauseVideo();
                                  videoUiStateController
                                      .updateIndicatorTypeAndShowIndicator(
                                    VideoControlsIndicatorType
                                        .playStatusIndicator,
                                  );
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
                              Consumer(
                                builder: (context, ref, _) {
                                  ref.watch(
                                    episodesProvider
                                        .select((state) => state.episodeIndex),
                                  );
                                  final hasNextEpisode = ref
                                      .read(episodesProvider.notifier)
                                      .hasNextEpisode;
                                  if (!hasNextEpisode) {
                                    return const SizedBox.shrink();
                                  }
                                  return InkWell(
                                    onTap: () {
                                      ref
                                          .read(episodesProvider.notifier)
                                          .switchToNextEpisode();
                                    },
                                    child: const Icon(
                                      Icons.skip_next_rounded,
                                      size: 33,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
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
                                  onTap: () {
                                    final container =
                                        ProviderScope.containerOf(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return UncontrolledProviderScope(
                                          container: container,
                                          child: const DanmakuSetting(),
                                        );
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
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
                                                  .watch(
                                                      currentUserInfoProvider)
                                                  .value;
                                              if (userInfo != null) {
                                                return DanmakuTextField(
                                                  iconColor: Colors.white,
                                                  textColor: Colors.white,
                                                  onFocusChange: (hasFocus) {
                                                    if (hasFocus) {
                                                      playController
                                                          .stopPlaying();
                                                      videoUiStateController
                                                          .cancelUiTimer();
                                                    } else {
                                                      playController
                                                          .startPlaying();
                                                    }
                                                  },
                                                  onSend: (message) =>
                                                      onSendDanmaku(
                                                          context,
                                                          playController,
                                                          message,
                                                          userInfo.id),
                                                );
                                              }
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                Consumer(
                                  builder: (context, ref, _) {
                                    return TextButton(
                                        onPressed: () {
                                          final container =
                                              ProviderScope.containerOf(
                                                  context);
                                          showGeneralDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            barrierLabel: 'EpisodesDialog',
                                            barrierColor: Colors.black54,
                                            transitionDuration: const Duration(
                                                milliseconds: 300),
                                            transitionBuilder: (context,
                                                animation,
                                                secondaryAnimation,
                                                child) {
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
                                              return UncontrolledProviderScope(
                                                container: container,
                                                child: const EpisodesDialog(),
                                              );
                                            },
                                          );
                                        },
                                        child: const Text("选集"));
                                  },
                                ),

                              //超分辨率
                              if (isWideScreen || fullscreen)
                                ShaderButton(
                                  playController: playController,
                                ),

                              if (isWideScreen || fullscreen) ...[
                                //倍速按钮
                                RateButton(
                                  playController: playController,
                                ),
                                // 画面填充按钮
                                ValueListenableBuilder<BoxFit>(
                                  valueListenable: playController.videoFit,
                                  builder: (context, videoFit, _) => FitButton(
                                    value: videoFit,
                                    onChanged: (fit) {
                                      playController.toggleVideoFit(fit);
                                    },
                                    onMenuOpen: () =>
                                        videoUiStateController.cancelUiTimer(),
                                    onMenuClose: () =>
                                        videoUiStateController.hideControlsUi(
                                      duration: const Duration(seconds: 2),
                                    ),
                                  ),
                                ),
                              ],

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
