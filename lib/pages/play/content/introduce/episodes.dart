import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/pages/play/provider/play_subject_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class EpisodesComponents extends ConsumerStatefulWidget {
  const EpisodesComponents({super.key});

  @override
  ConsumerState<EpisodesComponents> createState() => _EpisodesComponentsState();
}

class _EpisodesComponentsState extends ConsumerState<EpisodesComponents> {
  final playPageController = Get.find<PlayController>();
  final controller = ScrollController();

  /// 布局模式：false=列表，true=网格
  bool isGridView = false;

  /// 上次滚动定位对应的 sort，避免 rebuild 重复触发滚动
  double? lastScrolledSort;

  /// 剧集列表每行固定高度
  final double itemHeight = 80;

  static const double _loadMoreTriggerDistance = 80;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    controller.removeListener(_onScroll);
    controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreTriggerDistance) {
      _tryLoadMore();
    }
  }

  void _tryLoadMore() {
    final episodesState = ref.read(episodesProvider);
    if (!episodesState.hasMore ||
        episodesState.isLoadingMore ||
        episodesState.isLoading) {
      return;
    }
    final subjectId = ref.read(playSubjectProvider).subjectId;
    ref.read(episodesProvider.notifier).loadMore(subjectId);
  }

  /// 将列表滚动到当前选集对应行（需在布局完成、`controller` 已 attach 后调用）。
  void _scrollListToSelectedEpisode(
    List<EpisodeData> episodes,
    double selectedSort,
  ) {
    if (!mounted || isGridView || !controller.hasClients) return;
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

  Widget _buildLoadMoreFooter(bool isLoadingMore) {
    if (!isLoadingMore) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
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
            const Text('选集'),
            Consumer(
              builder: (context, ref, _) {
                final hasEpisodes = ref.watch(
                  episodesProvider.select((state) => state.episodes != null),
                );
                return hasEpisodes
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            isGridView = !isGridView;
                          });
                        },
                        icon: Icon(
                          isGridView ? Icons.view_list : Icons.grid_view,
                        ),
                        tooltip: isGridView ? '切换到列表' : '切换到网格',
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
        isGridView ? buildGridEpisodes() : buildListEpisodes(),
      ],
    );
  }

  Widget buildListEpisodes() {
    return Consumer(
      builder: (context, ref, _) {
        final episodesState = ref.watch(episodesProvider);
        if (episodesState.isLoading) {
          return const SizedBox();
        }

        final episodesItem = episodesState.episodes;
        if (episodesItem == null || episodesItem.data.isEmpty) {
          return const Text('暂无章节数据');
        }

        final episodes = episodesItem.data;
        final selectedSort = episodesState.episodeSort;
        if (lastScrolledSort != selectedSort) {
          lastScrolledSort = selectedSort;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollListToSelectedEpisode(episodes, selectedSort);
          });
        }

        final itemCount =
            episodes.length + (episodesState.isLoadingMore ? 1 : 0);

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
            itemCount: itemCount,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              if (index >= episodes.length) {
                return _buildLoadMoreFooter(episodesState.isLoadingMore);
              }

              final episode = episodes[index];
              final isSelected = selectedSort == episode.sort;
              return SizedBox(
                height: itemHeight,
                child: Card(
                  elevation: 0,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      final episodeIndex = index + 1;
                      final notifier = ref.read(episodesProvider.notifier);
                      notifier.setEpisodeSort(
                        episodeId: episode.id,
                        episodeIndex: episodeIndex,
                        sort: episode.sort,
                      );
                      notifier.setEpisodeTitle(
                        episode.nameCN.isEmpty ? episode.name : episode.nameCN,
                      );
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            ),
                          ),
                          if (isSelected)
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
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildGridEpisodes() {
    return Consumer(
      builder: (context, ref, _) {
        final episodesState = ref.watch(episodesProvider);
        if (episodesState.isLoading) {
          return const SizedBox();
        }

        final episodesItem = episodesState.episodes;
        if (episodesItem == null || episodesItem.data.isEmpty) {
          return const Text('暂无章节数据');
        }

        final episodes = episodesItem.data;
        final selectedSort = episodesState.episodeSort;
        final itemCount =
            episodes.length + (episodesState.isLoadingMore ? 1 : 0);

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
            controller: controller,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= episodes.length) {
                return const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final episode = episodes[index];
              final isSelected = selectedSort == episode.sort;
              return Card(
                elevation: 0,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final episodeIndex = index + 1;
                    final notifier = ref.read(episodesProvider.notifier);
                    notifier.setEpisodeSort(
                      episodeId: episode.id,
                      episodeIndex: episodeIndex,
                      sort: episode.sort,
                    );
                    notifier.setEpisodeTitle(
                      episode.nameCN.isEmpty ? episode.name : episode.nameCN,
                    );
                  },
                  child: Center(
                    child: Text(
                      '${episode.sort}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
