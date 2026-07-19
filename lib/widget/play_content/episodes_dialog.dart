import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EpisodesDialog extends ConsumerStatefulWidget {
  static const double _loadMoreTriggerDistance = 80;
  static const double _estimatedEpisodeItemExtent = 86;

  final void Function(int episodeId)? onEpisodeLongPress;
  final Widget isSelectedIcon;

  const EpisodesDialog({
    super.key,
    required this.isSelectedIcon,
    this.onEpisodeLongPress,
  });

  @override
  ConsumerState<EpisodesDialog> createState() => _EpisodesDialogState();
}

class _EpisodesDialogState extends ConsumerState<EpisodesDialog> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectedEpisodeKey = GlobalKey();
  int? _lastScrolledEpisodeId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final episodesAsync = ref.watch(episodesProvider);
    final episodesState = episodesAsync.asData?.value;
    final episodes = episodesState?.episodes?.data;
    final selectedEpisodeId = episodesState?.episodeId ?? 0;
    final subjectId =
        ref.watch(playExtraProvider.select((s) => s.playExtra.subjectId));

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: LayoutConstant.playContentWidth,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: Theme.of(context).cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "章节列表",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    decoration: TextDecoration.none,
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildEpisodesList(
                context,
                episodesAsync: episodesAsync,
                episodes: episodes,
                selectedEpisodeId: selectedEpisodeId,
                subjectId: subjectId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tryLoadMoreEpisodes({
    required int subjectId,
    required EpisodesData? episodesState,
    required ScrollMetrics metrics,
  }) {
    if (metrics.pixels <
        metrics.maxScrollExtent - EpisodesDialog._loadMoreTriggerDistance) {
      return;
    }

    if (episodesState == null ||
        episodesState.isLoadingMore ||
        !episodesState.hasMore) {
      return;
    }

    ref.read(subjectEpisodesProvider(subjectId).notifier).loadMore();
  }

  void _scrollToSelectedEpisode({
    required List<EpisodeData> episodes,
    required int selectedEpisodeId,
  }) {
    if (selectedEpisodeId == 0 || _lastScrolledEpisodeId == selectedEpisodeId) {
      return;
    }

    final selectedIndex =
        episodes.indexWhere((episode) => episode.id == selectedEpisodeId);
    if (selectedIndex < 0) {
      return;
    }

    _lastScrolledEpisodeId = selectedEpisodeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final targetOffset =
          (selectedIndex * EpisodesDialog._estimatedEpisodeItemExtent)
              .clamp(0.0, maxScrollExtent);
      _scrollController.jumpTo(targetOffset);

      final selectedContext = _selectedEpisodeKey.currentContext;
      if (selectedContext == null) return;
      Scrollable.ensureVisible(
        selectedContext,
        alignment: 0.35,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildEpisodesList(
    BuildContext context, {
    required AsyncValue<EpisodesData> episodesAsync,
    required List<EpisodeData>? episodes,
    required int selectedEpisodeId,
    required int subjectId,
  }) {
    final episodesState = episodesAsync.asData?.value;

    if (episodesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (episodesAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('章节加载失败'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.read(subjectEpisodesProvider(subjectId).notifier).retry(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (episodes == null || episodes.isEmpty) {
      return const Center(child: Text('暂无章节数据'));
    }

    _scrollToSelectedEpisode(
      episodes: episodes,
      selectedEpisodeId: selectedEpisodeId,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          _tryLoadMoreEpisodes(
            subjectId: subjectId,
            episodesState: episodesState,
            metrics: notification.metrics,
          );
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount:
            episodes.length + (episodesState?.isLoadingMore == true ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= episodes.length) {
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

          final episode = episodes[index];
          final isSelected = selectedEpisodeId == episode.id;
          final colorScheme = Theme.of(context).colorScheme;
          return Card(
            key: isSelected ? _selectedEpisodeKey : null,
            elevation: 0,
            child: InkWell(
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
                context.pop();
              },
              // 长按
              onLongPress: () => widget.onEpisodeLongPress?.call(episode.id),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: episode.watched == true
                        ? colorScheme.surfaceContainerHighest
                        : null,
                    border: episode.watched == true
                        ? Border.all(
                            color: colorScheme.secondaryContainer,
                            width: 2,
                          )
                        : null),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              episode.sort.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              episode.nameCN.isEmpty
                                  ? episode.name
                                  : episode.nameCN,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) widget.isSelectedIcon
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
}
