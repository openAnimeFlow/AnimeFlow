import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'episode_comments_provider.g.dart';

@Riverpod(keepAlive: true, dependencies: [Episodes])
Future<List<EpisodeComment>> episodeComments(Ref ref) async {
  final episodeId = ref.watch(episodesProvider).asData?.value.episodeId ?? 0;

  if (episodeId <= 0) {
    return const [];
  }

  return FlowRequest.episodeCommentsService(episodeId: episodeId);
}
