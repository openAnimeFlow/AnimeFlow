import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/player/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/player/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/player/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/player/presentation/widgets/video/ui/button/fit_button.dart';
import 'package:anime_flow/features/player/presentation/widgets/video/ui/button/rate_button.dart';
import 'package:anime_flow/features/player/presentation/widgets/video/ui/button/shader_button.dart';
import 'package:anime_flow/features/player/presentation/widgets/video/ui/danmaku/danmaku_setting.dart';
import 'package:anime_flow/features/player/presentation/widgets/video/ui/player_progress_bar.dart';
import 'package:anime_flow/features/player/presentation/widgets/video/ui/player_time_display.dart';
import 'package:anime_flow/features/player/presentation/providers/subject_episodes_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/widgets/danmaku_text_field.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/features/player/presentation/widgets/episode_playing_indicator.dart';
import 'package:anime_flow/features/player/presentation/widgets/episodes_dialog.dart';
import 'package:anime_flow/features/player/presentation/widgets/play_pause_icon.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

/// 底部区域控件
class BottomAreaControl extends ConsumerWidget {
  const BottomAreaControl({super.key});

  static const double _wideDanmakuControlsMaxWidth = 520;

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
          success
              ? AppLocalizations.of(context).danmakuSent
              : AppLocalizations.of(context).danmakuUnsupported,
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
      await playController.updateEpisodeWatched(episodeId);
      if (!dialogContext.mounted) return;
      final l10n = AppLocalizations.of(dialogContext);
      NotificationToast.show(l10n.tip, l10n.updatedProgress);
    } on AnimeFlowApiException catch (e) {
      if (!dialogContext.mounted) return;
      NotificationToast.show(
          AppLocalizations.of(dialogContext).updateFailed, e.message);
    } catch (e) {
      if (!dialogContext.mounted) return;
      LiggLogger().e(e);
      NotificationToast.show(
          AppLocalizations.of(dialogContext).updateFailed, e.toString());
    }
  }

  Widget _buildDanmakuInputField({
    required BuildContext context,
    required WidgetRef ref,
    required bool danmakuOn,
    required PlaySession playController,
    required VideoUiNotifier videoUiStateController,
  }) {
    if (!danmakuOn) return const SizedBox.shrink();
    final userInfo = ref.watch(currentUserInfoProvider).value;
    if (userInfo != null) {
      return DanmakuTextField(
        showCloseButton: false,
        iconColor: Colors.white,
        textColor: Colors.white,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            playController.stopPlaying();
            videoUiStateController.cancelUiTimer();
          } else {
            playController.startPlaying();
          }
        },
        onSend: (message) => onSendDanmaku(
          context,
          playController,
          message,
          userInfo.id,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        AppLocalizations.of(context).loginToSendDanmaku,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildWideDanmakuControls({
    required BuildContext context,
    required WidgetRef ref,
    required bool danmakuOn,
    required PlaySession playController,
    required VideoUiNotifier videoUiStateController,
  }) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _wideDanmakuControlsMaxWidth,
        ),
        child: Row(
          children: [
            //弹幕开关
            IconButton(
              tooltip: danmakuOn ? l10n.turnOffDanmaku : l10n.turnOnDanmaku,
              onPressed: () => playController.toggleDanmaku(),
              icon: Icon(
                danmakuOn
                    ? Icons.subtitles_outlined
                    : Icons.subtitles_off_outlined,
                color: Colors.white70,
                size: 25,
              ),
            ),
            //弹幕设置
            if (danmakuOn)
              IconButton(
                tooltip: l10n.danmakuSettings,
                onPressed: () {
                  final container = ProviderScope.containerOf(context);
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
                    BlendMode.srcIn,
                  ),
                ),
              ),
            Expanded(
              child: _buildDanmakuInputField(
                context: context,
                ref: ref,
                danmakuOn: danmakuOn,
                playController: playController,
                videoUiStateController: videoUiStateController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                              tooltip: playing ? l10n.pause : l10n.play,
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
                              tooltip: l10n.nextEpisode,
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
                        Expanded(
                          child: isWideScreen
                              ? _buildWideDanmakuControls(
                                  context: context,
                                  ref: ref,
                                  danmakuOn: danmakuOn,
                                  playController: playController,
                                  videoUiStateController:
                                      videoUiStateController,
                                )
                              : fullscreen
                                  ? _buildDanmakuInputField(
                                      context: context,
                                      ref: ref,
                                      danmakuOn: danmakuOn,
                                      playController: playController,
                                      videoUiStateController:
                                          videoUiStateController,
                                    )
                                  // 进度条
                                  : const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5),
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
                                            isSelectedIcon: Consumer(
                                              builder: (context, ref, _) {
                                                final playing = ref.watch(
                                                  playStateProvider.select(
                                                    (s) => s.playing,
                                                  ),
                                                );
                                                return EpisodePlayingIndicator(
                                                  size: 30,
                                                  isPlaying: playing,
                                                );
                                              },
                                            ),
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
                                  child: Text(l10n.episodeSelection));
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
