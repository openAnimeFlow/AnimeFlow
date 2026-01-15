import 'package:anime_flow/stores/episodes_state.dart';
import 'package:get/get.dart';

class EpisodeController extends GetxController{

  /// 判断是否有下一集（下一集的name字段不为空字符串）
  bool hasNextEpisode(EpisodesState episodesState) {
    final episodesData = episodesState.episodes.value;
    if (episodesData == null || episodesData.data.isEmpty) {
      return false;
    }

    final currentEpisodeIndex = episodesState.episodeIndex.value;
    // episodeIndex 是从1开始的，下一集的 episodeIndex 是 currentEpisodeIndex + 1
    final nextEpisodeIndex = currentEpisodeIndex + 1;

    // 检查下一集是否存在（数组索引是 nextEpisodeIndex - 1）
    if (nextEpisodeIndex - 1 >= episodesData.data.length) {
      return false;
    }

    final nextEpisode = episodesData.data[nextEpisodeIndex - 1];
    // 判断下一集的name字段是否不为空字符串
    return nextEpisode.name.isNotEmpty;
  }

  /// 切换到下一集
  void switchToNextEpisode(EpisodesState episodesState) {
    final episodesData = episodesState.episodes.value;
    if (episodesData == null || episodesData.data.isEmpty) {
      return;
    }

    final currentEpisodeIndex = episodesState.episodeIndex.value;
    // 下一集的索引（episodeIndex 从1开始，所以直接加1）
    final nextEpisodeIndex = currentEpisodeIndex + 1;

    // 检查下一集是否存在（数组索引是 nextEpisodeIndex - 1）
    if (nextEpisodeIndex - 1 >= episodesData.data.length) {
      return;
    }

    // 数组索引是 nextEpisodeIndex - 1（因为 episodeIndex 从1开始）
    final nextEpisode = episodesData.data[nextEpisodeIndex - 1];

    // 切换到下一集
    episodesState.setEpisodeSort(
      episodeId: nextEpisode.id,
      episodeIndex: nextEpisodeIndex,
      sort: nextEpisode.sort,
    );
    episodesState.setEpisodeTitle(nextEpisode.nameCN ?? nextEpisode.name);
  }
}