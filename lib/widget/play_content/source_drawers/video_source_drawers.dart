import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/video/data/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/item/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class VideoSourceDrawers extends StatefulWidget {
  final Function(String url)? onVideoUrlSelected;
  
  const VideoSourceDrawers({super.key, this.onVideoUrlSelected});

  @override
  State<VideoSourceDrawers> createState() => _VideoSourceDrawersState();
}

class _VideoSourceDrawersState extends State<VideoSourceDrawers> {
  late VideoStateController videoStateController;
  late EpisodesState episodesController;
  late VideoSourceController dataSourceController;
  late VideoUiStateController videoUiStateController;
  final logger = Logger();
  bool isShowEpisodes = false;
  int selectedWebsiteIndex = 0; // 当前选中的网站索引
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    videoUiStateController = Get.find<VideoUiStateController>();
    videoStateController = Get.find<VideoStateController>();
    episodesController = Get.find<EpisodesState>();
    dataSourceController = Get.find<VideoSourceController>();
    _searchController.text = dataSourceController.keyword.value;
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



  void _performSearch() {
    String searchQuery = _searchController.text;
    if (searchQuery.isNotEmpty) {
      setState(() {
        selectedWebsiteIndex = 0;
        isShowEpisodes = false;
      });
      dataSourceController.initResources(searchQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: PlayLayoutConstant.playContentWidth,
        height: MediaQuery.of(context).size.height,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '数据源',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              _manualSearch(),
              const SizedBox(height: 16),
              Obx(() {
                final dataSource = dataSourceController.videoResources.value;
                if (dataSource.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildWebsiteSelector(dataSource: dataSource);
              }),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final dataSource = dataSourceController.videoResources.value;
                  if (dataSource.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  // 确保索引有效，如果无效则使用 0
                  int validIndex = selectedWebsiteIndex >= dataSource.length
                      ? 0
                      : selectedWebsiteIndex;

                  // 如果索引不匹配，更新索引
                  if (validIndex != selectedWebsiteIndex) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          selectedWebsiteIndex = validIndex;
                        });
                      }
                    });
                  }
                  return _buildVideoSource(dataSource: dataSource);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _manualSearch() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Text(
            '手动搜索',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
              child: Material(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '手动搜索资源',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onSubmitted: (value) {
                _performSearch();
              },
            ),
          ))
        ],
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
    // 确保索引有效
    if (selectedWebsiteIndex >= dataSource.length) {
      return const SizedBox.shrink();
    }

    final selectedResource = dataSource[selectedWebsiteIndex];

    return Material(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 0),
        itemCount: selectedResource.episodeResources.length,
        itemBuilder: (context, index) {
          final resourceItem = selectedResource.episodeResources[index];
          final isLastItem =
              index == selectedResource.episodeResources.length - 1;

          return Obx(() {
            // 当前选中剧集对应的剧集数据
            final currentEpisode = resourceItem.episodes.firstWhereOrNull(
              (ep) => ep.episodeSort == episodesController.episodeIndex.value,
            );

            final excludedEpisodesCount = selectedResource.episodeResources
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
                  baseUrl: selectedResource.baseUrl,
                  websiteName: selectedResource.websiteName,
                  websiteIcon: selectedResource.websiteIcon,
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
                    ...selectedResource.episodeResources.expand((item) {
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
                          baseUrl: selectedResource.baseUrl,
                          websiteName: selectedResource.websiteName,
                          websiteIcon: selectedResource.websiteIcon,
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

  Widget _buildSource(Episode episode, EpisodeResourcesItem item,
      {required String websiteName,
      required String websiteIcon,
      required String baseUrl}) {
    final videoUrl = dataSourceController.videoUrl.value;
    final isSelected = baseUrl + episode.like == videoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                width: 2.5,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
      child: Card.filled(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
            onTap: () async {
              try {
                Get.back();
                final videoUrl = baseUrl + episode.like;
                dataSourceController.setWebSite(
                    title: websiteName,
                    iconUrl: websiteIcon,
                    videoUrl: videoUrl);

                videoStateController.disposeVideo();
                widget.onVideoUrlSelected?.call(videoUrl);
              } catch (e) {
                logger.e('获取视频源失败', error: e);
                Get.snackbar(
                  '错误',
                  '获取视频源失败: $e',
                  duration: const Duration(seconds: 3),
                  maxWidth: 300,
                  backgroundColor: Colors.red.shade100,
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            text: item.subjectsTitle,
                            children: [
                              TextSpan(
                                text:
                                    ' 第${episode.episodeSort.toString().padLeft(2, '0')}集',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
            )),
      ),
    );
  }
}
