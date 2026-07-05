import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/service/episodes_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subject_episodes_provider.g.dart';

class SubjectEpisodesState {
  const SubjectEpisodesState({
    required this.episodes,
    this.isLoadingMore = false,
  });

  final EpisodesItem episodes;
  final bool isLoadingMore;

  bool get hasMore => EpisodesPagination.hasMore(episodes);

  SubjectEpisodesState copyWith({
    EpisodesItem? episodes,
    bool? isLoadingMore,
  }) {
    return SubjectEpisodesState(
      episodes: episodes ?? this.episodes,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
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
      final merged = EpisodesPagination.mergePages(
        cached: current.episodes,
        page: page,
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
}

Future<EpisodesItem> _fetchEpisodesPage(
  int subjectId, {
  required int offset,
}) {
  return FlowRequest.getSubjectEpisodesByIdService(
    subjectId,
    EpisodesPagination.pageSize,
    offset,
  );
}

bool _containsEpisodeSort(EpisodesItem episodes, int episodeSort) {
  return episodes.data.any((episode) => episode.sort.toInt() == episodeSort);
}
