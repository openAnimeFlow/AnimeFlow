import 'package:anime_flow/components/play_content/video_source_drawers.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/controllers/crawler/crawler_config_controller.dart';
import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/video_source_controller.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:anime_flow/models/item/video/resources_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class IntroduceView extends StatefulWidget {
  final Subject subject;
  final Future<EpisodesItem> episodes;
  static const String drawerTitle = "章节列表";

  const IntroduceView(this.subject, this.episodes, {super.key});

  @override
  State<IntroduceView> createState() => _IntroduceViewState();
}

class _IntroduceViewState extends State<IntroduceView>
    with AutomaticKeepAliveClientMixin {
  Logger logger = Logger();
  late PlayPageController playPageController;
  late VideoSourceController videoResourcesController;
  late EpisodesController episodesController;
  late VideoSourceController videoSourceController;
  late CrawlerConfigController crawlerConfigController;
  List<ResourcesItem> videoResources = [];
  Worker? _screenWorker; // 屏幕宽高监听器
  bool isVideoSourceLoading = true;

  // 保持页面状态，防止切换Tab时重新加载
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    playPageController = Get.find<PlayPageController>();
    videoResourcesController = Get.find<VideoSourceController>();
    episodesController = Get.find<EpisodesController>();
    videoSourceController = Get.find<VideoSourceController>();
    crawlerConfigController = Get.find<CrawlerConfigController>();

    getVideoResources();
    // 初始化监听器
    _screenWorker = ever(playPageController.isWideScreen, (isWide) {
      // 如果有任何弹窗打开（BottomSheet 或 GeneralDialog），则关闭
      if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
        Get.back();
        // 延迟一点时间重新打开对应样式的弹窗
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            if (isWide) {
              _showSideDrawer(context, title: IntroduceView.drawerTitle);
            } else {
              _showBottomSheet(context, title: IntroduceView.drawerTitle);
            }
          }
        });
      }
    });
  }

  void getVideoResources() async {
    try {
      final configs = await crawlerConfigController.loadAllCrawlConfigs();
      List<ResourcesItem> allVideoResources = [];
      for (var config in configs) {
        final allEpisodesList =
            await videoResourcesController.getEpisodeResources(
                widget.subject.nameCN ?? widget.subject.name, config);

        final baseURL = config.baseURL;
        final websiteName = config.name;
        final websiteIcon = config.iconUrl;
        final matchVideoConfig = config.matchVideo;

        VideoConfig videoConfig = VideoConfig(
          enableNestedUrl: matchVideoConfig.enableNestedUrl,
          matchNestedUrl: matchVideoConfig.matchNestedUrl,
          matchVideoUrl: matchVideoConfig.matchNestedUrl,
          baseURL: baseURL,
        );

        ResourcesItem resourcesItem = ResourcesItem(
          websiteName: websiteName,
          websiteIcon: websiteIcon,
          episodeResources: allEpisodesList,
          videoConfig: videoConfig,
        );

        allVideoResources.add(resourcesItem);
        if (mounted) {
          setState(() {
            videoResources = allVideoResources;
            isVideoSourceLoading = false;
          });
        }
      }
    } catch (e) {
      logger.e(e);
      if (mounted) {
        setState(() {
          isVideoSourceLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // 清理监听器
    _screenWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build 来启用 AutomaticKeepAliveClientMixin
    super.build(context);
    const String sourceTitle = "数据源";
    return Padding(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subject.nameCN ?? widget.subject.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 10),
              //章节
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("选集"),
                      IconButton(
                          onPressed: () {
                            if (playPageController.isWideScreen.value) {
                              // 宽屏展示侧边抽屉
                              _showSideDrawer(context,
                                  title: IntroduceView.drawerTitle);
                            } else {
                              // 窄屏展示底部抽屉
                              _showBottomSheet(context,
                                  title: IntroduceView.drawerTitle);
                            }
                          },
                          icon: Icon(Icons.keyboard_arrow_down_rounded))
                    ],
                  ),
                  //横向滚动卡片
                  _scrollTheCardHorizontally()
                ],
              ),
              //数据源
              Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sourceTitle,
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            Obx(() => videoSourceController.webSiteName.value !=
                                    ''
                                ? Text(
                                    videoSourceController.webSiteName.value,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : SizedBox.shrink()),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      isVideoSourceLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : OutlinedButton.icon(
                              onPressed: () {
                                Get.generalDialog(
                                    barrierDismissible: true,
                                    barrierLabel: "SourceDrawer",
                                    barrierColor: Colors.black54,
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                    // 动画
                                    transitionBuilder: (context, animation,
                                        secondaryAnimation, child) {
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
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return VideoSourceDrawers(
                                        sourceTitle,
                                        videoResources: videoResources,
                                      );
                                    });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              icon: Icon(Icons.sync_alt_rounded),
                              label: const Text("切换源"),
                            ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  /// 底部抽屉
  void _showBottomSheet(BuildContext context, {String? title}) {
    Get.bottomSheet(
        ignoreSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        Container(
          //TODO 获取竖屏播放器高度状态，动态设置底部抽屉弹出占满剩余高度
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            children: [
              // 顶部指示条
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  title ?? '',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                    alignment: Alignment.topLeft, child: _buildEpisodesGrid()),
              )
            ],
          ),
        ));
  }

  /// 侧边抽屉
  void _showSideDrawer(BuildContext context, {String? title}) {
    Get.generalDialog(
      barrierDismissible: true,
      barrierLabel: "EpisodesDrawer",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title ?? '',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          decoration: TextDecoration.none),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildEpisodesGrid()),
              ],
            ),
          ),
        );
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
  }

  /// 通用章节网格
  Widget _buildEpisodesGrid() {
    final Logger logger = Logger();
    return FutureBuilder<EpisodesItem>(
      future: widget.episodes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final episodeList = snapshot.data!.data;
          if (episodeList.isEmpty) {
            return const Center(child: Text('暂无章节数据'));
          }
          return LayoutBuilder(builder: (context, constraints) {
            final double spacing = 8.0;
            // 动态计算列数，最小2列，最大6列
            final int crossAxisCount =
                (constraints.maxWidth / 160).floor().clamp(2, 6);
            final double itemWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;

            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: episodeList.map((episode) {
                  return SizedBox(
                    width: itemWidth,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () {
                          logger.i('第${episode.sort}话');
                          //TODO 实现播放
                        },
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '第${episode.sort}话',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Text(
                                episode.nameCN.isNotEmpty
                                    ? episode.nameCN
                                    : episode.name,
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          });
        } else {
          return const Center(child: Text('加载失败'));
        }
      },
    );
  }

  //横向滚动卡片
  FutureBuilder<EpisodesItem> _scrollTheCardHorizontally() {
    final Logger logger = Logger();

    return FutureBuilder<EpisodesItem>(
      future: widget.episodes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          final episodeList = snapshot.data!.data;
          if (episodeList.isEmpty) {
            return const Text('暂无章节数据');
          }
          //TODO 暂时默认选择第一集
          if (episodesController.episodeSort.value == 0) {
            final firstEpisode = episodeList.first;
            episodesController.setEpisodeSort(firstEpisode.sort, 1);
            episodesController.setEpisodeTitle(firstEpisode.nameCN);
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                episodeList.length,
                (index) {
                  final episode = episodeList[index];
                  return Obx(() => Card(
                      elevation: 0,
                      color:
                          episodesController.episodeSort.value == episode.sort
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                      child: InkWell(
                        onTap: () {
                          final episodeIndex = index + 1;
                          episodesController.setEpisodeSort(
                              episode.sort, episodeIndex);
                          episodesController.setEpisodeTitle(episode.nameCN);
                          logger.i('选中剧集索引:$episodeIndex');
                        },
                        child: Container(
                          width: 150,
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('第${episode.sort}话'),
                              SizedBox(height: 5),
                              Text(
                                episode.nameCN.isNotEmpty
                                    ? episode.nameCN
                                    : episode.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      )));
                },
              ),
            ),
          );
        } else {
          return const Text('暂无章节数据');
        }
      },
    );
  }
}
