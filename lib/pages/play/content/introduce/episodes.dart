import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class EpisodesComponents extends StatefulWidget {
  const EpisodesComponents({super.key});

  @override
  State<EpisodesComponents> createState() => EpisodesComponentsState();
}

class EpisodesComponentsState extends State<EpisodesComponents> {
  final playPageController = Get.find<PlayController>();
  final subjectState = Get.find<PlaySubjectState>();
  final episodesState = Get.find<EpisodesState>();
  final controller = ScrollController();
  bool isLoading = false;

  /// 布局模式：false=列表，true=网格
  bool _isGridView = false;

  /// 剧集列表每行固定高度
  final double itemHeight = 80;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// 将列表滚动到当前选集对应行（需在布局完成、`controller` 已 attach 后调用）。
  void _scrollListToSelectedEpisode(
    List<EpisodeData> episodes,
    double selectedSort,
  ) {
    if (!mounted || _isGridView || !controller.hasClients) return;
    final index = episodes.indexWhere(
      (e) => e.sort.toDouble() == selectedSort,
    );
    if (index < 0) return;
    final maxExtent = controller.position.maxScrollExtent;
    final offset = (index * itemHeight).clamp(0.0, maxExtent);
    controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                    tooltip: _isGridView ? '切换到列表' : '切换到网格',
                  )
                : const SizedBox.shrink())
          ],
        ),
        _isGridView ? _buildGridEpisodes() : _buildListEpisodes()
      ],
    );
  }

  Widget _buildListEpisodes() {
    return Obx(() {
      if (episodesState.isLoading.value) {
        return const SizedBox();
      } else {
        final episodesItem = episodesState.episodes.value;
        if (episodesItem == null || episodesItem.data.isEmpty) {
          return const Text('暂无章节数据');
        } else {
          final episodes = episodesItem.data;
          final selectedSort = episodesState.episodeSort.value;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollListToSelectedEpisode(episodes, selectedSort);
          });
          return Container(
            height: 250,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.8),
            ),
            child: ListView.builder(
                controller: controller,
                itemCount: episodes.length,
                padding: EdgeInsets.zero,
                itemExtent: itemHeight,
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  return Obx(
                    () => Card(
                      elevation: 0,
                      color: episodesState.episodeSort.value == episode.sort
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          final episodeIndex = index + 1;
                          episodesState.setEpisodeSort(
                              episodeId: episode.id,
                              episodeIndex: episodeIndex,
                              sort: episode.sort);
                          episodesState.setEpisodeTitle(episode.nameCN.isEmpty
                              ? episode.name
                              : episode.nameCN);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: episode.collection != null
                                ? Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.3)
                                : null,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(episode.sort.toString().padLeft(2, '0')),
                                  Text(
                                    episode.nameCN.isEmpty
                                        ? episode.name
                                        : episode.nameCN,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              )),
                              if (episodesState.episodeSort.value ==
                                  episode.sort)
                                Lottie.asset(
                                  AssetsPathConstants.playJsonIng,
                                  width: 30,
                                  height: 30,
                                  frameBuilder: (context, child, composition) {
                                    return ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.primary,
                                        BlendMode.srcIn,
                                      ),
                                      child: child,
                                    );
                                  },
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          );
        }
      }
    });
  }

  Widget _buildGridEpisodes() {
    return Obx(() {
      if (episodesState.isLoading.value) {
        return const SizedBox();
      } else {
        final episodesItem = episodesState.episodes.value;
        if (episodesItem == null || episodesItem.data.isEmpty) {
          return const Text('暂无章节数据');
        } else {
          final episodes = episodesItem.data;
          return Container(
            constraints: const BoxConstraints(maxHeight: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.8),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                childAspectRatio: 1,
              ),
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Obx(
                  () => Card(
                    elevation: 0,
                    color: episodesState.episodeSort.value == episode.sort
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final episodeIndex = index + 1;
                        episodesState.setEpisodeSort(
                            episodeId: episode.id,
                            episodeIndex: episodeIndex,
                            sort: episode.sort);
                        episodesState.setEpisodeTitle(episode.nameCN.isEmpty
                            ? episode.name
                            : episode.nameCN);
                      },
                      child: Center(
                        child: Text(
                          '${episode.sort}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                episodesState.episodeSort.value == episode.sort
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      }
    });
  }
}
