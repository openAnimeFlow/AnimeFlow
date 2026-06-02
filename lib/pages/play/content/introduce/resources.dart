import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_source_controller.dart';
import 'package:anime_flow/pages/play/provider/play_subject_provider.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/play_content/source_drawers/video_source_drawers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class VideoResourcesView extends ConsumerStatefulWidget {
  const VideoResourcesView({super.key});

  @override
  ConsumerState<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends ConsumerState<VideoResourcesView> {
  final videoSourceController = Get.find<VideoSourceController>();
  final playController = Get.find<PlayController>();

  void _showSourceDrawer() {
    void onVideoUrlSelected(String url) {
      playController.player.stop();
      videoSourceController.loadVideoPage(url);
    }

    final subjectName = ref.read(playSubjectProvider).subjectName;

    if (playController.isWideScreen.value) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "SourceDrawer",
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
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
        pageBuilder: (context, animation, secondaryAnimation) {
          return VideoSourceDrawers(
            isBottomSheet: false,
            onVideoUrlSelected: onVideoUrlSelected,
            videoSourceController: videoSourceController,
            subjectName: subjectName,
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return VideoSourceDrawers(
            isBottomSheet: true,
            onVideoUrlSelected: onVideoUrlSelected,
            videoSourceController: videoSourceController,
            subjectName: subjectName,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
                      Obx(() => videoSourceController.isLoading.value ||
                              videoSourceController.webSiteTitle.value.isNotEmpty
                          ? Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: AnimationNetworkImage(
                                    height: 25,
                                    width: 25,
                                    url: videoSourceController.webSiteIcon.value,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  videoSourceController.webSiteTitle.value,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                  onPressed: _showSourceDrawer,
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
