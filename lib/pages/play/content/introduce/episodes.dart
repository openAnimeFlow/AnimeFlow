import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class EpisodesComponents extends ConsumerStatefulWidget {
  const EpisodesComponents({super.key});

  @override
  ConsumerState<EpisodesComponents> createState() => _EpisodesComponentsState();
}

class _EpisodesComponentsState extends ConsumerState<EpisodesComponents> {
  final controller = ScrollController();

  /// 布局模式：false=列表，true=网格
  bool isGridView = false;

  /// 上次滚动定位对应的 episodeId，避免 rebuild 重复触发滚动
  int? lastScrolledEpisodeId;

  /// 剧集类型 → 中文标签
  static const Map<int, String> _typeLabels = {
    0: '正篇',
    1: '特别篇',
    2: 'OP',
    3: 'ED',
    4: 'Trailer',
    5: 'MAD',
    6: '其他',
  };

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
    if (position.pixels >=
        position.maxScrollExtent - _loadMoreTriggerDistance) {
      _tryLoadMore();
    }
  }

  void _tryLoadMore() {
    final episodesState = ref.read(episodesProvider).asData?.value;
    if (episodesState == null ||
        !episodesState.hasMore ||
        episodesState.isLoadingMore) {
      return;
    }
    ref.read(episodesProvider.notifier).loadMore();
  }

  /// 正篇(type=0)置顶，其余按 type 分组，同 type 内按 sort 排序
  void _sortEpisodes(List<EpisodeData> episodes) {
    episodes.sort((a, b) {
      final aIsMain = a.type == 0 ? 0 : 1;
      final bIsMain = b.type == 0 ? 0 : 1;
      if (aIsMain != bIsMain) return aIsMain.compareTo(bIsMain);
      if (a.type != b.type) return a.type.compareTo(b.type);
      return a.sort.compareTo(b.sort);
    });
  }

  /// 将列表滚动到当前选集对应行（需在布局完成、`controller` 已 attach 后调用）。
  void _scrollListToSelectedEpisode(
    List<EpisodeData> episodes,
    int episodeId,
  ) {
    if (!mounted || isGridView || !controller.hasClients) return;
    final index = episodes.indexWhere(
      (e) => e.id == episodeId,
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
    final episodesAsync = ref.watch(episodesProvider);
    final hasEpisodes = episodesAsync.asData?.value.episodes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('选集'),
            hasEpisodes
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
                : const SizedBox.shrink(),
          ],
        ),
        episodesAsync.when(
          loading: () => const Column(
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 12),
              Text('正在获取剧集...'),
            ],
          ),
          error: (error, _) => _buildLoadError(error),
          data: (episodesState) => isGridView
              ? buildGridEpisodes(episodesState)
              : buildListEpisodes(episodesState),
        ),
      ],
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

  Widget _buildLoadError(Object error) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('剧集获取失败'),
            const SizedBox(height: 8),
            Text(
              '$error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.read(episodesProvider.notifier).retry(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildListEpisodes(EpisodesData episodesState) {
    final episodesItem = episodesState.episodes;
    if (episodesItem == null || episodesItem.data.isEmpty) {
      return const Text('暂无章节数据');
    }

    final episodes = episodesItem.data;
    _sortEpisodes(episodes);
    final selectedEpisodeId = episodesState.episodeId;
    if (lastScrolledEpisodeId != selectedEpisodeId) {
      lastScrolledEpisodeId = selectedEpisodeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollListToSelectedEpisode(episodes, selectedEpisodeId);
      });
    }

    final itemCount = episodes.length + (episodesState.isLoadingMore ? 1 : 0);

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
          final isSelected = selectedEpisodeId == episode.id;
          return SizedBox(
            height: itemHeight,
            child: Card(
              elevation: 0,
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _selectEpisode(episode, index + 1),
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
                            Row(
                              children: [
                                Text(episode.sort.toString().padLeft(2, '0')),
                                if (episode.type != 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    _typeLabels[episode.type] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
  }

  Widget buildGridEpisodes(EpisodesData episodesState) {
    final episodesItem = episodesState.episodes;
    if (episodesItem == null || episodesItem.data.isEmpty) {
      return const Text('暂无章节数据');
    }

    final episodes = episodesItem.data;
    _sortEpisodes(episodes);
    final selectedEpisodeId = episodesState.episodeId;
    final itemCount = episodes.length + (episodesState.isLoadingMore ? 1 : 0);

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
          final isSelected = selectedEpisodeId == episode.id;
          return Card(
            elevation: 0,
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _selectEpisode(episode, index + 1),
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
  }

  void _selectEpisode(EpisodeData episode, int episodeIndex) {
    final notifier = ref.read(episodesProvider.notifier);
    notifier.setEpisodeSort(
      episodeId: episode.id,
      episodeIndex: episodeIndex,
      sort: episode.sort,
    );
    notifier.setEpisodeTitle(
      episode.nameCN.isEmpty ? episode.name : episode.nameCN,
    );
  }
}
