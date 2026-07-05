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
    return _fetchInitialData(extra);
  }

  Future<EpisodesData> _fetchInitialData(PlayRouteExtra extra) async {
    final subjectId = extra.playExtra.subjectId;
    final continueEpisode = extra.continueEpisode ?? 0;

    var episodes = await FlowRequest.getSubjectEpisodesByIdService(
      subjectId,
      EpisodesPagination.pageSize,
      0,
    );

    while (continueEpisode > 0 &&
        continueEpisode > episodes.data.length &&
        EpisodesPagination.hasMore(episodes)) {
      final page = await FlowRequest.getSubjectEpisodesByIdService(
        subjectId,
        EpisodesPagination.pageSize,
        episodes.data.length,
      );
      episodes = EpisodesPagination.mergePages(cached: episodes, page: page);
    }

    if (episodes.data.isEmpty) {
      return EpisodesData(
        episodes: episodes,
        hasMore: EpisodesPagination.hasMore(episodes),
      );
    }

    final selection =
        continueEpisode > 0 && continueEpisode <= episodes.data.length
            ? _buildEpisodeSelection(
                episode: episodes.data[continueEpisode - 1],
                index: continueEpisode,
              )
            : _buildFirstNonCollectionSelection(episodes);

    return EpisodesData(
      episodes: episodes,
      episodeTitle: selection.title,
      episodeSort: selection.sort,
      episodeIndex: selection.index,
      episodeId: selection.id,
      hasMore: EpisodesPagination.hasMore(episodes),
    );
  }

  EpisodesData? get _currentData => state.asData?.value;

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final extra = ref.read(playExtraProvider);
      return _fetchInitialData(extra);
    });
  }

  /// 滚动到底部时加载更多剧集
  Future<void> loadMore() async {
    final current = _currentData;
    final episodes = current?.episodes;
    if (current == null ||
        episodes == null ||
        state.isLoading ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final subjectId = ref.read(playExtraProvider).playExtra.subjectId;
      final page = await FlowRequest.getSubjectEpisodesByIdService(
        subjectId,
        EpisodesPagination.pageSize,
        episodes.data.length,
      );
      final merged =
          EpisodesPagination.mergePages(cached: episodes, page: page);
      state = AsyncData(
        current.copyWith(
          episodes: merged,
          hasMore: EpisodesPagination.hasMore(merged),
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      LiggLogger().e(e);
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
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
    if (current.episodeIndex != episodeIndex) {
      LiggLogger().i('选中剧集索引:$episodeIndex');
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
