import 'package:anime_flow/components/play_content/source_drawers/video_source_drawers.dart';
import 'package:anime_flow/controllers/video/video_source_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class VideoResourcesView extends StatefulWidget {
  final String title;

  const VideoResourcesView({super.key, required this.title});

  @override
  State<VideoResourcesView> createState() => _VideoResourcesViewState();
}


class _VideoResourcesViewState extends State<VideoResourcesView> {
  late VideoSourceController videoSourceController;


  @override
  void initState() {
    super.initState();
    videoSourceController = Get.find<VideoSourceController>();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  Obx(() => videoSourceController.webSiteName.value != ''
                      ? Text(
                          videoSourceController.webSiteName.value,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : const Text('选择数据源')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                Get.generalDialog(
                    barrierDismissible: true,
                    barrierLabel: "SourceDrawer",
                    barrierColor: Colors.black54,
                    transitionDuration: const Duration(milliseconds: 300),
                    // 动画
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
                      return VideoSourceDrawers(
                        widget.title,
                      );
                    });
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
    );
  }
}
