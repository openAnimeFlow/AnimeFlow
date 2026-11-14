import 'package:anime_flow/features/play/domain/play_queries.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_search_response.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/shared/models/player/bangumi/episode_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';
import 'dart:async';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/presence/presence_service.dart';
import 'package:dio/dio.dart';

class FlowPlayQueries implements PlayQueries {
  static Future<void> markEpisodeWatched(int episodeId) =>
      FlowApi.updateEpisodeWatchedService(episodeId, watched: true);

  @override
  Future<DanmakuSearchResponse> searchDanmaku(String keyword) =>
      FlowApi.searchDanmakuEpisodes(keyword);
  @override
  Future<DanmakuEpisodeResponse> danmakuEpisodes(int id) =>
      FlowApi.getDanDanEpisodesByDanDanBangumiID(id);
  @override
  Future<List<EpisodeComment>> comments(int episodeId) =>
      FlowApi.episodeCommentsService(episodeId: episodeId);
  @override
  Future<SubjectItem> recommendations(int subjectId) =>
      FlowApi.getBangumiRecommendationService(subjectId);
  @override
  Stream<OnlineCount> onlineCount(int subjectId) {
    final cancel = CancelToken();
    late StreamSubscription<OnlineCount> subscription;
    late final StreamController<OnlineCount> controller;
    controller = StreamController<OnlineCount>(
      onListen: () {
        subscription = FlowApi.getSubjectPresenceOnlineCount(
                subjectId, PresenceService.instance.presenceId, cancel)
            .listen(controller.add,
                onError: controller.addError, onDone: controller.close);
      },
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () {
        cancel.cancel('subject online count disposed');
        return subscription.cancel();
      },
    );
    return controller.stream;
  }
}
