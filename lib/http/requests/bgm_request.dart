import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api/bgm_api.dart';
import 'package:anime_flow/http/api/common_api.dart';
import 'package:anime_flow/models/item/calendar_item.dart';
import 'package:anime_flow/models/item/episode_comments_item.dart';
import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:anime_flow/models/item/search_item.dart';
import 'package:anime_flow/models/item/subject_comments_item.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:anime_flow/utils/http/dio_request.dart';
import 'package:dio/dio.dart';

class BgmRequest {
  static const String _nextBaseUrl = BgmNextApi.nextBaseUrl;

  /// 获取热门
  static Future<HotItem> getHotService(int limit, int offset) async {
    final response = await dioRequest.get(_nextBaseUrl + BgmNextApi.hot,
        queryParameters: {"type": 2, "limit": limit, "offset": offset},
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return HotItem.fromJson(response.data);
  }

  ///根据id获取条目
  static Future<SubjectsItem> getSubjectByIdService(int id) async {
    final response = await dioRequest.get(
        _nextBaseUrl +
            BgmNextApi.subjectById.replaceFirst('{subjectId}', id.toString()),
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return SubjectsItem.fromJson(response.data);
  }

  ///获取条目章节
  static Future<EpisodesItem> getSubjectEpisodesByIdService(
      int id, int limit, int offset) async {
    final response = await dioRequest.get(
        _nextBaseUrl +
            BgmNextApi.episodes.replaceFirst('{subjectId}', id.toString()),
        queryParameters: {"limit": limit, "offset": offset},
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return EpisodesItem.fromJson(response.data);
  }

  ///获取条目评论
  static Future<SubjectCommentItem> getSubjectCommentsByIdService({
    required int limit,
    required int offset,
    required int subjectId,
  }) async {
    final response = await dioRequest.get(
      _nextBaseUrl +
          BgmNextApi.subjectComments
              .replaceFirst('{subjectId}', subjectId.toString()),
      queryParameters: {
        "type": 2,
        "limit": limit,
        "offset": offset,
      },
      options: Options(
        headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
      ),
    );
    return SubjectCommentItem.fromJson(response.data);
  }

  ///条目搜索
  static Future<SearchItem> searchSubjectService(
      {required String keyword,
      required int limit,
      required int offset}) async {
    final response = await dioRequest.post(
      _nextBaseUrl + BgmNextApi.search,
      queryParameters: {
        "limit": limit,
        "offset": offset,
      },
      data: {
        "filter": {
          "type": [2]
        },
        "keyword": keyword,
      },
      options: Options(
        headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
      ),
    );

    return SearchItem.fromJson(response.data);
  }

  ///每日放送
  static Future<Calendar> calendarService() async {
    final response = await dioRequest.get(
      _nextBaseUrl + BgmNextApi.calendar,
      options: Options(
        headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
      ),
    );
    return Calendar.fromJson(response.data);
  }

  ///剧集评论
  static Future<List<EpisodeComment>> episodeCommentsService({
    required int episodeId,
  }) async {
    final response = await dioRequest.get(_nextBaseUrl +
        BgmNextApi.episodeComments
            .replaceFirst('{episodeId}', episodeId.toString()));
    final data = response.data as List<dynamic>;
    return data
        .map((item) => EpisodeComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
