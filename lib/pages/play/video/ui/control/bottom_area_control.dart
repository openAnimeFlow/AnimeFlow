import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/pages/play/video/ui/button/fit_button.dart';
import 'package:anime_flow/pages/play/video/ui/button/rate_button.dart';
import 'package:anime_flow/pages/play/video/ui/button/shader_button.dart';
import 'package:anime_flow/pages/play/video/ui/danmaku/danmaku_setting.dart';
import 'package:anime_flow/pages/play/video/ui/player_progress_bar.dart';
import 'package:anime_flow/pages/play/video/ui/player_time_display.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/danmaku_text_field.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:anime_flow/widget/play_content/episodes_dialog.dart';
import 'package:anime_flow/widget/play_pause_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

/// 底部区域控件
class BottomAreaControl extends ConsumerWidget {
  const BottomAreaControl({super.key});

  Future<void> onSendDanmaku(
    BuildContext context,
    PlaySession playController,
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

  Future<void> _updateEpisodeWatched(
    BuildContext dialogContext,
    ProviderContainer container,
    int episodeId,
  ) async {
    try {
      final playController = container.read(playSessionProvider);
      await playController.updateEpisodeWatchedState(episodeId);
      if (!dialogContext.mounted) return;
      final subjectId = container.read(playExtraProvider).playExtra.subjectId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container
            .read(subjectEpisodesProvider(subjectId).notifier)
            .setEpisodeWatched(
              episodeId: episodeId,
              watched: true,
            );
      });
      NotificationToast.show('提示', '已更新观看进度');
    } on AnimeFlowApiException catch (e) {
      if (!dialogContext.mounted) return;
      NotificationToast.show('更新失败', e.message);
    } catch (e) {
      if (!dialogContext.mounted) return;
      LiggLogger().e(e);
      NotificationToast.show('更新失败', e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playController = ref.read(playSessionProvider);
    final videoUiStateController = ref.read(videoUiProvider.notifier);
    final fullscreen =
        ref.watch(playStateProvider.select((s) => s.isFullscreen));
    final danmakuOn = ref.watch(playStateProvider.select((s) => s.danmakuOn));
    final isWideScreen =
        ref.watch(playStateProvider.select((s) => s.isWideScreen));
    final isContentExpanded =
        ref.watch(playStateProvider.select((s) => s.isContentExpanded));
    final isShowControlsUi =
        ref.watch(videoUiProvider.select((s) => s.isShowControlsUi));
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: PlayerTimeDisplay(),
                    ),
                    // 进度条
                    if (fullscreen || isWideScreen)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        child: PlayerProgressBar(),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 播放按钮
                        Consumer(
                          builder: (context, ref, child) {
                            final playing = ref.watch(
                                playStateProvider.select((s) => s.playing));
                            return IconButton(
                              tooltip: playing ? '暂停' : '播放',
                              onPressed: () {
                                playController.playOrPauseVideo();
                                videoUiStateController
                                    .updateIndicatorTypeAndShowIndicator(
                                  VideoControlsIndicatorType
                                      .playStatusIndicator,
                                );
                              },
                              icon: PlayPauseIcon(
                                playing: playing,
                                iconColor: Colors.white70,
                              ),
                            );
                          },
                        ),
                        // 下一集
                        Consumer(
                          builder: (context, ref, _) {
                            final episodesState =
                                ref.watch(episodesProvider).asData?.value;
                            final episodes = episodesState?.episodes;
                            final selection = episodes == null
                                ? null
                                : SubjectEpisodesState(episodes: episodes)
                                    .nextEpisodeSelection(
                                    episodesState!.episodeIndex,
                                  );
                            if (selection == null) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              tooltip: '下一集',
                              onPressed: () {
                                final notifier =
                                    ref.read(episodesProvider.notifier);
                                notifier.setEpisodeSort(
                                  episodeId: selection.id,
                                  episodeIndex: selection.index,
                                  sort: selection.sort,
                                );
                                notifier.setEpisodeTitle(selection.title);
                              },
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 33,
                                color: Colors.white70,
                              ),
                            );
                          },
                        ),
                        //弹幕开关
                        IconButton(
                          tooltip: danmakuOn ? '关闭弹幕' : '开启弹幕',
                          onPressed: () => playController.toggleDanmaku(),
                          icon: Icon(
                              danmakuOn
                                  ? Icons.subtitles_outlined
                                  : Icons.subtitles_off_outlined,
                              color: Colors.white70,
                              size: 25),
                        ),
                        //弹幕设置
                        if (danmakuOn)
                          IconButton(
                            tooltip: '弹幕设置',
                            onPressed: () {
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
                            icon: SvgPicture.asset(
                              AssetsPathConstants.danmakuIcon,
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                  Colors.white.withValues(alpha: 0.8),
                                  BlendMode.srcIn),
                            ),
                          ),
                        Expanded(
                          child: fullscreen || isWideScreen
                              ? danmakuOn
                                  // 弹幕输入框
                                  ? Consumer(
                                      builder: (context, ref, _) {
                                        final userInfo = ref
                                            .watch(currentUserInfoProvider)
                                            .value;
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
                                            onSend: (message) => onSendDanmaku(
                                                context,
                                                playController,
                                                message,
                                                userInfo.id),
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
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink()
                              // 进度条
                              : const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: PlayerProgressBar(),
                                ),
                        ),
                        //选集
                        if (fullscreen || !isContentExpanded)
                          Consumer(
                            builder: (context, ref, _) {
                              return TextButton(
                                  onPressed: () {
                                    final container =
                                        ProviderScope.containerOf(context);
                                    showGeneralDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      barrierLabel: 'EpisodesDialog',
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
                                      pageBuilder: (dialogContext, animation,
                                          secondaryAnimation) {
                                        return UncontrolledProviderScope(
                                          container: container,
                                          child: EpisodesDialog(
                                            onEpisodeLongPress: (episodeId) {
                                              _updateEpisodeWatched(
                                                dialogContext,
                                                container,
                                                episodeId,
                                              );
                                            },
                                          ),
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
                          Consumer(
                            builder: (context, ref, child) {
                              final videoFit = ref.watch(
                                  playStateProvider.select((s) => s.videoFit));
                              return FitButton(
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
                              );
                            },
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
  }
}
