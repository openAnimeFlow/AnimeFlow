import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/features/network_speed/network_speed_provider.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_source_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/pages/play/video/ui/setting/video_setting.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/battery_icon.dart';
import 'package:anime_flow/widget/network_icon.dart';
import 'package:anime_flow/widget/play_content/source_drawers/video_source_drawers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

/// 顶部区域空间
class TopAreaControl extends ConsumerStatefulWidget {
  const TopAreaControl({super.key});

  @override
  ConsumerState<TopAreaControl> createState() => _TopAreaControlState();
}

class _TopAreaControlState extends ConsumerState<TopAreaControl> {
  final setting = Storage.setting;
  late final PlaySession playController;
  late int _skipDuration;

  VideoSourceNotifier get videoSourceController =>
      ref.read(videoSourceProvider.notifier);

  @override
  void initState() {
    super.initState();
    playController = ref.read(playSessionProvider);
    _skipDuration = setting.get(PlaybackKey.skipDuration, defaultValue: 85);
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
    final videoUiStateController =
        ref.read(videoUiProvider.notifier);
    final isShowControlsUi = ref.watch(
        videoUiProvider.select((s) => s.isShowControlsUi));
    final fullscreen =
        ref.watch(playStateProvider.select((s) => s.isFullscreen));
    final leftPadding = MediaQuery.of(context).padding.left;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isShowControlsUi
          ? Container(
              key: ValueKey<bool>(
                isShowControlsUi,
              ),
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
                    //Obx细粒度更新机制,只有直接访问了响应式变量的Obx才会被触发重建。
                    if (fullscreen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        height: 16,
                        child: _buildTopInfoBar(),
                      ),
                    Row(
                      children: [
                        //左侧
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: fullscreen ? '退出全屏' : '返回',
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
                                      final subjectName = ref.watch(
                                          playExtraProvider.select(
                                              (e) => e.playExtra.subjectName));
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
                                                state.asData?.value
                                                    .episodeTitle ??
                                                ''));
                                        final episodeSort = ref.watch(
                                            episodesProvider.select((state) =>
                                                state.asData?.value
                                                    .episodeSort ??
                                                0));
                                        if (episodeTitle.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Row(
                                          children: [
                                            Text(
                                              episodeSort
                                                  .toString()
                                                  .padLeft(2, '0'),
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
                            final position = ref.watch(
                                playStateProvider.select((s) => s.position));
                            final isWideScreen = ref.watch(playStateProvider
                                .select((s) => s.isWideScreen));
                            return Row(
                              children: [
                                if (position > Duration.zero &&
                                    (isWideScreen || fullscreen)) ...[
                                  Tooltip(
                                    message: '跳过 $_skipDuration 秒',
                                    child: IconButton(
                                      onPressed: () => playController.seekTo(
                                        position +
                                            Duration(seconds: _skipDuration),
                                      ),
                                      icon: SvgPicture.asset(
                                        AssetsPathConstants.blockGrove,
                                        width: 25,
                                        height: 25,
                                        colorFilter: const ColorFilter.mode(
                                            Colors.white70, BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: '设置',
                                    onPressed: () {
                                      _showRightSlideDialog(
                                        barrierDismissible: true,
                                        context: context,
                                        barrierLabel: 'VideoSetting',
                                        child: const VideoSetting(),
                                      );
                                    },
                                    icon: const Icon(
                                      size: 29,
                                      color: Colors.white70,
                                      Icons.settings_outlined,
                                    ),
                                  ),
                                ],
                                if (fullscreen)
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final subjectName = ref.watch(
                                          playExtraProvider.select(
                                              (e) => e.playExtra.subjectName));
                                      return IconButton(
                                        padding: const EdgeInsets.all(0),
                                        onPressed: () {
                                          _showRightSlideDialog(
                                            context: context,
                                            barrierLabel: 'SourceDrawer',
                                            barrierDismissible: true,
                                            child: VideoSourceDrawers(
                                              onVideoUrlSelected: (url) {
                                                playController.player.stop();
                                                videoSourceController
                                                    .loadVideoPage(url);
                                                videoUiStateController
                                                    .updateIndicatorType(
                                                        VideoControlsIndicatorType
                                                            .parsingIndicator);
                                                videoUiStateController
                                                    .updateMainAxisAlignmentType(
                                                        MainAxisAlignment
                                                            .center);
                                                videoUiStateController
                                                    .showIndicator();
                                              },
                                              isBottomSheet: false,
                                              videoSourceController:
                                                  videoSourceController,
                                              subjectName: subjectName,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.reset_tv_outlined,
                                          size: 29,
                                          color: Colors.white70,
                                        ),
                                      );
                                    },
                                  ),
                                if (SystemUtil.isDesktop && !fullscreen)
                                  isWideScreen
                                      ? Consumer(
                                          builder: (context, ref, child) {
                                            final isContentExpanded = ref.watch(
                                                playStateProvider.select((s) =>
                                                    s.isContentExpanded));
                                            return IconButton(
                                              onPressed: () => playController
                                                  .toggleContentExpanded(),
                                              padding: const EdgeInsets.all(0),
                                              icon: AnimatedRotation(
                                                turns:
                                                    isContentExpanded ? 0 : 0.5,
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                child: SvgPicture.asset(
                                                  AssetsPathConstants
                                                      .rightPanelClose,
                                                  width: 30,
                                                  height: 30,
                                                  colorFilter:
                                                      const ColorFilter.mode(
                                                    Colors.white70,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : const SizedBox.shrink()
                              ],
                            );
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            )
          : SizedBox.shrink(
              key: ValueKey<bool>(
                isShowControlsUi,
              ),
            ),
    );
  }

  ///顶部信息栏
  Widget _buildTopInfoBar() {
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
                return Builder(
                  builder: (context) {
                    final speedAsync =
                        ref.watch(networkSpeedStreamProvider(2000));
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
                  },
                );
              })
            ],
          ),
        ),
        //系统时间
        Consumer(
          builder: (context, ref, child) {
            final currentTime = ref.watch(
              videoUiProvider
                  .select((state) => state.currentTime),
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
        //电池图标
        if (SystemUtil.isMobile)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final battery = ref.watch(
                  videoUiProvider
                      .select((state) => state.batteryLevel),
                );
                final batteryState = ref.watch(
                  videoUiProvider
                      .select((state) => state.batteryState),
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$battery%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    BatteryIcon(
                      size: 25,
                      battery: battery,
                      batteryState: batteryState,
                      angle: 90,
                    ),
                  ],
                );
              },
            ),
          )
        else
          const Spacer()
      ],
    );
  }
}
