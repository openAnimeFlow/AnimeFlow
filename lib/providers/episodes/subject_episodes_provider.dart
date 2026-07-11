import 'package:anime_flow/network/api/flow_api.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subject_episodes_provider.g.dart';

const _episodesPageSize = 100;

class SubjectEpisodesState {
  SubjectEpisodesState({
    required EpisodesItem episodes,
    this.isLoadingMore = false,
  }) : episodes = _sortEpisodesItem(episodes);

  final EpisodesItem episodes;
  final bool isLoadingMore;

  bool get hasMore => episodes.data.length < episodes.total;

  SubjectEpisodesState copyWith({
    EpisodesItem? episodes,
    bool? isLoadingMore,
  }) {
    return SubjectEpisodesState(
      episodes: episodes ?? this.episodes,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  EpisodeSelection? selectionForContinueEpisode(int? continueEpisodeSort) {
    if (episodes.data.isEmpty) {
      return null;
    }
    if (continueEpisodeSort != null) {
      return findSelectionBySort(continueEpisodeSort) ??
          firstEpisodeSelection();
    }
    return nextWatchedEpisodeSelection() ?? firstEpisodeSelection();
  }

  /// 返回最后一个已观看剧集的下一集。
  ///
  /// 未通过路由指定剧集时，用它恢复到用户下一集应观看的内容。
  EpisodeSelection? nextWatchedEpisodeSelection() {
    var lastWatchedIndex = -1;
    for (var i = 0; i < episodes.data.length; i++) {
      if (episodes.data[i].watched == true) {
        lastWatchedIndex = i;
      }
    }

    if (lastWatchedIndex < 0 || lastWatchedIndex + 1 >= episodes.data.length) {
      return null;
    }

    final nextEpisode = episodes.data[lastWatchedIndex + 1];
    if (nextEpisode.name.isEmpty) {
      return null;
    }
    return _buildEpisodeSelection(
      episode: nextEpisode,
      index: lastWatchedIndex + 2,
    );
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

  EpisodeSelection? findSelectionBySort(int episodeSort) {
    for (var i = 0; i < episodes.data.length; i++) {
      final episode = episodes.data[i];
      if (episode.sort.toInt() == episodeSort) {
        return _buildEpisodeSelection(
          episode: episode,
          index: i + 1,
        );
      }
    }
    return null;
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

  bool hasNextEpisode(int currentEpisodeIndex) {
    return nextEpisodeSelection(currentEpisodeIndex) != null;
  }

  EpisodeSelection? nextEpisodeSelection(int currentEpisodeIndex) {
    if (episodes.data.isEmpty) {
      return null;
    }
    final nextEpisodeIndex = currentEpisodeIndex + 1;
    final dataIndex = nextEpisodeIndex - 1;
    if (dataIndex >= episodes.data.length) {
      return null;
    }
    final nextEpisode = episodes.data[dataIndex];
    if (nextEpisode.name.isEmpty) {
      return null;
    }
    return _buildEpisodeSelection(
      episode: nextEpisode,
      index: nextEpisodeIndex,
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

@riverpod
class SubjectEpisodes extends _$SubjectEpisodes {
  @override
  Future<SubjectEpisodesState> build(int subjectId) async {
    final episodes = await _fetchEpisodesPage(subjectId, offset: 0);
    return SubjectEpisodesState(episodes: episodes);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final episodes = await _fetchEpisodesPage(subjectId, offset: 0);
      return SubjectEpisodesState(episodes: episodes);
    });
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _fetchEpisodesPage(
        subjectId,
        offset: current.episodes.data.length,
      );
      final merged = current.episodes.copyWith(
        data: [...current.episodes.data, ...page.data],
        total: page.total,
      );
      state = AsyncData(
        SubjectEpisodesState(
          episodes: merged,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadUntilEpisodeSort(int episodeSort) async {
    var current = state.asData?.value;
    while (current != null &&
        current.hasMore &&
        !_containsEpisodeSort(current.episodes, episodeSort)) {
      await loadMore();
      current = state.asData?.value;
    }
  }

  Future<void> updateEpisodeWatched({
    required int episodeId,
    bool watched = true,
  }) async {
    await FlowApi.updateEpisodeWatchedService(
      episodeId,
      watched: watched,
    );
    setEpisodeWatched(
      episodeId: episodeId,
      watched: watched,
    );
  }

  void setEpisodeWatched({
    required int episodeId,
    required bool watched,
  }) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final index =
        current.episodes.data.indexWhere((episode) => episode.id == episodeId);
    if (index < 0 || current.episodes.data[index].watched == watched) {
      return;
    }
    final updatedEpisodes = [...current.episodes.data];
    updatedEpisodes[index] = updatedEpisodes[index].copyWith(watched: watched);
    state = AsyncData(
      current.copyWith(
        episodes: current.episodes.copyWith(data: updatedEpisodes),
      ),
    );
  }
}

Future<EpisodesItem> _fetchEpisodesPage(
  int subjectId, {
  required int offset,
}) {
  return FlowApi.getSubjectEpisodesByIdService(
    subjectId,
    _episodesPageSize,
    offset,
  );
}

bool _containsEpisodeSort(EpisodesItem episodes, int episodeSort) {
  return episodes.data.any((episode) => episode.sort.toInt() == episodeSort);
}
