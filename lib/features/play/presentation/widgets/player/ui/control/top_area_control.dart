import 'package:anime_flow/features/auth/auth_api.dart';
import 'dart:async';

import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network_speed/network_speed_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_online_count_provider.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/setting/video_setting_dialog.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/widgets/ios_battery_icon.dart';
import 'package:anime_flow/shared/widgets/network_icon.dart';
import 'package:anime_flow/shared/widgets/collection_button.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/features/play/presentation/widgets/source_drawers/video_source_drawers.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

/// 顶部区域控件
class TopAreaControl extends ConsumerStatefulWidget {
  const TopAreaControl({super.key});

  @override
  ConsumerState<TopAreaControl> createState() => _TopAreaControlState();
}

class _TopAreaControlState extends ConsumerState<TopAreaControl> {
  late final PlaySession playController;
  late int _skipDuration;

  VideoSourceNotifier get videoSourceController =>
      ref.read(videoSourceProvider.notifier);

  @override
  void initState() {
    super.initState();
    playController = ref.read(playSessionProvider);
    _skipDuration = AppSettings.skipDuration;
  }

  Future<T?> _showRightSlideDialog<T>({
    required BuildContext context,
    required String barrierLabel,
    required Widget child,
    bool barrierDismissible = false,
  }) {
    final container = ProviderScope.containerOf(context);
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return UncontrolledProviderScope(
          container: container,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final videoUiStateController = ref.read(videoUiProvider.notifier);
    final isShowControlsUi =
        ref.watch(videoUiProvider.select((s) => s.isShowControlsUi));
    final fullscreen =
        ref.watch(playStateProvider.select((s) => s.isFullscreen));
    final leftPadding = MediaQuery.of(context).padding.left;
    // Keep the subtree mounted across auto-hide so stream subscriptions survive.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: isShowControlsUi ? 1 : 0,
        end: isShowControlsUi ? 1 : 0,
      ),
      duration: const Duration(milliseconds: 200),
      curve: isShowControlsUi ? Curves.easeOutCubic : Curves.easeInCubic,
      builder: (context, value, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: value,
            child: Transform.translate(
              offset: Offset(0, -12 * (1 - value)),
              child: IgnorePointer(
                ignoring: !isShowControlsUi,
                child: ExcludeSemantics(
                  excluding: !isShowControlsUi,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black45, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: leftPadding <= 0 ? 5 : leftPadding,
            right: 5,
            top: 2,
          ),
          child: Column(
            children: [
              //全屏时顶部信息展示
              if (fullscreen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  height: 16,
                  child: _buildTopInfoBar(context),
                ),
              Row(
                children: [
                  //左侧
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: fullscreen ? l10n.exitFullscreen : l10n.back,
                          onPressed: () {
                            if (fullscreen) {
                              playController.exitFullScreen();
                            } else {
                              context.pop();
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (SystemUtil.isDesktop || fullscreen)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer(builder: (context, ref, child) {
                                final subjectName = ref.watch(playExtraProvider
                                    .select((e) => e.playExtra.subjectName));
                                return Text(
                                  subjectName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }),
                              Consumer(
                                builder: (context, ref, child) {
                                  final episodeTitle = ref.watch(
                                      episodesProvider.select((state) =>
                                          state.asData?.value.episodeTitle ??
                                          ''));
                                  final episodeSort = ref.watch(
                                      episodesProvider.select((state) =>
                                          state.asData?.value.episodeSort ??
                                          0));
                                  if (episodeTitle.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Row(
                                    children: [
                                      Text(
                                        episodeSort.toString().padLeft(2, '0'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        episodeTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      )
                                    ],
                                  );
                                },
                              )
                            ],
                          )
                      ],
                    ),
                  ),
                  //右侧
                  Consumer(
                    builder: (context, ref, child) {
                      final isWideScreen = ref.watch(
                        playStateProvider.select((s) => s.isWideScreen),
                      );
                      final isContentExpanded = ref.watch(
                        playStateProvider.select((s) => s.isContentExpanded),
                      );
                      final showContentActions = fullscreen ||
                          (SystemUtil.isDesktop &&
                              isWideScreen &&
                              !isContentExpanded);
                      return Row(
                        children: [
                          if (isWideScreen || fullscreen)
                            _SkipButton(skipDuration: _skipDuration),
                          if (showContentActions)
                            const _CollectionControlButton(),
                          if (showContentActions)
                            IconButton(
                              tooltip: l10n.settings,
                              onPressed: () {
                                _showRightSlideDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  barrierLabel: 'VideoSetting',
                                  child: const VideoSettingDialog(),
                                );
                              },
                              icon: const Icon(
                                size: 29,
                                color: Colors.white,
                                Icons.settings_outlined,
                              ),
                            ),
                          if (fullscreen)
                            Consumer(
                              builder: (context, ref, child) {
                                final subjectName = ref.watch(playExtraProvider
                                    .select((e) => e.playExtra.subjectName));
                                return IconButton(
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {
                                    _showRightSlideDialog(
                                      context: context,
                                      barrierLabel: 'SourceDrawer',
                                      barrierDismissible: true,
                                      child: VideoSourceDrawers(
                                        onVideoUrlSelected: (url) {
                                          unawaited(playController.stop());
                                          videoSourceController
                                              .loadVideoPage(url);
                                          videoUiStateController
                                              .showParsingIndicator();
                                        },
                                        isBottomSheet: false,
                                        videoSourceNotifier:
                                            videoSourceController,
                                        subjectName: subjectName,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.reset_tv_outlined,
                                    size: 29,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          if (SystemUtil.isDesktop &&
                              !fullscreen &&
                              isWideScreen)
                            IconButton(
                              onPressed: () =>
                                  playController.toggleContentExpanded(),
                              padding: const EdgeInsets.all(0),
                              icon: AnimatedRotation(
                                turns: isContentExpanded ? 0 : 0.5,
                                duration: const Duration(milliseconds: 300),
                                child: SvgPicture.asset(
                                  AssetsPathConstants.rightPanelClose,
                                  width: 30,
                                  height: 30,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///顶部信息栏
  Widget _buildTopInfoBar(BuildContext context) {
    return Row(
      children: [
        //网络图标
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 5,
            children: [
              const NetworkIcon(),
              Consumer(builder: (context, ref, child) {
                final speedAsync = ref.watch(networkSpeedStreamProvider(2000));
                final data = speedAsync.asData?.value;
                final download = data?.download ?? 0;
                final upload = data?.upload ?? 0;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (download > 0) ...[
                      const RotatedBox(
                        quarterTurns: 1,
                        child: Icon(
                          Icons.arrow_right_alt_outlined,
                          size: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        Utils.formatBytesPerSec(download),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    if (upload > 0) ...[
                      const RotatedBox(
                        quarterTurns: 3,
                        child: Icon(
                          Icons.arrow_right_alt_outlined,
                          size: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        Utils.formatBytesPerSec(upload),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ],
                );
              })
            ],
          ),
        ),
        //系统时间
        Consumer(
          builder: (context, ref, child) {
            final currentTime = ref.watch(
              videoUiProvider.select((state) => state.currentTime),
            );
            return Text(
              currentTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const _OnlineCountIndicator(),
              if (SystemUtil.isMobile) ...[
                const SizedBox(width: 8),
                //电池图标
                Consumer(
                  builder: (context, ref, child) {
                    final battery = ref.watch(
                      videoUiProvider.select((state) => state.batteryLevel),
                    );
                    final batteryState = ref.watch(
                      videoUiProvider.select((state) => state.batteryState),
                    );
                    final isCharging = batteryState == BatteryState.charging;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IosBatteryIcon(
                          batteryLevel: battery,
                          isCharging: isCharging,
                          size: 35,
                        ),
                        if (isCharging)
                          const Icon(Icons.flash_on_outlined,
                              size: 13, color: IosBatteryIcon.chargingColor),
                      ],
                    );
                  },
                ),
              ]
            ],
          ),
        )
      ],
    );
  }
}

class _SkipButton extends ConsumerWidget {
  const _SkipButton({required this.skipDuration});

  final int skipDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Progress updates only affect visibility when crossing zero.
    final hasPosition = ref.watch(
      playStateProvider.select((state) => state.position > Duration.zero),
    );
    if (!hasPosition) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.skipSeconds(skipDuration),
      child: IconButton(
        onPressed: () {
          final position = ref.read(playStateProvider).position;
          ref.read(playSessionProvider).seekTo(
                position + Duration(seconds: skipDuration),
              );
          ref.read(videoUiProvider.notifier).restartControlsAutoHideTimer();
        },
        icon: SvgPicture.asset(
          AssetsPathConstants.blockGrove,
          width: 25,
          height: 25,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _CollectionControlButton extends ConsumerWidget {
  const _CollectionControlButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(
      isLoggedInProvider.select((state) => state.value ?? false),
    );
    if (!isLoggedIn) return const SizedBox.shrink();

    final collection = ref.watch(
      animeInfoProvider.select((state) {
        final subject = state.asData?.value;
        return subject == null
            ? null
            : (id: subject.id, type: subject.interest?.type);
      }),
    );
    if (collection == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final collectType = collectTypeFromApiType(collection.type);
    final videoUiStateController = ref.read(videoUiProvider.notifier);
    return CollectionButton(
      key: ValueKey(collection.id),
      collectType: collectType,
      onMenuOpen: videoUiStateController.cancelUiTimer,
      onMenuClose: () => videoUiStateController.hideControlsUi(
        duration: const Duration(seconds: 2),
      ),
      buttonBuilder: (context, label, _, onPressed) {
        return IconButton(
          tooltip: label,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            collectType == null ? Icons.favorite_border : Icons.favorite,
            color: Colors.white,
            size: 29,
          ),
        );
      },
      onCollectTypeChanged: (newType) async {
        try {
          await ref
              .read(animeInfoProvider.notifier)
              .updateCollectionType(newType.value);
        } on AnimeFlowApiException catch (e) {
          NotificationToast.show(e.message, title: l10n.updateFailed);
          rethrow;
        } catch (e) {
          NotificationToast.show(e.toString(), title: l10n.updateFailed);
          rethrow;
        }
      },
    );
  }
}

class _OnlineCountIndicator extends ConsumerWidget {
  const _OnlineCountIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canShowOnlineCount = ref.watch(
      playExtraProvider.select(
        (state) => !state.isOfflineMode && state.playExtra.subjectId > 0,
      ),
    );
    if (!canShowOnlineCount) return const SizedBox.shrink();

    final onlineUsers = ref.watch(
      subjectOnlineCountProvider.select(
        (state) => state.asData?.value.onlineUsers,
      ),
    );
    if (onlineUsers == null || onlineUsers <= 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.totalWatchers,
      child: SizedBox(
        height: 18,
        child: Row(
          spacing: 2,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: Center(
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: 18,
              child: Center(
                child: Text(
                  onlineUsers.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
