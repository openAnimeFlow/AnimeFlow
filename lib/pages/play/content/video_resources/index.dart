import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/play_content/source_drawers/video_source_drawers.dart';
import 'package:anime_flow/controllers/video/data/data_source_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoResourcesView extends StatefulWidget {
  final String sourceTitle;
  final SubjectBasicData subjectBasicData;

  const VideoResourcesView(
      {super.key, required this.sourceTitle, required this.subjectBasicData});

  @override
  State<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends State<VideoResourcesView> {
  late DataSourceController dataSourceController;
  late PlayPageController playPageController;
  @override
  void initState() {
    super.initState();
    dataSourceController = Get.find<DataSourceController>();
    playPageController = Get.find<PlayPageController>();
    dataSourceController.initResources(widget.subjectBasicData.name);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Offstage(child: VideoSourceDrawers()),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sourceTitle,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Obx(() => !dataSourceController.isLoading.value
                          ? Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: AnimationNetworkImage(
                                      height: 25,
                                      width: 25,
                                      url: dataSourceController
                                          .webSiteIcon.value),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  dataSourceController.webSiteTitle.value,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            )
                          : const Row(
                              children: [
                                Text('自动选择资源中'),
                                SizedBox(width: 5),
                                SizedBox(
                                  height: 10,
                                  width: 10,
                                  child: CircularProgressIndicator(),
                                )
                              ],
                            )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    if (playPageController.isWideScreen.value) {
                      // 侧边抽屉
                      Get.generalDialog(
                        barrierDismissible: true,
                        barrierLabel: "SourceDrawer",
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return const VideoSourceDrawers();
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
                    } else {
                      // 底部抽屉
                      Get.bottomSheet(
                        const VideoSourceDrawers(isBottomSheet: true),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        isDismissible: true,
                        enableDrag: true,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: const Text("切换源"),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
