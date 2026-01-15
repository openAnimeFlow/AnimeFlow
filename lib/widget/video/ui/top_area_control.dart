import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/stores/subject_state.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

/// 顶部区域空间
class TopAreaControl extends StatelessWidget {
  const TopAreaControl({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playPageController = Get.find<PlayController>();
    final videoUiStateController = Get.find<VideoUiStateController>();
    final episodesController = Get.find<EpisodesState>();
    final subjectStateController = Get.find<SubjectState>();
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
                  padding: EdgeInsets.only(
                      left: leftPadding != 0 ? leftPadding : 5,
                      right: 5,
                      top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectStateController.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              episodesController.episodeTitle.value != ''
                                  ? Row(
                                      children: [
                                        Text(
                                          episodesController.episodeSort.value
                                              .toString()
                                              .padLeft(2, '0'),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          episodesController.episodeTitle.value,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15),
                                        )
                                      ],
                                    )
                                  : const SizedBox.shrink()
                            ],
                          )
                      ]),
                      //右侧
                      Row(
                        children: [
                          IconButton(
                            padding: const EdgeInsets.all(0),
                            onPressed: () {},
                            icon: Icon(
                              Icons.settings,
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
                                      playPageController.isContentExpanded.value
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
