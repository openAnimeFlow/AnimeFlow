import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';

class SubjectEpisodesState {
  SubjectEpisodesState({
    required EpisodesItem episodes,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isExhausted = false,
  }) : episodes = _sortEpisodesItem(episodes);

  final EpisodesItem episodes;
  final bool isLoadingMore;
  final Object? loadMoreError;
  final bool isExhausted;

  bool get hasMore => !isExhausted && episodes.data.length < episodes.total;

  SubjectEpisodesState copyWith({
    EpisodesItem? episodes,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
    bool? isExhausted,
  }) {
    return SubjectEpisodesState(
      episodes: episodes ?? this.episodes,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : loadMoreError ?? this.loadMoreError,
      isExhausted: isExhausted ?? this.isExhausted,
    );
  }

  EpisodeSelection? selectionForContinueEpisode() {
    if (episodes.data.isEmpty) {
      return null;
    }
    return nextWatchedEpisodeSelection() ?? firstEpisodeSelection();
  }

  /// 返回最后一个已观看剧集之后、已到播出日期的下一集。
  ///
  /// 未通过路由指定剧集时，用它恢复到用户下一集应观看的内容。
  EpisodeSelection? nextWatchedEpisodeSelection() {
    var lastWatchedIndex = -1;
    for (var i = 0; i < episodes.data.length; i++) {
      if (episodes.data[i].watched == true) {
        lastWatchedIndex = i;
      }
    }

    if (lastWatchedIndex < 0) return null;
    return nextEpisodeSelection(lastWatchedIndex + 1);
  }

  EpisodeSelection? firstEpisodeSelection() {
    if (episodes.data.isEmpty) {
      return null;
    }
    return _buildEpisodeSelection(
      episode: episodes.data.first,
      index: 1,
    );
  }

  EpisodeSelection? findSelectionById(int episodeId) {
    for (var i = 0; i < episodes.data.length; i++) {
      final episode = episodes.data[i];
      if (episode.id == episodeId) {
        return _buildEpisodeSelection(
          episode: episode,
          index: i + 1,
        );
      }
    }
    return null;
  }

  bool hasNextEpisode(int currentEpisodeIndex, {bool requireAired = true}) {
    return nextEpisodeSelection(currentEpisodeIndex,
            requireAired: requireAired) !=
        null;
  }

  /// 在线选集要求下一集已播出；离线选集由本地文件列表决定。
  EpisodeSelection? nextEpisodeSelection(int currentEpisodeIndex,
      {bool requireAired = true}) {
    if (currentEpisodeIndex < 1 ||
        currentEpisodeIndex >= episodes.data.length) {
      return null;
    }
    final nextEpisode = episodes.data[currentEpisodeIndex];
    if (requireAired && !nextEpisode.hasAired) {
      return null;
    }
    return _buildEpisodeSelection(
      episode: nextEpisode,
      index: currentEpisodeIndex + 1,
    );
  }

  EpisodeSelection _buildEpisodeSelection({
    required EpisodeData episode,
    required int index,
  }) {
    return EpisodeSelection(
      id: episode.id,
      index: index,
      sort: episode.sort.toDouble(),
      title: episode.nameCN.isEmpty ? episode.name : episode.nameCN,
    );
  }
}

class EpisodeSelection {
  const EpisodeSelection({
    required this.id,
    required this.index,
    required this.sort,
    required this.title,
  });

  final int id;
  final int index;
  final double sort;
  final String title;
}

EpisodesItem _sortEpisodesItem(EpisodesItem episodes) {
  final sortedEpisodes = [...episodes.data]..sort(_compareEpisodes);
  return episodes.copyWith(data: sortedEpisodes);
}

int _compareEpisodes(EpisodeData a, EpisodeData b) {
  final aIsMain = a.type == 0 ? 0 : 1;
  final bIsMain = b.type == 0 ? 0 : 1;
  if (aIsMain != bIsMain) {
    return aIsMain.compareTo(bIsMain);
  }
  if (a.type != b.type) {
    return a.type.compareTo(b.type);
  }
  final sortComparison = a.sort.compareTo(b.sort);
  if (sortComparison != 0) {
    return sortComparison;
  }
  return a.id.compareTo(b.id);
}
