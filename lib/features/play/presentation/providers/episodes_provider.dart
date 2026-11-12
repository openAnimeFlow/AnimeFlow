import 'package:anime_flow/features/play/domain/play_session_actions.dart';
import 'package:anime_flow/features/play/domain/episodes_data.dart';
import 'package:anime_flow/features/play/application/episode_selection.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/subject_episodes/application/subject_episodes_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
export '../../domain/episodes_data.dart';
part 'episodes_provider.g.dart';

@Riverpod(dependencies: [playExtra])
class Episodes extends _$Episodes implements EpisodeActions {
  final selection = PlayEpisodeSelection();
  EpisodesData? get _currentData => state.asData?.value;

  @override
  Future<EpisodesData> build() async {
    final extra = ref.watch(playExtraProvider);
    final subjectId = extra.playExtra.subjectId;
    final requestedEpisodeId = extra.continueEpisodeId;
    if (extra.isOfflineMode) {
      return selection.offlineEpisodes(
          subjectId: subjectId,
          requestedEpisodeId: requestedEpisodeId,
          offlineEpisodeUrl: extra.offlineEpisodeUrl,
          availableEpisodes: [
            for (final episode in extra.offlineEpisodes)
              if (episode.localMediaPath.trim().isNotEmpty) episode,
          ]);
    }
    selection.request(subjectId, requestedEpisodeId);
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
    return selection.onlineEpisodes(
        subjectId, subjectEpisodes, requestedEpisodeId, _currentData);
  }

  /// 通过条目剧集列表的统一入口更新观看状态，复用生命周期与会话保护。
  @override
  Future<void> updateEpisodeWatched(int episodeId,
      {bool watched = true}) async {
    if (!ref.mounted) return;
    final current = _currentData;
    if (current == null || current.subjectId <= 0) return;
    await ref
        .read(subjectEpisodesProvider(current.subjectId).notifier)
        .updateEpisodeWatched(episodeId: episodeId, watched: watched);
  }

  @override
  bool hasNextEpisode() => selection.hasNextEpisode(_currentData,
      offline: ref.read(playExtraProvider).isOfflineMode);

  void selectEpisode(int episodeId) {
    final next = selection.selectEpisode(_currentData, episodeId);
    if (!identical(next, _currentData)) state = AsyncData(next);
  }

  @override
  void switchToNextEpisode() {
    final next = selection.nextEpisode(_currentData,
        offline: ref.read(playExtraProvider).isOfflineMode);
    if (next != null) state = AsyncData(next);
  }
}
