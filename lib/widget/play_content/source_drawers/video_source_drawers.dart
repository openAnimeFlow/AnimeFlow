import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/video/data/data_source_controller.dart';
import 'package:anime_flow/controllers/video/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/data/crawler/html_request.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class VideoSourceDrawers extends StatefulWidget {
  final String title;

  const VideoSourceDrawers(this.title, {super.key});

  @override
  State<VideoSourceDrawers> createState() => _VideoSourceDrawersState();
}

class _VideoSourceDrawersState extends State<VideoSourceDrawers> {
  late VideoSourceController videoSourceController;
  late VideoStateController videoStateController;
  late EpisodesController episodesController;
  late DataSourceController dataSourceController;
  late VideoUiStateController videoUiStateController;
  final logger = Logger();
  bool isShowEpisodes = false;
  int selectedWebsiteIndex = 0; // 当前选中的网站索引

  @override
  void initState() {
    super.initState();
    videoUiStateController = Get.find<VideoUiStateController>();
    videoStateController = Get.find<VideoStateController>();
    videoSourceController = Get.find<VideoSourceController>();
    episodesController = Get.find<EpisodesController>();
    dataSourceController = Get.find<DataSourceController>();
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
        color: Theme.of(context).cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
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
            // 网站选择器 - 使用 Obx 实现响应式渲染
            Obx(() => _buildWebsiteSelector(
                dataSource: dataSourceController.videoResources.value)),
            const SizedBox(height: 16),
            // 剧集列表 - 使用 Obx 实现响应式渲染
            Expanded(
              child: Obx(() => _buildVideoSource(
                  dataSource: dataSourceController.videoResources.value)),
            ),
          ],
        ),
      ),
    );
  }

  // 数据源选择器
  Widget _buildWebsiteSelector({required List<ResourcesItem> dataSource}) {
    return SizedBox(
        height: 40,
        child: Row(
          children: [
            Icon(
              Icons.public,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dataSource.length,
                    itemBuilder: (context, index) {
                      final data = dataSource[index];
                      final isSelected = selectedWebsiteIndex == index;

                      // final currentEpisodeCount = resource.episodeResources
                      //     .where((item) => item.episodes.any((ep) =>
                      //         ep.episodeSort ==
                      //         episodesController.episodeIndex.value))
                      //     .length;

                      return GestureDetector(
                        onTap: () => setSelectedWebsite(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
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
                                    url: data.websiteIcon),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                data.websiteName,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    decoration: TextDecoration.none),
                              ),
                              // 显示解析状态
                              if (data.isLoading) ...[
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ] else if (data.errorMessage != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ] else if (data.episodeResources.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    })),
          ],
        ));
  }

  Widget _buildVideoSource({required List<ResourcesItem> dataSource}) {
    return Material(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 0),
        itemCount: dataSource[selectedWebsiteIndex].episodeResources.length,
        itemBuilder: (context, index) {
          final resourceItem =
              dataSource[selectedWebsiteIndex].episodeResources[index];
          final isLastItem = index ==
              dataSource[selectedWebsiteIndex].episodeResources.length - 1;

          // 使用 Obx 包裹每个列表项，监听 episodeIndex 变化
          return Obx(() {
            // 当前选中剧集对应的剧集数据
            final currentEpisode = resourceItem.episodes.firstWhereOrNull(
              (ep) => ep.episodeSort == episodesController.episodeIndex.value,
            );

            final excludedEpisodesCount = dataSource[selectedWebsiteIndex]
                .episodeResources
                .expand((item) => item.episodes.where((ep) =>
                    ep.episodeSort != episodesController.episodeIndex.value))
                .length;

            // 如果当前资源组没有匹配的剧集，不渲染
            if (currentEpisode == null) {
              return const SizedBox.shrink();
            }

            // 只渲染当前选中的剧集
            return Column(
              children: [
                _buildSource(
                  currentEpisode,
                  resourceItem,
                  dataSource[selectedWebsiteIndex].videoConfig,
                  websiteName: dataSource[selectedWebsiteIndex].websiteName,
                  websiteIcon: dataSource[selectedWebsiteIndex].websiteIcon,
                ),

                // 在最后一项后显示开关按钮
                if (isLastItem) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '显示已被排除的资源($excludedEpisodesCount)',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
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
                    ...dataSource[selectedWebsiteIndex]
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
                        (excludedEpisode) => _buildSource(
                          excludedEpisode,
                          item,
                          dataSource[selectedWebsiteIndex].videoConfig,
                          websiteName:
                              dataSource[selectedWebsiteIndex].websiteName,
                          websiteIcon:
                              dataSource[selectedWebsiteIndex].websiteIcon,
                        ),
                      );
                    }),
                ],
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildSource(
      Episode episode, EpisodeResourcesItem item, VideoConfig videoConfig,
      {required String websiteName, required String websiteIcon}) {
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          try {
            Get.back();
            dataSourceController.setWebSite(
                title: websiteName, iconUrl: websiteIcon);

            videoStateController.disposeVideo();

            videoUiStateController
                .updateMainAxisAlignmentType(MainAxisAlignment.center);

            videoUiStateController.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.parsingIndicator);

            final videoUrl = await WebRequest.getVideoSourceService(
              episode.like,
              videoConfig,
            );

            dataSourceController.setVideoUrl(videoUrl);
            Get.snackbar(
              '视频资源解析成功',
              '',
              duration: const Duration(seconds: 2),
              maxWidth: 300,
            );
          } catch (e) {
            Get.snackbar(
              '错误',
              '获取视频源失败: $e',
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red.shade100,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.subjectsTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '第${episode.episodeSort}集',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '线路:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.lineNames,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Icon(Icons.link, size: 20, color: Colors.grey),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
