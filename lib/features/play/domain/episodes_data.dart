import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';

class EpisodesData {
  const EpisodesData({
    this.subjectId = 0,
    this.episodes,
    this.episodeTitle = '',
    this.episodeSort = 0,
    this.episodeIndex = 0,
    this.episodeId = 0,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.loadMoreError,
  });

  /// 当前番剧 id
  final int subjectId;

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

  /// 分页失败时保留已有剧集，由界面展示错误并提供重试。
  final Object? loadMoreError;

  EpisodesData copyWith({
    int? subjectId,
    EpisodesItem? episodes,
    String? episodeTitle,
    double? episodeSort,
    int? episodeIndex,
    int? episodeId,
    bool? isLoadingMore,
    bool? hasMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return EpisodesData(
      subjectId: subjectId ?? this.subjectId,
      episodes: episodes ?? this.episodes,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeSort: episodeSort ?? this.episodeSort,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      episodeId: episodeId ?? this.episodeId,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadMoreError:
          clearLoadMoreError ? null : loadMoreError ?? this.loadMoreError,
    );
  }
}
