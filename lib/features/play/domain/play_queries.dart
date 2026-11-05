import 'package:anime_flow/shared/models/player/danmaku/danmaku_search_response.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/shared/models/player/bangumi/episode_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';

abstract interface class PlayQueries {
  Future<DanmakuSearchResponse> searchDanmaku(String keyword);
  Future<DanmakuEpisodeResponse> danmakuEpisodes(int id);
  Future<List<EpisodeComment>> comments(int episodeId);
  Future<SubjectItem> recommendations(int subjectId);
  Stream<OnlineCount> onlineCount(int subjectId);
}
