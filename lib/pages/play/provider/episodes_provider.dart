import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/provider/play_subject_provider.dart';
import 'package:anime_flow/pages/play/service/episodes_pagination.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'episodes_provider.g.dart';

/// 剧集状态数据（不可变）
class EpisodesData {
  const EpisodesData({
    this.episodes,
    this.episodeTitle = '',
    this.episodeSort = 0,
    this.episodeIndex = 0,
    this.episodeId = 0,
    this.isLoading = false,
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

  /// 是否正在加载首屏
  final bool isLoading;

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
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return EpisodesData(
      episodes: episodes ?? this.episodes,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeSort: episodeSort ?? this.episodeSort,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      episodeId: episodeId ?? this.episodeId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// 播放页剧集状态，生命周期与 [playRouteExtraProvider] 绑定。
@Riverpod(dependencies: [playRouteExtra])
class Episodes extends _$Episodes {
  @override
  EpisodesData build() {
    ref.watch(playRouteExtraProvider);
    return const EpisodesData();
  }

  /// 重置为初始状态（进入播放页时调用，确保获得全新状态）
  void reset() {
    state = const EpisodesData();
  }

  /// 加载首屏剧集
  Future<void> loadInitial(int subjectId) async {
    if (state.episodes != null || state.isLoading) {
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final episodes = await FlowRequest.getSubjectEpisodesByIdService(
        subjectId,
        EpisodesPagination.pageSize,
        0,
      );
      state = state.copyWith(
        episodes: episodes,
        hasMore: EpisodesPagination.hasMore(episodes),
        isLoading: false,
      );
    } catch (e) {
      LiggLogger().e(e);
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// 滚动到底部时加载更多剧集
  Future<void> loadMore(int subjectId) async {
    final episodes = state.episodes;
    if (episodes == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await FlowRequest.getSubjectEpisodesByIdService(
        subjectId,
        EpisodesPagination.pageSize,
        episodes.data.length,
      );
      final merged = EpisodesPagination.mergePages(cached: episodes, page: page);
      state = state.copyWith(
        episodes: merged,
        hasMore: EpisodesPagination.hasMore(merged),
        isLoadingMore: false,
      );
    } catch (e) {
      LiggLogger().e(e);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// 设置剧集列表数据
  void setEpisodes(EpisodesItem episodes) {
    state = state.copyWith(
      episodes: episodes,
      hasMore: EpisodesPagination.hasMore(episodes),
    );
  }

  /// 设置加载状态
  void setLoading(bool isLoading) {
    if (state.isLoading == isLoading) return;
    state = state.copyWith(isLoading: isLoading);
  }

  /// 设置当前剧集标题
  void setEpisodeTitle(String title) {
    if (state.episodeTitle == title) return;
    state = state.copyWith(episodeTitle: title);
  }

  /// 设置当前选中剧集
  void setEpisodeSort({
    required num sort,
    required int episodeIndex,
    required int episodeId,
  }) {
    if (state.episodeIndex != episodeIndex) {
      LiggLogger().i('选中剧集索引:$episodeIndex');
    }
    state = state.copyWith(
      episodeSort: sort.toDouble(),
      episodeIndex: episodeIndex,
      episodeId: episodeId,
    );
  }

  /// 是否存在下一集（下一集的 name 字段不为空字符串）
  bool get hasNextEpisode {
    final episodesData = state.episodes;
    if (episodesData == null || episodesData.data.isEmpty) {
      return false;
    }
    // episodeIndex 从 1 开始，下一集索引为 episodeIndex + 1
    final nextEpisodeIndex = state.episodeIndex + 1;
    if (nextEpisodeIndex - 1 >= episodesData.data.length) {
      return false;
    }
    return episodesData.data[nextEpisodeIndex - 1].name.isNotEmpty;
  }

  /// 切换到下一集
  void switchToNextEpisode() {
    final episodesData = state.episodes;
    if (episodesData == null || episodesData.data.isEmpty) {
      return;
    }
    final nextEpisodeIndex = state.episodeIndex + 1;
    if (nextEpisodeIndex - 1 >= episodesData.data.length) {
      return;
    }
    final nextEpisode = episodesData.data[nextEpisodeIndex - 1];
    setEpisodeSort(
      episodeId: nextEpisode.id,
      episodeIndex: nextEpisodeIndex,
      sort: nextEpisode.sort,
    );
    setEpisodeTitle(
      nextEpisode.nameCN.isEmpty ? nextEpisode.name : nextEpisode.nameCN,
    );
  }
}
