import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'episodes_provider.g.dart';

class EpisodesData {
  const EpisodesData({
    this.episodes,
    this.episodeTitle = '',
    this.episodeSort = 0,
    this.episodeIndex = 0,
    this.episodeId = 0,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  /// 剧集列表数据
  final EpisodesItem? episodes;

  /// 当前剧集标题
  final String episodeTitle;

  /// 当前剧集 sort
  final double episodeSort;

  /// 当前剧集序号（从 1 开始）
  final int episodeIndex;

  /// 当前剧集 id
  final int episodeId;

  /// 是否正在加载更多
  final bool isLoadingMore;

  /// 是否还有更多剧集可加载
  final bool hasMore;

  EpisodesData copyWith({
    EpisodesItem? episodes,
    String? episodeTitle,
    double? episodeSort,
    int? episodeIndex,
    int? episodeId,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return EpisodesData(
      episodes: episodes ?? this.episodes,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeSort: episodeSort ?? this.episodeSort,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      episodeId: episodeId ?? this.episodeId,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。
@Riverpod(dependencies: [playExtra])
class Episodes extends _$Episodes {
  @override
  Future<EpisodesData> build() async {
    final extra = ref.watch(playExtraProvider);
    final subjectId = extra.playExtra.subjectId;
    final requestedEpisodeSort = extra.continueEpisode;
    if (requestedEpisodeSort != null) {
      await ref
          .read(subjectEpisodesProvider(subjectId).notifier)
          .loadUntilEpisodeSort(requestedEpisodeSort);
    }
    final subjectEpisodes =
        await ref.watch(subjectEpisodesProvider(subjectId).future);
    return _buildEpisodesData(extra, subjectEpisodes);
  }

  EpisodesData _buildEpisodesData(
    PlayRouteExtra extra,
    SubjectEpisodesState subjectEpisodes,
  ) {
    final episodes = subjectEpisodes.episodes;
    final continueEpisodeSort = extra.continueEpisode;

    if (episodes.data.isEmpty) {
      return EpisodesData(
        episodes: episodes,
        isLoadingMore: subjectEpisodes.isLoadingMore,
        hasMore: subjectEpisodes.hasMore,
      );
    }

    final selection = continueEpisodeSort != null
        ? _findEpisodeSelectionBySort(episodes, continueEpisodeSort) ??
            _buildFirstNonCollectionSelection(episodes)
        : _buildFirstNonCollectionSelection(episodes);

    return EpisodesData(
      episodes: episodes,
      episodeTitle: selection.title,
      episodeSort: selection.sort,
      episodeIndex: selection.index,
      episodeId: selection.id,
      isLoadingMore: subjectEpisodes.isLoadingMore,
      hasMore: subjectEpisodes.hasMore,
    );
  }

  EpisodesData? get _currentData => state.asData?.value;

  Future<void> retry() async {
    final extra = ref.read(playExtraProvider);
    final subjectId = extra.playExtra.subjectId;
    ref.invalidate(subjectEpisodesProvider(subjectId));
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final subjectEpisodes =
          await ref.read(subjectEpisodesProvider(subjectId).future);
      return _buildEpisodesData(extra, subjectEpisodes);
    });
  }

  Future<void> loadMore() async {
    final current = _currentData;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    final extra = ref.read(playExtraProvider);
    final subjectId = extra.playExtra.subjectId;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    await ref.read(subjectEpisodesProvider(subjectId).notifier).loadMore();
    final subjectEpisodes =
        ref.read(subjectEpisodesProvider(subjectId)).asData?.value;
    if (subjectEpisodes == null) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      return;
    }
    state = AsyncData(_buildEpisodesData(extra, subjectEpisodes));
  }

  void setEpisodeTitle(String title) {
    final current = _currentData;
    if (current == null || current.episodeTitle == title) {
      return;
    }
    state = AsyncData(current.copyWith(episodeTitle: title));
  }

  void setEpisodeSort({
    required num sort,
    required int episodeIndex,
    required int episodeId,
  }) {
    final current = _currentData;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        episodeSort: sort.toDouble(),
        episodeIndex: episodeIndex,
        episodeId: episodeId,
      ),
    );
  }

  /// 是否存在下一集（下一集的 name 字段不为空字符串）
  bool get hasNextEpisode {
    final current = _currentData;
    final episodesData = current?.episodes;
    if (current == null || episodesData == null || episodesData.data.isEmpty) {
      return false;
    }
    final nextEpisodeIndex = current.episodeIndex + 1;
    if (nextEpisodeIndex - 1 >= episodesData.data.length) {
      return false;
    }
    return episodesData.data[nextEpisodeIndex - 1].name.isNotEmpty;
  }

  /// 切换到下一集
  void switchToNextEpisode() {
    final current = _currentData;
    final episodesData = current?.episodes;
    if (current == null || episodesData == null || episodesData.data.isEmpty) {
      return;
    }
    final nextEpisodeIndex = current.episodeIndex + 1;
    if (nextEpisodeIndex - 1 >= episodesData.data.length) {
      return;
    }
    final nextEpisode = episodesData.data[nextEpisodeIndex - 1];
    final title =
        nextEpisode.nameCN.isEmpty ? nextEpisode.name : nextEpisode.nameCN;
    state = AsyncData(
      current.copyWith(
        episodeSort: nextEpisode.sort.toDouble(),
        episodeIndex: nextEpisodeIndex,
        episodeId: nextEpisode.id,
        episodeTitle: title,
      ),
    );
  }

  _EpisodeSelection _buildEpisodeSelection({
    required EpisodeData episode,
    required int index,
  }) {
    return _EpisodeSelection(
      id: episode.id,
      index: index,
      sort: episode.sort.toDouble(),
      title: episode.nameCN.isEmpty ? episode.name : episode.nameCN,
    );
  }

  _EpisodeSelection _buildFirstNonCollectionSelection(EpisodesItem episodes) {
    var targetIndex = 0;
    for (var i = 0; i < episodes.data.length; i++) {
      if (episodes.data[i].collection == null) {
        targetIndex = i;
        break;
      }
    }
    return _buildEpisodeSelection(
      episode: episodes.data[targetIndex],
      index: targetIndex + 1,
    );
  }

  _EpisodeSelection? _findEpisodeSelectionBySort(
    EpisodesItem episodes,
    int episodeSort,
  ) {
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
}

class _EpisodeSelection {
  const _EpisodeSelection({
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
