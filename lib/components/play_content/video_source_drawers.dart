import 'package:anime_flow/components/image/animation_network_image.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/video/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/data/crawler/html_request.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class VideoSourceDrawers extends StatefulWidget {
  final String title;
  final List<ResourcesItem> videoResources;

  const VideoSourceDrawers(this.title,
      {super.key, required this.videoResources});

  @override
  State<VideoSourceDrawers> createState() => _VideoSourceDrawersState();
}

class _VideoSourceDrawersState extends State<VideoSourceDrawers> {
  late VideoSourceController videoSourceController;
  late VideoStateController videoStateController;
  late EpisodesController episodesController;
  final logger = Logger();
  bool isShowEpisodes = false;
  int selectedWebsiteIndex = 0; // 当前选中的网站索引

  @override
  void initState() {
    super.initState();
    videoStateController = Get.find<VideoStateController>();
    videoSourceController = Get.find<VideoSourceController>();
    episodesController = Get.find<EpisodesController>();
  }

  void setShowEpisodes() {
    setState(() {
      isShowEpisodes = !isShowEpisodes;
    });
  }

  void setSelectedWebsite(int index) {
    setState(() {
      selectedWebsiteIndex = index;
      isShowEpisodes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: PlayLayoutConstant.playContentWidth,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Theme
            .of(context)
            .cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: MediaQuery
                  .of(context)
                  .padding
                  .top),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.color,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 网站选择器
            _buildWebsiteSelector(),
            const SizedBox(height: 16),
            // 剧集列表
            Expanded(
              child: Material(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 0),
                  itemCount: widget.videoResources[selectedWebsiteIndex]
                      .episodeResources.length,
                  itemBuilder: (context, index) {
                    final resourceItem = widget
                        .videoResources[selectedWebsiteIndex]
                        .episodeResources[index];
                    final isLastItem = index ==
                        widget.videoResources[selectedWebsiteIndex]
                            .episodeResources.length -
                            1;

                    // 使用 Obx 包裹每个列表项，监听 episodeIndex 变化
                    return Obx(() {
                      // 当前选中剧集对应的剧集数据
                      final currentEpisode =
                      resourceItem.episodes.firstWhereOrNull(
                            (ep) =>
                        ep.episodeSort ==
                            episodesController.episodeIndex.value,
                      );


                      final excludedEpisodesCount = widget
                          .videoResources[selectedWebsiteIndex].episodeResources
                          .expand((item) =>
                          item.episodes.where((ep) =>
                          ep.episodeSort !=
                              episodesController.episodeIndex.value))
                          .length;

                      // 如果当前资源组没有匹配的剧集，不渲染
                      if (currentEpisode == null) {
                        return SizedBox.shrink();
                      }

                      // 只渲染当前选中的剧集
                      return Column(
                        children: [
                          _buildVideoSource(
                            currentEpisode,
                            resourceItem,
                            widget.videoResources[selectedWebsiteIndex]
                                .videoConfig,
                          ),

                          // 在最后一项后显示开关按钮
                          if (isLastItem) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '显示已被排除的资源($excludedEpisodesCount)',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(width: 8),
                                  Switch(
                                    value: isShowEpisodes,
                                    onChanged: (value) {
                                      setShowEpisodes();
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // 当开关打开时，显示所有资源的所有其他剧集
                            if (isShowEpisodes)
                              ...widget.videoResources[selectedWebsiteIndex]
                                  .episodeResources
                                  .expand((item) {
                                // 获取该资源的所有非当前集数的剧集
                                final excludedEpisodes = item.episodes
                                    .where(
                                      (ep) =>
                                  ep.episodeSort !=
                                      episodesController.episodeIndex.value,
                                )
                                    .toList();
                                // 遍历所有其他剧集
                                return excludedEpisodes.map(
                                      (excludedEpisode) =>
                                      _buildVideoSource(
                                        excludedEpisode,
                                        item,
                                        widget
                                            .videoResources[selectedWebsiteIndex]
                                            .videoConfig,
                                      ),
                                );
                              }),
                          ],
                        ],
                      );
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSource(Episode episode,
      EpisodeResourcesItem item,
      dynamic videoConfig,) {
    return Card.filled(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          try {
            videoSourceController.setWebSiteName(
                widget.videoResources[selectedWebsiteIndex].websiteName);
            Get.back();
            videoStateController.disposeVideo();
            final videoUrl = await WebRequest.getVideoSourceService(
              episode.like,
              videoConfig,
            );
            videoSourceController.setVideoUrl(videoUrl);
            Get.snackbar(
              '视频资源解析成功',
              '',
              duration: Duration(seconds: 2),
              maxWidth: 300,
            );
          } catch (e) {
            logger.e('获取视频源失败: $e');
            if (Get.isDialogOpen == true) {
              Get.back();
            }
            Get.snackbar(
              '错误',
              '获取视频源失败: $e',
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red.shade100,
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.subjectsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '第${episode.episodeSort}集',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '线路:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    item.lineNames,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Icon(Icons.link, size: 20, color: Colors.grey),
                  Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 数据源选择器
  Widget _buildWebsiteSelector() {
    return SizedBox(
        height: 40,
        child: Row(
          children: [
            Icon(
              Icons.public,
              size: 24,
              color: Theme
                  .of(context)
                  .colorScheme
                  .onSurface,
            ),
            SizedBox(width: 8),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.videoResources.length,
                itemBuilder: (context, index) {
                  final resource = widget.videoResources[index];
                  final isSelected = selectedWebsiteIndex == index;

                  return Obx(() {
                    final currentEpisodeCount = resource.episodeResources
                        .where((item) =>
                        item.episodes.any((ep) =>
                        ep.episodeSort ==
                            episodesController.episodeIndex.value))
                        .length;

                    return GestureDetector(
                      onTap: () => setSelectedWebsite(index),
                      child: Container(
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme
                              .of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              : Theme
                              .of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme
                                .of(context)
                                .colorScheme
                                .primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: AnimationNetworkImage(
                                  width: 24,
                                  height: 24,
                                  url: resource.websiteIcon),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${resource.websiteName}($currentEpisodeCount)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme
                                      .of(context)
                                      .colorScheme
                                      .primary
                                      : Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface,
                                  decoration: TextDecoration.none),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            )
          ],
        ));
  }
}
