import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EpisodesDrawerView extends ConsumerStatefulWidget {
  final SubjectsInfoItem subjectItem;
  final String subjectName;
  final String subjectImage;
  final ScrollController scrollController;
  final void Function(int episodeId)? onEpisodeLongPress;

  const EpisodesDrawerView({
    super.key,
    required this.subjectItem,
    required this.subjectName,
    required this.subjectImage,
    required this.scrollController,
    this.onEpisodeLongPress,
  });

  static void show(
    BuildContext context, {
    required SubjectsInfoItem subjectItem,
    required String subjectName,
    required String subjectImage,
    void Function(int episodeId)? onEpisodeLongPress,
  }) {
    final providerContainer = ProviderScope.containerOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return UncontrolledProviderScope(
          container: providerContainer,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.60,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.52, 0.95],
            builder: (context, scrollController) {
              return EpisodesDrawerView(
                scrollController: scrollController,
                subjectItem: subjectItem,
                subjectName: subjectName,
                subjectImage: subjectImage,
                onEpisodeLongPress: onEpisodeLongPress,
              );
            },
          ),
        );
      },
    );
  }

  @override
  ConsumerState<EpisodesDrawerView> createState() => _EpisodesDrawerViewState();
}

class _EpisodesDrawerViewState extends ConsumerState<EpisodesDrawerView> {
  static const double _loadMoreTriggerDistance = 80;

  void _tryLoadMoreEpisodes(int subjectId) {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreTriggerDistance) {
      return;
    }

    final episodesState =
        ref.read(subjectEpisodesProvider(subjectId)).asData?.value;
    if (episodesState == null ||
        episodesState.isLoadingMore ||
        !episodesState.hasMore) {
      return;
    }
    ref.read(subjectEpisodesProvider(subjectId).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final subjectItem = widget.subjectItem;
    final episodesAsync = ref.watch(subjectEpisodesProvider(subjectItem.id));

    return episodesAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 180,
          child: LinearProgressIndicator(),
        ),
      ),
      error: (error, _) {
        LiggLogger().e(error);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('剧集加载失败'),
              const SizedBox(height: 8),
              Text(
                '$error',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref
                    .read(subjectEpisodesProvider(subjectItem.id).notifier)
                    .retry(),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        );
      },
      data: (episodesState) => _buildEpisodesList(episodesState, subjectItem),
    );
  }

  Widget _buildEpisodesList(
    SubjectEpisodesState episodesState,
    SubjectsInfoItem subjectItem,
  ) {
    final sortedEpisodes = [...episodesState.episodes.data]..sort((a, b) {
        final aIsMain = a.type == 0 ? 0 : 1;
        final bIsMain = b.type == 0 ? 0 : 1;
        if (aIsMain != bIsMain) return aIsMain.compareTo(bIsMain);
        if (a.type != b.type) return a.type.compareTo(b.type);
        return a.sort.compareTo(b.sort);
      });

    if (sortedEpisodes.isEmpty) {
      return const Center(child: Text('暂无剧集数据'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              Text(
                '剧集',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Text(
                episodesState.hasMore
                    ? '已加载 ${sortedEpisodes.length} 集'
                    : '共 ${sortedEpisodes.length} 集',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                _tryLoadMoreEpisodes(subjectItem.id);
              }
              return false;
            },
            child: ListView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              itemExtent: 70,
              itemCount:
                  sortedEpisodes.length + (episodesState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= sortedEpisodes.length) {
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

                final episode = sortedEpisodes[index];
                return ListTile(
                  tileColor: episode.watched == true
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  onLongPress: () => widget.onEpisodeLongPress?.call(
                    episode.id,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    PlayRoute.fromExtra(
                      PlayRouteExtra(
                        playExtra: PlayExtra(
                          subjectId: subjectItem.id,
                          subjectName: widget.subjectName,
                          subjectCover: widget.subjectImage,
                          subjectAliases: subjectItem.infobox
                              .where((item) => item.key == '别名')
                              .expand((item) => item.values.map((e) => e.v))
                              .toList(),
                        ),
                        continueEpisodeId: episode.id,
                      ),
                    ).push(context);
                  },
                  leading: Text(
                    episode.sort.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(
                    episode.nameCN.isEmpty ? episode.name : episode.nameCN,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      if (episode.type != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            episodesTypeLabels[episode.type] ?? '',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      if (episode.airdate.isNotEmpty) ...[
                        if (episode.type != 0) const SizedBox(width: 8),
                        Text(episode.airdate),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.play_arrow_rounded),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
