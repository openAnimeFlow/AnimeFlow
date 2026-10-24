import 'dart:async';

import 'package:anime_flow/features/subject_episodes/data/repositories/subject_episodes_repository.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/user/user_events.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

@riverpod
class SubjectEpisodes extends _$SubjectEpisodes {
  Future<bool>? _pendingPage;
  int _revision = 0;
  int _nextOffset = 0;
  late CancelToken _cancelToken;
  String? _sessionId;
  Future<void>? _refreshFuture;
  final _watchedChanges = <int, bool>{};
  bool _allWatched = false;

  @override
  Future<SubjectEpisodesState> build(int subjectId) async {
    final revision = ++_revision;
    final cancelToken = _cancelToken = CancelToken();
    _pendingPage = null;
    _refreshFuture = null;
    _watchedChanges.clear();
    _allWatched = false;
    final forceRefresh = ref.isRefresh;
    ref.onDispose(() {
      _revision++;
      cancelToken.cancel();
    });
    // 观看状态属于当前账号；会话变化时重建，并等待凭证就绪后再请求。
    ref.watch(
        currentFlowTokenProvider.select((token) => token.value?.sessionId));
    ref.watch(collectionRevisionProvider);
    final repository = ref.watch(subjectEpisodesRepositoryProvider.notifier);
    final token = await ref.read(currentFlowTokenProvider.future);
    if (!_isCurrent(revision)) throw cancelToken.cancelError!;
    _sessionId = token?.sessionId;
    final cached = await repository.readPage(subjectId,
        sessionId: _sessionId, limit: _episodesPageSize, offset: 0);
    if (!_isCurrent(revision)) throw cancelToken.cancelError!;
    if (cached != null) {
      _nextOffset = cached.data.data.length;
      if (forceRefresh || !cached.isFresh) {
        // 先完成缓存展示，再刷新首页；后续翻页等待刷新结束，避免混用页边界。
        _refreshFuture = Future<void>(() => _refreshCachedPage(revision));
      }
      return _pageState(cached.data);
    }
    final episodes = await fetchPage(subjectId, offset: 0);
    if (_isCurrent(revision)) _nextOffset = episodes.data.length;
    return _pageState(episodes);
  }

  SubjectEpisodesState _pageState(EpisodesItem page) => SubjectEpisodesState(
        episodes: _deduplicate(_applyWatchedChanges(page)),
        isExhausted: page.data.isEmpty,
      );

  /// 刷新或分页响应不能覆盖当前页面中刚完成的观看状态修改。
  EpisodesItem _applyWatchedChanges(EpisodesItem page) => page.copyWith(
        data: page.data.map((episode) {
          final watched =
              _watchedChanges[episode.id] ?? (_allWatched ? true : null);
          return watched == null ? episode : episode.copyWith(watched: watched);
        }).toList(),
      );

  Future<void> _refreshCachedPage(int revision) async {
    if (!_isCurrent(revision)) return;
    try {
      final page = await ref
          .read(subjectEpisodesRepositoryProvider.notifier)
          .getPage(subjectId,
              sessionId: _sessionId,
              limit: _episodesPageSize,
              offset: 0,
              cancelToken: _cancelToken,
              forceRefresh: true,
              fallbackToCache: false);
      if (!_isCurrent(revision)) return;
      _nextOffset = page.data.length;
      state = AsyncData(_pageState(page));
    } catch (error) {
      // 刷新失败继续展示旧页，下一次进入或主动重试时再刷新。
      if (_isCurrent(revision)) debugPrint('刷新剧集缓存失败：$error');
    }
  }

  Future<void> retry() async {
    ref.invalidateSelf();
    // 首次加载失败仍通过 provider 的 AsyncError 展示。
    try {
      await future;
    } catch (_) {}
  }

  bool _isCurrent(int revision) => ref.mounted && revision == _revision;

  bool _isCurrentSession(int revision, String? sessionId) =>
      _isCurrent(revision) &&
      ref.read(currentFlowTokenProvider).value?.sessionId == sessionId;

  /// 返回是否新增了剧集，并发调用共享同一次分页请求。
  Future<bool> loadMore() {
    if (!ref.mounted) return Future.value(false);
    final pending = _pendingPage;
    if (pending != null) return pending;
    final revision = _revision;
    late final Future<bool> request;
    request = _loadMore(revision).whenComplete(() {
      if (identical(_pendingPage, request)) _pendingPage = null;
    });
    return _pendingPage = request;
  }

  Future<bool> _loadMore(int revision) async {
    try {
      await future;
      await _refreshFuture;
      if (!_isCurrent(revision)) return false;
      final current = state.requireValue;
      if (!current.hasMore) return false;
      state = AsyncData(current.copyWith(
        isLoadingMore: true,
        clearLoadMoreError: true,
      ));
      final page = await fetchPage(
        subjectId,
        offset: _nextOffset,
      );
      if (!_isCurrent(revision)) return false;
      // 保留分页请求期间发生的观看状态修改。
      final latest = state.requireValue;
      final merged = _deduplicate(latest.episodes.copyWith(
        data: [...latest.episodes.data, ..._applyWatchedChanges(page).data],
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
      ref.read(subjectEpisodesRepositoryProvider.notifier).getPage(subjectId,
          sessionId: _sessionId,
          limit: _episodesPageSize,
          offset: offset,
          cancelToken: _cancelToken);

  Future<void> updateEpisodeWatched({
    required int episodeId,
    bool watched = true,
  }) async {
    if (!ref.mounted) return;
    final revision = _revision;
    final sessionId = ref.read(currentFlowTokenProvider).value?.sessionId;
    await ref
        .read(subjectEpisodesRepositoryProvider.notifier)
        .updateEpisodeWatched(subjectId, episodeId,
            sessionId: sessionId, watched: watched);
    // 页面销毁、刷新或切换账号后，旧请求不能写回当前列表。
    if (!_isCurrentSession(revision, sessionId)) return;
    _applyEpisodeWatched(
      episodeId: episodeId,
      watched: watched,
    );
  }

  Future<void> markAllEpisodesWatched() async {
    if (!ref.mounted) return;
    final revision = _revision;
    final sessionId = ref.read(currentFlowTokenProvider).value?.sessionId;
    await ref
        .read(subjectEpisodesRepositoryProvider.notifier)
        .markAllEpisodesWatched(subjectId, sessionId: sessionId);
    if (!_isCurrentSession(revision, sessionId)) return;

    _allWatched = true;
    _watchedChanges.clear();
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
    if (!ref.mounted) return;
    unawaited(ref.read(subjectEpisodesRepositoryProvider.notifier).cacheWatched(
        subjectId,
        sessionId: _sessionId,
        episodeId: episodeId,
        watched: watched));
    _applyEpisodeWatched(episodeId: episodeId, watched: watched);
  }

  void _applyEpisodeWatched({
    required int episodeId,
    required bool watched,
  }) {
    _watchedChanges[episodeId] = watched;
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
