import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EpisodesDialog extends ConsumerWidget {
  const EpisodesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesState = ref.watch(episodesProvider);
    final episodes = episodesState.episodes?.data;
    final selectedEpisode = episodesState.episodeSort;

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
                episodes: episodes,
                selectedEpisode: selectedEpisode,
                isLoading: episodesState.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesList(
    BuildContext context,
    WidgetRef ref, {
    required List<EpisodeData>? episodes,
    required double selectedEpisode,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (episodes == null || episodes.isEmpty) {
      return const Center(child: Text('暂无章节数据'));
    }

    return ListView.builder(
      itemCount: episodes.length,
      itemBuilder: (BuildContext context, int index) {
        final episode = episodes[index];
        final isSelected = selectedEpisode == episode.sort;
        return Card(
          elevation: 0,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          margin: const EdgeInsets.only(bottom: 8),
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
        );
      },
    );
  }
}
