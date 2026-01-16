import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/stores/subject_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class EpisodesComponents extends StatefulWidget {
  const EpisodesComponents({super.key});

  @override
  State<EpisodesComponents> createState() => EpisodesComponentsState();
}

class EpisodesComponentsState extends State<EpisodesComponents> {
  late PlayController playPageController;
  late SubjectState subjectState;
  late EpisodesState episodesState;
  static const String drawerTitle = "章节列表";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    playPageController = Get.find<PlayController>();
    episodesState = Get.find<EpisodesState>();
    subjectState = Get.find<SubjectState>();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("选集"),
            Obx(() => episodesState.episodes.value != null
                ? IconButton(
                    onPressed: () {
                      if (playPageController.isWideScreen.value) {
                        // 宽屏展示侧边抽屉
                        showSideDrawer(context);
                      } else {
                        // 窄屏展示底部抽屉
                        showBottomSheet(context);
                      }
                    },
                    icon: const Icon(Icons.keyboard_arrow_down_rounded))
                : const SizedBox.shrink())
          ],
        ),
        //横向滚动卡片
        _scrollTheCardHorizontally()
      ],
    );
  }

  Widget _scrollTheCardHorizontally() {
    final Logger logger = Logger();
    return Obx(() {
      if (episodesState.isLoading.value) {
        return const CircularProgressIndicator();
      } else {
        final episodesItem = episodesState.episodes.value;
        if (episodesItem == null || episodesItem.data.isEmpty) {
          return const Text('暂无章节数据');
        } else {
          final episodes = episodesItem.data;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                episodes.length,
                (index) {
                  final episode = episodes[index];
                  return Obx(() => Card(
                      elevation: 0,
                      color: episodesState.episodeSort.value == episode.sort
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: InkWell(
                        onTap: () {
                          final episodeIndex = index + 1;
                          episodesState.setEpisodeSort(
                              episodeId: episode.id,
                              episodeIndex: episodeIndex,
                              sort: episode.sort);
                          episodesState
                              .setEpisodeTitle(episode.nameCN ?? episode.name);
                          logger.i('选中剧集索引:$episodeIndex');
                        },
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('第${episode.sort}话'),
                              const SizedBox(height: 5),
                              Text(
                                episode.nameCN ?? episode.name,
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
        }
      }
    });
  }

  /// 底部抽屉
  static void showBottomSheet(BuildContext context) {
    Get.bottomSheet(
      ignoreSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        //TODO 获取竖屏播放器高度状态，动态设置底部抽屉弹出占满剩余高度
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
              padding: const EdgeInsets.only(bottom: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                drawerTitle,
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
                  alignment: Alignment.topLeft,
                  child: _buildEpisodesGridStatic(context)),
            )
          ],
        ),
      ),
    );
  }

  /// 侧边抽屉
  static void showSideDrawer(BuildContext context) {
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
                      drawerTitle,
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
                Expanded(child: _buildEpisodesGridStatic(context)),
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

  /// 静态方法：构建剧集网格（用于抽屉）
  static Widget _buildEpisodesGridStatic(BuildContext context) {
    final episodesState = Get.find<EpisodesState>();
    return Obx(() {
      // 获取剧集数据
      final episodesData = episodesState.episodes.value;
      if (episodesData == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final episodeList = episodesData.data;
      if (episodeList.isEmpty) {
        return const Center(child: Text('暂无章节数据'));
      }

      return LayoutBuilder(builder: (context, constraints) {
        const double spacing = 8.0;
        // 动态计算列数，最小2列，最大6列
        final int crossAxisCount =
            (constraints.maxWidth / 160).floor().clamp(2, 6);
        final double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(
              episodeList.length,
              (index) {
                final episode = episodeList[index];
                return SizedBox(
                  width: itemWidth,
                  child: Obx(
                    () => Card(
                      color: episodesState.episodeSort.value == episode.sort
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () {
                          final episodeIndex = index + 1;
                          episodesState.setEpisodeSort(
                              episodeId: episode.id,
                              episodeIndex: episodeIndex,
                              sort: episode.sort);
                          episodesState
                              .setEpisodeTitle(episode.nameCN ?? episode.name);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '第${episode.sort}话',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                episode.nameCN ?? episode.name,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      });
    });
  }
}
