import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
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
  late PlaySubjectState subjectState;
  late EpisodesState episodesState;
  static const String drawerTitle = "章节列表";
  bool isLoading = false;
  bool _isGridView = false; // 布局模式：false=列表，true=网格

  @override
  void initState() {
    super.initState();
    playPageController = Get.find<PlayController>();
    episodesState = Get.find<EpisodesState>();
    subjectState = Get.find<PlaySubjectState>();
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
                itemCount: episodes.length,
                padding: EdgeInsets.zero,
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
                          episodesState
                              .setEpisodeTitle(episode.nameCN ?? episode.name);
                          Logger().i('选中剧集索引:$episodeIndex');
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
                        episodesState
                            .setEpisodeTitle(episode.nameCN ?? episode.name);
                        Logger().i('选中剧集索引:$episodeIndex');
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
                        child: Center(
                          child: Text(
                            '${episode.sort}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: episodesState.episodeSort.value ==
                                      episode.sort
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
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
