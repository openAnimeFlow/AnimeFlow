import 'package:anime_flow/stores/subject_state.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/play_content/source_drawers/video_source_drawers.dart';
import 'package:anime_flow/controllers/video/data/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:logger/logger.dart';

class VideoResourcesView extends StatefulWidget {

  const VideoResourcesView(
      {super.key});

  @override
  State<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends State<VideoResourcesView> {
  late VideoSourceController dataSourceController;
  late SubjectState subjectStateController;
  late EpisodesState episodesController;
  late VideoStateController videoStateController;
  late WebviewItemController webviewItemController;
  final Logger logger = Logger();
  bool _hasAutoSelected = false; // 标记是否已经自动选择过

  @override
  void initState() {
    super.initState();
    dataSourceController = Get.find<VideoSourceController>();
    subjectStateController = Get.find<SubjectState>();
    episodesController = Get.find<EpisodesState>();
    videoStateController = Get.find<VideoStateController>();
    webviewItemController = Get.find<WebviewItemController>();
    
    // 检查资源是否已经为当前关键词初始化过，避免全屏切换时重复初始化
    final currentKeyword = subjectStateController.name;
    if (dataSourceController.keyword.value != currentKeyword) {
      // 只有当关键词不同时才重新初始化
      _hasAutoSelected = false;
      dataSourceController.initResources(currentKeyword);
    }
    
    // 监听 isLoading 变化，当所有资源获取完成时（isLoading == true）自动选择第一个有资源的网站
    ever(dataSourceController.isLoading, (bool isLoading) {
      if (mounted && isLoading) {
        // 当 isLoading 变为 true 时，说明所有网站的资源获取完成
        final resources = dataSourceController.videoResources.value;
        _autoSelectFirstResource(resources);
      }
    });
  }

  /// 查找第一个有资源的网站索引
  int _findFirstResourceIndex(List<ResourcesItem> dataSource) {
    for (int i = 0; i < dataSource.length; i++) {
      if (dataSource[i].episodeResources.isNotEmpty) {
        return i;
      }
    }
    return 0;
  }

  /// 自动选择第一个有资源的网站并加载视频
  void _autoSelectFirstResource(List<ResourcesItem> resources) {
    // 如果已经自动选择过，或者已经有选中的资源，不再自动选择
    if (_hasAutoSelected || dataSourceController.webSiteTitle.value.isNotEmpty) {
      return;
    }

    // 检查是否有资源加载完成
    final hasResource = resources.any((r) => r.episodeResources.isNotEmpty);
    if (!hasResource) {
      return;
    }

    final firstResourceIndex = _findFirstResourceIndex(resources);
    final selectedResource = resources[firstResourceIndex];
    
    if (selectedResource.episodeResources.isEmpty) {
      return; // 没有找到有资源的网站
    }

    _hasAutoSelected = true;
    
    // 自动加载第一个匹配的资源
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _autoLoadFirstResource(selectedResource);
      }
    });
  }

  /// 自动加载第一个匹配当前剧集的资源
  Future<void> _autoLoadFirstResource(ResourcesItem resource) async {
    // 如果已经有选中的资源，不再自动加载
    if (dataSourceController.webSiteTitle.value.isNotEmpty) {
      return;
    }

    // 遍历资源列表，找到第一个匹配当前剧集的资源
    for (var resourceItem in resource.episodeResources) {
      final matchingEpisodes = resourceItem.episodes.where(
        (ep) => ep.episodeSort == episodesController.episodeIndex.value,
      );
      if (matchingEpisodes.isNotEmpty) {
        final currentEpisode = matchingEpisodes.first;
        try {
          dataSourceController.setWebSite(
            title: resource.websiteName,
            iconUrl: resource.websiteIcon,
            videoUrl: resource.baseUrl + currentEpisode.like,
          );
          videoStateController.disposeVideo();
          await _loadVideoPage(resource.baseUrl + currentEpisode.like);
        } catch (e) {
          logger.e('自动加载视频源失败', error: e);
        } finally {
        }
        return;
      }
    }
  }

  Future<void> _loadVideoPage(String url) async {
    logger.d('加载视频页面: $url');
    await webviewItemController.loadUrl(
      url,
      true, // useNativePlayer: 使用原生播放器
      true, // useLegacyParser: 不使用旧解析器
      offset: 0,
    );
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
                      Obx(() => dataSourceController.isLoading.value
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
