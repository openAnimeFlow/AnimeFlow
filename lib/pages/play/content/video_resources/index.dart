import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/pages/play/content/video_resources/video_source_drawers.dart';
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
  bool _isSourceDrawerExpanded = false; // 控制源抽屉是否展开
  final GlobalKey _videoSourceKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    dataSourceController = Get.find<DataSourceController>();
    playPageController = Get.find<PlayPageController>();
    dataSourceController.initResources(widget.subjectBasicData.name);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
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
                                      url: dataSourceController.webSiteIcon.value),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  dataSourceController.webSiteTitle.value,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold),
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
                    setState(() {
                      _isSourceDrawerExpanded = !_isSourceDrawerExpanded;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  icon: Icon(_isSourceDrawerExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.sync_alt_rounded),
                  label: Text(_isSourceDrawerExpanded ? "收起" : "切换源"),
                ),
              ],
            ),
          ),
          // 展开/收起动画 - 始终挂载 VideoSourceDrawers，通过高度控制显示
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isSourceDrawerExpanded
                  ? Container(
                    color: Colors.black12,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: VideoSourceDrawers(
                        key: _videoSourceKey,
                        isEmbedded: true,
                        onClose: () {
                          setState(() {
                            _isSourceDrawerExpanded = false;
                          });
                        },
                      ),
                    )
                  : SizedBox(
                      height: 0,
                      child: VideoSourceDrawers(
                        key: _videoSourceKey,
                        isEmbedded: true,
                        onClose: () {
                          setState(() {
                            _isSourceDrawerExpanded = false;
                          });
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
