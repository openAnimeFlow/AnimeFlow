import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// 顶部区域空间
class TopAreaControl extends StatelessWidget {
  final String subjectName;

  const TopAreaControl({
    super.key,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    bool fullscreen = isFullscreen(context);
    final playPageController = Get.find<PlayController>();
    final videoUiStateController = Get.find<VideoUiStateController>();
    final episodesController = Get.find<EpisodesController>();

    return Obx(() => AnimatedSwitcher(
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
                        left: MediaQuery.of(context).padding.left,
                        right: 5,
                        top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          IconButton(
                            padding: const EdgeInsets.all(0),
                              onPressed: () {
                                Get.back();
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white.withValues(alpha: 0.8),
                              )),
                          const SizedBox(width: 5),
                          if (Utils.isDesktop || fullscreen)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subjectName,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
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
                                            episodesController
                                                .episodeTitle.value,
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
                                      icon: playPageController
                                              .isContentExpanded.value
                                          ? SvgPicture.asset(
                                              "assets/icons/right_panel_close.svg",
                                              width: 30,
                                              height: 30,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                Colors.white70,
                                                BlendMode.srcIn,
                                              ),
                                            )
                                          : SvgPicture.asset(
                                              "assets/icons/left_panel_close.svg",
                                              width: 30,
                                              height: 30,
                                              colorFilter:
                                                  const ColorFilter.mode(
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
        ));
  }
}
