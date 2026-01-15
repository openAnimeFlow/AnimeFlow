import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpisodesView extends StatelessWidget {
  const EpisodesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: PlayLayoutConstant.playContentWidth,
        height: double.infinity,
        padding: const EdgeInsets.only(top: 16, right: 16,left: 16),
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
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildEpisodesList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesList(BuildContext context) {
    final episodesState = Get.find<EpisodesState>();
    return Obx(() {
      final episodesData = episodesState.episodes.value;
      
      if (episodesData == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final episodeList = episodesData.data;
      if (episodeList.isEmpty) {
        return const Center(child: Text('暂无章节数据'));
      }

      return ListView.builder(
        itemCount: episodeList.length,
        itemBuilder: (BuildContext context, int index) {
          final episode = episodeList[index];
          return Obx(() {
            final isSelected = episodesState.episodeSort.value == episode.sort;
            return Card(
              elevation: 0,
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  final episodeIndex = index + 1;
                  episodesState.setEpisodeSort(
                    episodeId: episode.id,
                    episodeIndex: episodeIndex,
                    sort: episode.sort,
                  );
                  episodesState.setEpisodeTitle(episode.nameCN ?? episode.name);
                  Get.back();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第${episode.sort}话',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        episode.nameCN??episode.name,
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
          });
        },
      );
    });
  }
}
