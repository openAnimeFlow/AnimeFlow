import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';
import 'package:anime_flow/shared/models/player/bangumi/episode_comments_item.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_search_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_query_providers.g.dart';

@Riverpod(dependencies: [playExtra])
Future<SubjectItem> recommendation(Ref ref) {
  final subjectId = ref.watch(playExtraProvider).playExtra.subjectId;
  return ref.watch(playQueriesProvider).recommendations(subjectId);
}

@Riverpod(dependencies: [Episodes])
Future<List<EpisodeComment>> episodeComments(Ref ref) async {
  final episodeId = ref.watch(
    episodesProvider.select((episodes) => episodes.value?.episodeId ?? 0),
  );

  if (episodeId <= 0) {
    return const [];
  }

  return ref.watch(playQueriesProvider).comments(episodeId);
}

@Riverpod(dependencies: [playExtra])
Stream<OnlineCount> subjectOnlineCount(Ref ref) {
  final subjectId = ref.watch(playExtraProvider).playExtra.subjectId;
  return ref.watch(playQueriesProvider).onlineCount(subjectId);
}

final danmakuSearchProvider = FutureProvider.autoDispose
    .family<DanmakuSearchResponse, String>((ref, keyword) =>
        ref.watch(playQueriesProvider).searchDanmaku(keyword));

final danmakuEpisodesProvider = FutureProvider.autoDispose
    .family<DanmakuEpisodeResponse, int>(
        (ref, id) => ref.watch(playQueriesProvider).danmakuEpisodes(id));
