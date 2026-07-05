import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/service/episodes_pagination.dart';
import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'episodes_provider.g.dart';

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

/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。
@Riverpod(dependencies: [playExtra])
class Episodes extends _$Episodes {
  @override
  EpisodesData build() {
    final extra = ref.watch(playExtraProvider);
    // 异步加载剧集
    Future.microtask(() => _load(extra));
    return const EpisodesData();
  }

  /// 并定位到续播集数或首个正篇。
  Future<void> _load(PlayRouteExtra extra) async {
    final subjectId = extra.playExtra.subjectId;
    final continueEpisode = extra.continueEpisode ?? 0;

    state = state.copyWith(isLoading: true);
    try {
      // 加载首屏
      var episodes = await FlowRequest.getSubjectEpisodesByIdService(
        subjectId,
        EpisodesPagination.pageSize,
        0,
      );
      state = state.copyWith(
        episodes: episodes,
        hasMore: EpisodesPagination.hasMore(episodes),
      );

      // 如需续播，继续翻页直到 data 覆盖 continueEpisode
      while (continueEpisode > 0 &&
          continueEpisode > episodes.data.length &&
          EpisodesPagination.hasMore(episodes)) {
        final page = await FlowRequest.getSubjectEpisodesByIdService(
          subjectId,
          EpisodesPagination.pageSize,
          episodes.data.length,
        );
        episodes = EpisodesPagination.mergePages(cached: episodes, page: page);
        state = state.copyWith(
          episodes: episodes,
          hasMore: EpisodesPagination.hasMore(episodes),
        );
      }

      if (episodes.data.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      //  定位到续播集数
      if (continueEpisode > 0 && continueEpisode <= episodes.data.length) {
        final episode = episodes.data[continueEpisode - 1];
        _selectEpisode(episode, continueEpisode);
      } else {
        // 否则定位到首个非集合（正篇）
        _selectFirstNonCollection(episodes);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      LiggLogger().e(e);
      state = state.copyWith(isLoading: false);
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
      final merged =
          EpisodesPagination.mergePages(cached: episodes, page: page);
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

  void _selectEpisode(EpisodeData episode, int index) {
    setEpisodeSort(
      sort: episode.sort,
      episodeIndex: index,
      episodeId: episode.id,
    );
    setEpisodeTitle(
      episode.nameCN.isEmpty ? episode.name : episode.nameCN,
    );
  }

  void _selectFirstNonCollection(EpisodesItem episodes) {
    var targetIndex = 0;
    for (var i = 0; i < episodes.data.length; i++) {
      if (episodes.data[i].collection == null) {
        targetIndex = i;
        break;
      }
    }
    final target = episodes.data[targetIndex];
    setEpisodeSort(
      sort: target.sort,
      episodeIndex: targetIndex + 1,
      episodeId: target.id,
    );
    setEpisodeTitle(
      target.nameCN.isEmpty ? target.name : target.nameCN,
    );
  }
}
