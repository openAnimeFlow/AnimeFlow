import 'package:anime_flow/core/logger/app_log.dart';
import 'package:anime_flow/features/play/application/play_session.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';
import 'package:anime_flow/features/play/presentation/widgets/dialog/episodes_dialog.dart';
import 'package:anime_flow/features/play/presentation/widgets/player_settings_sheet.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/subject_episodes/application/subject_episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/fit_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/rate_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/button/upscale_button.dart';
import 'package:anime_flow/features/play/presentation/widgets/dialog/danmaku_setting_dialog.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/player_progress_bar.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/player_time_display.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:anime_flow/shared/widgets/danmaku_text_field.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/features/play/presentation/widgets/loading_animation.dart';
import 'package:anime_flow/features/play/presentation/widgets/play_pause_icon.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

/// 底部区域控件
@Dependencies([
  VideoUiNotifier,
  PlayStateNotifier,
  playSession,
  DanmakuStateNotifier,
  playExtra,
  Episodes
])
class BottomAreaControl extends ConsumerWidget {
  const BottomAreaControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShowControlsUi = ref.watch(
      videoUiProvider.select((state) => state.isShowControlsUi),
    );
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (ref.read(playPreferencesProvider).showMiniProgressBar)
          _MiniProgressBarVisibility(visible: !isShowControlsUi),
        // Keep menus, input drafts and subscriptions alive across auto-hide.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: isShowControlsUi ? 1 : 0,
            end: isShowControlsUi ? 1 : 0,
          ),
          duration: const Duration(milliseconds: 200),
          curve: isShowControlsUi ? Curves.easeOutCubic : Curves.easeInCubic,
          builder: (context, value, child) => ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: IgnorePointer(
                  ignoring: !isShowControlsUi,
                  child: ExcludeSemantics(
                    excluding: !isShowControlsUi,
                    child: ExcludeFocus(
                      excluding: !isShowControlsUi,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: const _BottomControlsContent(),
        ),
      ],
    );
  }
}

@Dependencies([
  playSession,
  VideoUiNotifier,
  PlayStateNotifier,
  DanmakuStateNotifier,
  playExtra,
  Episodes
])
class _BottomControlsContent extends ConsumerWidget {
  const _BottomControlsContent();

  static const double _wideDanmakuControlsMaxWidth = 520;

  String _videoFitLabel(AppLocalizations l10n, VideoFit fit) => switch (fit) {
        VideoFit.contain => l10n.fitAuto,
        VideoFit.cover => l10n.fitCrop,
        VideoFit.fill => l10n.fitStretch,
      };

  Widget _menuContent(List<Widget> items) => SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 144),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
        ),
      );

  Widget _menuOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return MenuItemButton(
      closeOnActivate: false,
      onPressed: onPressed,
      trailingIcon:
          isSelected ? Icon(Icons.check, size: 18, color: primary) : null,
      child: Text(
        label,
        style: isSelected
            ? TextStyle(color: primary, fontWeight: FontWeight.bold)
            : null,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Consumer(
      builder: (context, ref, _) {
        final playController = ref.read(playSessionProvider);
        final videoUiStateController = ref.read(videoUiProvider.notifier);
        final duration = ref.watch(playStateProvider.select((s) => s.duration));
        final position = ref.watch(playStateProvider.select((s) => s.position));
        final buffered = ref.watch(playStateProvider.select((s) => s.buffered));
        final isDragging = ref.watch(
          videoUiProvider.select((state) => state.isHorizontalDragging),
        );
        final dragPosition = isDragging
            ? ref.watch(videoUiProvider.select((state) => state.dragPosition))
            : Duration.zero;

        return PlayerProgressBar(
          duration: duration,
          position: position,
          buffered: buffered,
          isDragging: isDragging,
          dragPosition: dragPosition,
          onChangeStart: (value) {
            if (!playController.beginManualSeek()) return;
            videoUiStateController.startProgressDrag(
              Duration(milliseconds: value.toInt()),
            );
          },
          onChanged: (value) {
            videoUiStateController.setHorizontalDragPosition(
              Duration(milliseconds: value.toInt()),
            );
          },
          onChangeEnd: (value) {
            playController.finishManualSeek(
              Duration(milliseconds: value.toInt()),
            );
            videoUiStateController.endHorizontalDrag();
          },
        );
      },
    );
  }

  Future<void> _updateEpisodeWatched(
    BuildContext dialogContext,
    ProviderContainer container,
    EpisodeData episode,
  ) async {
    try {
      final playController = container.read(playSessionProvider);
      await playController.updateEpisodeWatched(
        episode.id,
        watched: episode.watched != true,
      );
      if (!dialogContext.mounted) return;
      final l10n = AppLocalizations.of(dialogContext);
      NotificationToast.show(l10n.updatedProgress, title: l10n.tip);
    } on AnimeFlowApiException catch (e) {
      if (!dialogContext.mounted) return;
      NotificationToast.show(e.message,
          title: AppLocalizations.of(dialogContext).updateFailed);
    } catch (e) {
      if (!dialogContext.mounted) return;
      logError(e);
      NotificationToast.show(e.toString(),
          title: AppLocalizations.of(dialogContext).updateFailed);
    }
  }

  Widget _buildWideDanmakuControls() {
    return Consumer(builder: (context, ref, _) {
      final danmakuOn =
          ref.watch(danmakuStateProvider.select((s) => s.enabled));
      final playController = ref.read(playSessionProvider);
      final videoUiStateController = ref.read(videoUiProvider.notifier);
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
                onPressed: () {
                  playController.danmaku.toggleEnabled();
                  videoUiStateController.restartControlsAutoHideTimer();
                },
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
                    showPlayerSettingsSheet(
                      context: context,
                      label: l10n.danmakuSettings,
                      child: const DanmakuSettingDialog(),
                      onOpen: videoUiStateController.cancelUiTimer,
                      onClose:
                          videoUiStateController.restartControlsAutoHideTimer,
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
              const Expanded(child: _DanmakuInputField()),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playController = ref.read(playSessionProvider);
    final videoUiStateController = ref.read(videoUiProvider.notifier);
    final fullscreen = ref.watch(videoUiProvider.select((s) => s.isFullscreen));
    final isWideScreen =
        ref.watch(videoUiProvider.select((s) => s.isWideScreen));
    final leftPadding = MediaQuery.of(context).padding.left;
    // 全屏 + 不随键盘压缩 body 时，用 viewInsets 把底部控件顶到键盘上方
    final keyboardLift = fullscreen && ref.read(playbackDeviceProvider).isMobile
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;

    void onMenuOpenChanged(bool isOpen) {
      if (isOpen) {
        videoUiStateController.cancelUiTimer();
      } else {
        videoUiStateController.hideControlsUi(
          duration: const Duration(seconds: 2),
        );
      }
    }

    return Container(
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
            bottom: (ref.read(playbackDeviceProvider).isDesktop
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                child: _buildProgressBar(),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 播放按钮
                Consumer(
                  builder: (context, ref, child) {
                    final playing =
                        ref.watch(playStateProvider.select((s) => s.playing));
                    return IconButton(
                      tooltip: playing ? l10n.pause : l10n.play,
                      onPressed: () {
                        if (!playController.playOrPauseVideo()) return;
                        videoUiStateController.restartControlsAutoHideTimer();
                        videoUiStateController.showTopIndicator(
                          VideoControlsIndicatorType.playStatusIndicator,
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
                    final isOfflineMode = ref.watch(
                      playExtraProvider.select((extra) => extra.isOfflineMode),
                    );
                    final hasNextEpisode = ref.watch(
                      episodesProvider.select((state) {
                        final current = state.asData?.value;
                        final episodes = current?.episodes;
                        return current != null &&
                            episodes != null &&
                            SubjectEpisodesState(episodes: episodes)
                                .hasNextEpisode(current.episodeIndex,
                                    requireAired: !isOfflineMode);
                      }),
                    );
                    if (!hasNextEpisode) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      tooltip: l10n.nextEpisode,
                      onPressed: () {
                        ref
                            .read(episodesProvider.notifier)
                            .switchToNextEpisode();
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
                      ? _buildWideDanmakuControls()
                      : fullscreen
                          ? const _DanmakuInputField()
                          // 进度条
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: _buildProgressBar(),
                            ),
                ),
                //选集
                Consumer(builder: (context, ref, _) {
                  final showEpisodeSelection = ref.watch(
                    videoUiProvider.select((state) =>
                        state.isFullscreen || !state.isContentExpanded),
                  );
                  if (!showEpisodeSelection) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      final container = ProviderScope.containerOf(context);
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'EpisodesDialog',
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (context, animation, secondaryAnimation, child) {
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
                        pageBuilder:
                            (dialogContext, animation, secondaryAnimation) {
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
                                  return LoadingAnimation(
                                    size: 30,
                                    isPlaying: playing,
                                  );
                                },
                              ),
                              onEpisodeLongPress: (episode) {
                                _updateEpisodeWatched(
                                  dialogContext,
                                  container,
                                  episode,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: Text(l10n.episodeSelection),
                  );
                }),

                //超分辨率
                if (isWideScreen || fullscreen)
                  Consumer(
                    builder: (context, ref, child) {
                      ref.watch(
                          playStateProvider.select((state) => state.kernel));
                      final upscalePreset = ref.watch(
                        playStateProvider.select(
                          (state) => state.upscalePreset,
                        ),
                      );
                      final capabilities =
                          playController.playbackCoordinator.capabilities;
                      final enabled = upscalePreset.isEnabled &&
                          capabilities.supportsUpscalePreset(upscalePreset);
                      return JellyMenu<VoidCallback>(
                        tooltip: '4K',
                        preferredVerticalDirection: VerticalDirection.up,
                        triggerColor: enabled
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5)
                            : Colors.transparent,
                        triggerBuilder: (_, open) =>
                            UpscaleButton(onPressed: open),
                        menuBuilder: (_, select) =>
                            _menuContent(buildUpscaleMenuItems(
                          context,
                          value: upscalePreset,
                          capabilities: capabilities,
                          onChanged: playController.setUpscalePreset,
                          onActivate: select,
                        )),
                        onSelected: (apply) => apply(),
                        onOpenChanged: onMenuOpenChanged,
                      );
                    },
                  ),

                if (isWideScreen || fullscreen) ...[
                  //倍速按钮
                  Consumer(
                    builder: (context, ref, child) {
                      final rate = ref.watch(
                        playStateProvider.select((state) => state.rate),
                      );
                      return JellyMenu<double>(
                        tooltip: l10n.playbackRate,
                        triggerColor: Colors.transparent,
                        preferredVerticalDirection: VerticalDirection.up,
                        triggerResizeDuration:
                            const Duration(milliseconds: 200),
                        triggerBuilder: (_, open) =>
                            RateButton(value: rate, onPressed: open),
                        menuBuilder: (context, select) => _menuContent([
                          for (final speed in RateButton.speeds)
                            _menuOption(
                              context,
                              label: '${speed}x',
                              isSelected: rate == speed,
                              onPressed: () => select(speed),
                            ),
                        ]),
                        onSelected: playController.setPlaybackRate,
                        onOpenChanged: onMenuOpenChanged,
                      );
                    },
                  ),
                  // 画面填充按钮
                  Consumer(
                    builder: (context, ref, child) {
                      final videoFit = ref
                          .watch(playStateProvider.select((s) => s.videoFit));
                      return JellyMenu<VideoFit>(
                        tooltip: _videoFitLabel(l10n, videoFit),
                        triggerColor: Colors.transparent,
                        preferredVerticalDirection: VerticalDirection.up,
                        triggerBuilder: (_, open) => FitButton(onPressed: open),
                        menuBuilder: (context, select) => _menuContent([
                          for (final fit in VideoFit.values)
                            _menuOption(
                              context,
                              label: _videoFitLabel(l10n, fit),
                              isSelected: videoFit == fit,
                              onPressed: () => select(fit),
                            ),
                        ]),
                        onSelected:
                            ref.read(playStateProvider.notifier).setVideoFit,
                        onOpenChanged: onMenuOpenChanged,
                      );
                    },
                  ),
                ],

                // 全屏按钮
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  child: IconButton(
                      onPressed: () {
                        videoUiStateController.toggleFullScreen();
                      },
                      padding: const EdgeInsets.all(0),
                      icon: Icon(
                        fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        size: 33,
                        color: Colors.white70,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

@Dependencies([VideoUiNotifier, PlayStateNotifier])
class _MiniProgressBarVisibility extends ConsumerWidget {
  const _MiniProgressBarVisibility({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useWideOffset = ref.watch(
      videoUiProvider
          .select((state) => state.isFullscreen || state.isWideScreen),
    );
    final offset = useWideOffset ? 50.0 : 30.0;
    return IgnorePointer(
      child: ExcludeSemantics(
        excluding: !visible,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: visible ? 1 : 0, end: visible ? 1 : 0),
          duration: const Duration(milliseconds: 200),
          curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
          builder: (context, value, child) => ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: value,
              child: Transform.translate(
                offset: Offset(0, -offset * (1 - value)),
                child: child,
              ),
            ),
          ),
          child: const _MiniProgressBar(),
        ),
      ),
    );
  }
}

@Dependencies([PlayStateNotifier])
class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      playStateProvider.select((state) => (
            duration: state.duration,
            position: state.position,
            buffered: state.buffered,
          )),
    );
    return MiniPlayerProgressBar(
      duration: progress.duration,
      position: progress.position,
      buffered: progress.buffered,
    );
  }
}

@Dependencies([DanmakuStateNotifier, playSession, VideoUiNotifier])
class _DanmakuInputField extends ConsumerWidget {
  const _DanmakuInputField();

  Future<void> _onSend(
    BuildContext context,
    PlaySession playController,
    String text,
    int type,
    Color color,
  ) async {
    final success = await playController.danmaku
        .send(text, type: type, color: color.toARGB32());
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (!success) {
      NotificationToast.show(l10n.danmakuUnsupported, title: '提示');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danmakuOn =
        ref.watch(danmakuStateProvider.select((state) => state.enabled));
    if (!danmakuOn) return const SizedBox.shrink();
    final userId = ref.watch(
      currentUserInfoProvider.select((state) => state.value?.id),
    );
    if (userId != null) {
      final playController = ref.read(playSessionProvider);
      final videoUiStateController = ref.read(videoUiProvider.notifier);
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
        onSend: (message, type, color) =>
            _onSend(context, playController, message, type, color),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
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
}
