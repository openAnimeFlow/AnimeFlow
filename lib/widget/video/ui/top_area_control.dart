import 'package:anime_flow/controllers/video/source/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/play_content/source_drawers/video_source_drawers.dart';
import 'package:anime_flow/widget/video/ui/video_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

/// 顶部区域空间
class TopAreaControl extends StatefulWidget {
  const TopAreaControl({super.key});

  @override
  State<TopAreaControl> createState() => _TopAreaControlState();
}

class _TopAreaControlState extends State<TopAreaControl> {
  late VideoStateController videoStateController;
  late VideoSourceController videoSourceController;

  late PlayController playPageController;
  late VideoUiStateController videoUiStateController;
  late EpisodesState episodesController;
  late PlaySubjectState subjectStateController;

  @override
  void initState() {
    super.initState();
    videoStateController = Get.find<VideoStateController>();
    videoSourceController = Get.find<VideoSourceController>();
    playPageController = Get.find<PlayController>();
    videoUiStateController = Get.find<VideoUiStateController>();
    episodesController = Get.find<EpisodesState>();
    subjectStateController = Get.find<PlaySubjectState>();
  }

  @override
  Widget build(BuildContext context) {
    final leftPadding = MediaQuery.of(context).padding.left;
    return Obx(() {
      // 全屏状态
      final fullscreen = playPageController.isFullscreen.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: videoUiStateController.isShowControlsUi.value
            ? Container(
                key: ValueKey<bool>(
                    videoUiStateController.isShowControlsUi.value),
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.black45, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left:  5,
                      right: 5,
                      top: 2),
                  child: Column(
                    children: [
                      if (fullscreen) ...[
                        SizedBox(
                          height: 18,
                          child: Row(
                            children: [
                              //Obx细粒度更新机制,只有直接访问了响应式变量的Obx才会被触发重建。
                              const Spacer(),
                              const SizedBox(width: 12),
                              Obx(
                                () => Text(
                                  videoUiStateController.currentTime.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Obx(
                                  () {
                                    final battery = videoUiStateController
                                        .batteryLevel.value;
                                    final batteryState = videoUiStateController
                                        .batteryState.value;

                                    return Row(

                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${videoUiStateController.batteryLevel.value}%',
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
                            ],
                          ),
                        ),
                      ],
                      Row(
                        children: [
                          //左侧
                          Expanded(
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (fullscreen) {
                                      playPageController.exitFullScreen();
                                    } else {
                                      Get.back();
                                    }
                                  },
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                if (Utils.isDesktop || fullscreen)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subjectStateController.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      episodesController.episodeTitle.value !=
                                              ''
                                          ? Row(
                                              children: [
                                                Text(
                                                  episodesController
                                                      .episodeSort.value
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  episodesController
                                                      .episodeTitle.value,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15),
                                                )
                                              ],
                                            )
                                          : const SizedBox.shrink()
                                    ],
                                  )
                              ],
                            ),
                          ),
                          //右侧
                          Row(
                            children: [
                              if (fullscreen)
                                IconButton(
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {
                                    Get.generalDialog(
                                      barrierDismissible: true,
                                      barrierLabel: "SourceDrawer",
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
                                        return VideoSourceDrawers(
                                          onVideoUrlSelected: (url) {
                                            videoStateController.player.stop();
                                            videoSourceController
                                                .loadVideoPage(url);
                                          },
                                          isBottomSheet: false,
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Icons.reset_tv_outlined,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              if (Utils.isDesktop)
                                Obx(() => playPageController.isWideScreen.value
                                    ? IconButton(
                                        onPressed: () => playPageController
                                            .toggleContentExpanded(),
                                        padding: const EdgeInsets.all(0),
                                        icon: SvgPicture.asset(
                                          playPageController
                                                  .isContentExpanded.value
                                              ? "assets/icons/right_panel_close.svg"
                                              : "assets/icons/left_panel_close.svg",
                                          width: 30,
                                          height: 30,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.white70,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink())
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox.shrink(
                key: ValueKey<bool>(
                    videoUiStateController.isShowControlsUi.value),
              ),
      );
    });
  }
}
