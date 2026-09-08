import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subject_episodes_provider.g.dart';

const _episodesPageSize = 100;

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
  Future<bool>? _pendingPage;
  int _revision = 0;
  int _nextOffset = 0;

  @override
  Future<SubjectEpisodesState> build(int subjectId) async {
    final revision = ++_revision;
    _pendingPage = null;
    ref.onDispose(() => _revision++);
    final episodes = await fetchPage(subjectId, offset: 0);
    if (_isCurrent(revision)) _nextOffset = episodes.data.length;
    return SubjectEpisodesState(
      episodes: _deduplicate(episodes),
      isExhausted: episodes.data.isEmpty,
    );
  }

  Future<void> retry() async {
    ref.invalidateSelf();
    // Initial errors remain exposed through the provider's AsyncError.
    try {
      await future;
    } catch (_) {}
  }

  bool _isCurrent(int revision) => ref.mounted && revision == _revision;

  /// Returns whether new episodes were added. Concurrent callers share a request.
  Future<bool> loadMore() {
    final pending = _pendingPage;
    if (pending != null) return pending;
    final revision = _revision;
    final link = ref.keepAlive();
    late final Future<bool> request;
    request = _loadMore(revision).whenComplete(() {
      if (identical(_pendingPage, request)) _pendingPage = null;
      link.close();
    });
    return _pendingPage = request;
  }

  Future<bool> _loadMore(int revision) async {
    try {
      final current = await future;
      if (!_isCurrent(revision) || !current.hasMore) return false;
      state = AsyncData(current.copyWith(
        isLoadingMore: true,
        clearLoadMoreError: true,
      ));
      final page = await fetchPage(
        subjectId,
        offset: _nextOffset,
      );
      if (!_isCurrent(revision)) return false;
      // Preserve watched changes made while the page request was in flight.
      final latest = state.requireValue;
      final merged = _deduplicate(latest.episodes.copyWith(
        data: [...latest.episodes.data, ...page.data],
        total: page.total,
      ));
      final progressed = merged.data.length > latest.episodes.data.length;
      _nextOffset += page.data.length;
      state = AsyncData(
        latest.copyWith(
          episodes: merged,
          isLoadingMore: false,
          isExhausted: !progressed || _nextOffset >= page.total,
          clearLoadMoreError: true,
        ),
      );
      return progressed;
    } catch (error) {
      if (_isCurrent(revision)) {
        final current = state.asData?.value;
        if (current != null) {
          state = AsyncData(current.copyWith(
            isLoadingMore: false,
            loadMoreError: error,
          ));
        }
      }
      return false;
    }
  }

  Future<void> loadUntilEpisodeId(int episodeId) async {
    final link = ref.keepAlive();
    final revision = _revision;
    try {
      var current = await future;
      while (_isCurrent(revision)) {
        if (_containsEpisodeId(current.episodes, episodeId)) return;
        if (!current.hasMore) {
          throw StateError('未找到剧集 $episodeId');
        }
        final progressed = await loadMore();
        if (!_isCurrent(revision)) return;
        current = state.requireValue;
        if (!progressed) {
          throw current.loadMoreError ?? StateError('未找到剧集 $episodeId');
        }
      }
    } finally {
      link.close();
    }
  }

  @protected
  Future<EpisodesItem> fetchPage(int subjectId, {required int offset}) =>
      FlowApi.getSubjectEpisodesByIdService(
          subjectId, _episodesPageSize, offset);

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

  Future<void> markAllEpisodesWatched() async {
    await FlowApi.markAllEpisodesWatchedService(subjectId);

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        episodes: current.episodes.copyWith(
          data: current.episodes.data
              .map((episode) => episode.copyWith(watched: true))
              .toList(),
        ),
      ),
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

EpisodesItem _deduplicate(EpisodesItem episodes) {
  final seen = <int>{};
  return episodes.copyWith(
    data: episodes.data.where((episode) => seen.add(episode.id)).toList(),
  );
}

bool _containsEpisodeId(EpisodesItem episodes, int episodeId) {
  return episodes.data.any((episode) => episode.id == episodeId);
}
