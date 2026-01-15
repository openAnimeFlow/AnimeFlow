import 'package:anime_flow/stores/subject_state.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/play_content/source_drawers/video_source_drawers.dart';
import 'package:anime_flow/controllers/video/data/video_source_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class VideoResourcesView extends StatefulWidget {

  const VideoResourcesView(
      {super.key});

  @override
  State<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends State<VideoResourcesView> {
  late VideoSourceController dataSourceController;
  late SubjectState subjectStateController;

  @override
  void initState() {
    super.initState();
    dataSourceController = Get.find<VideoSourceController>();
    subjectStateController = Get.find<SubjectState>();
    
    // 检查资源是否已经为当前关键词初始化过，避免全屏切换时重复初始化
    final currentKeyword = subjectStateController.name;
    if (dataSourceController.keyword.value != currentKeyword) {
      // 只有当关键词不同时才重新初始化
      dataSourceController.initResources(currentKeyword);
    }
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
                      const Text(
                        '数据源',
                        style: TextStyle(
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
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: "SourceDrawer",
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
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return const VideoSourceDrawers();
                      },
                    );
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
