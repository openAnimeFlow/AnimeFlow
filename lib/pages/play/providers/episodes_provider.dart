import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'episodes_provider.g.dart';

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

  EpisodesData copyWith({
    int? subjectId,
    EpisodesItem? episodes,
    String? episodeTitle,
    double? episodeSort,
    int? episodeIndex,
    int? episodeId,
    bool? isLoadingMore,
    bool? hasMore,
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
    );
  }
}

/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。
@Riverpod(dependencies: [playExtra])
class Episodes extends _$Episodes {
  int? _selectedSubjectId;
  int? _selectedEpisodeId;
  int? _lastRequestedEpisodeId;

  @override
  Future<EpisodesData> build() async {
    final extra = ref.watch(playExtraProvider);
    final subjectId = extra.playExtra.subjectId;
    final requestedEpisodeId = extra.continueEpisodeId;
    if (_selectedSubjectId != subjectId) {
      _selectedSubjectId = null;
      _selectedEpisodeId = null;
      _lastRequestedEpisodeId = null;
    }
    if (requestedEpisodeId != null &&
        requestedEpisodeId != _lastRequestedEpisodeId) {
      _selectedSubjectId = subjectId;
      _selectedEpisodeId = requestedEpisodeId;
      _lastRequestedEpisodeId = requestedEpisodeId;
    }
    if (requestedEpisodeId != null) {
      await ref
          .read(subjectEpisodesProvider(subjectId).notifier)
          .loadUntilEpisodeId(requestedEpisodeId);
    }
    final subjectEpisodesAsync = ref.watch(subjectEpisodesProvider(subjectId));
    final subjectEpisodes = switch (subjectEpisodesAsync) {
      AsyncData(:final value) => value,
      AsyncError(:final error, :final stackTrace) =>
        Error.throwWithStackTrace(error, stackTrace),
      _ => await ref.watch(subjectEpisodesProvider(subjectId).future),
    };
    return _buildEpisodesData(subjectId, subjectEpisodes);
  }

  EpisodesData _buildEpisodesData(
    int subjectId,
    SubjectEpisodesState subjectEpisodes,
  ) {
    final episodes = subjectEpisodes.episodes;
    final continueEpisodeId = ref.read(playExtraProvider).continueEpisodeId;
    final current = _currentData;
    final selectedEpisodeId =
        _selectedSubjectId == subjectId ? _selectedEpisodeId : null;

    if (episodes.data.isEmpty) {
      return EpisodesData(
        subjectId: subjectId,
        episodes: episodes,
        isLoadingMore: subjectEpisodes.isLoadingMore,
        hasMore: subjectEpisodes.hasMore,
      );
    }

    final selection = current != null && current.subjectId == subjectId
        ? subjectEpisodes.findSelectionById(current.episodeId) ??
            _findSelectedEpisode(
              subjectEpisodes,
              selectedEpisodeId: selectedEpisodeId,
            ) ??
            _selectionForContinueEpisode(
              subjectEpisodes,
              continueEpisodeId: continueEpisodeId,
            )
        : _findSelectedEpisode(
              subjectEpisodes,
              selectedEpisodeId: selectedEpisodeId,
            ) ??
            _selectionForContinueEpisode(
              subjectEpisodes,
              continueEpisodeId: continueEpisodeId,
            );
    if (selection == null) {
      return EpisodesData(
        subjectId: subjectId,
        episodes: episodes,
        isLoadingMore: subjectEpisodes.isLoadingMore,
        hasMore: subjectEpisodes.hasMore,
      );
    }

    _selectedSubjectId = subjectId;
    _selectedEpisodeId = selection.id;

    return EpisodesData(
      subjectId: subjectId,
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

  EpisodeSelection? _findSelectedEpisode(
    SubjectEpisodesState subjectEpisodes, {
    required int? selectedEpisodeId,
  }) {
    if (selectedEpisodeId == null) {
      return null;
    }
    return subjectEpisodes.findSelectionById(selectedEpisodeId);
  }

  EpisodeSelection? _selectionForContinueEpisode(
    SubjectEpisodesState subjectEpisodes, {
    required int? continueEpisodeId,
  }) {
    if (continueEpisodeId != null) {
      return subjectEpisodes.findSelectionById(continueEpisodeId);
    }
    return subjectEpisodes.selectionForContinueEpisode();
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
    _selectedSubjectId = current.subjectId;
    _selectedEpisodeId = episodeId;
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
    return SubjectEpisodesState(episodes: episodesData).hasNextEpisode(
      current.episodeIndex,
    );
  }

  /// 切换到下一集
  void switchToNextEpisode() {
    final current = _currentData;
    final episodesData = current?.episodes;
    if (current == null || episodesData == null || episodesData.data.isEmpty) {
      return;
    }
    final selection = SubjectEpisodesState(episodes: episodesData)
        .nextEpisodeSelection(current.episodeIndex);
    if (selection == null) return;
    _selectedSubjectId = current.subjectId;
    _selectedEpisodeId = selection.id;
    state = AsyncData(
      current.copyWith(
        episodeSort: selection.sort,
        episodeIndex: selection.index,
        episodeId: selection.id,
        episodeTitle: selection.title,
      ),
    );
  }
}
