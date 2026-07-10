import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EpisodesDialog extends ConsumerWidget {
  final void Function(int episodeId)? onEpisodeLongPress;
  const EpisodesDialog({super.key, this.onEpisodeLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        padding: const EdgeInsets.all(16),
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
                ref,
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

  void _sortEpisodes(List<EpisodeData> episodes) {
    episodes.sort((a, b) {
      final aIsMain = a.type == 0 ? 0 : 1;
      final bIsMain = b.type == 0 ? 0 : 1;
      if (aIsMain != bIsMain) return aIsMain.compareTo(bIsMain);
      if (a.type != b.type) return a.type.compareTo(b.type);
      return a.sort.compareTo(b.sort);
    });
  }

  Widget _buildEpisodesList(
    BuildContext context,
    WidgetRef ref, {
    required AsyncValue<EpisodesData> episodesAsync,
    required List<EpisodeData>? episodes,
    required int selectedEpisodeId,
    required int subjectId,
  }) {
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

    // 正篇置顶，其他按 type 分组排列
    _sortEpisodes(episodes);

    return ListView.builder(
      itemCount: episodes.length,
      itemBuilder: (BuildContext context, int index) {
        final episode = episodes[index];
        final isSelected = selectedEpisodeId == episode.id;
        final colorScheme = Theme.of(context).colorScheme;
        return Card(
          elevation: 0,
          color: isSelected ? colorScheme.primaryContainer : null,
          margin: index != episodes.length - 1
              ? const EdgeInsets.only(bottom: 8)
              : null,
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
            onLongPress: () => onEpisodeLongPress?.call(episode.id),
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
                      episode.nameCN.isEmpty ? episode.name : episode.nameCN,
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
            ),
          ),
        );
      },
    );
  }
}
