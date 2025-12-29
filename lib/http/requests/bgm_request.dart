import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api/bgm_api.dart';
import 'package:anime_flow/http/api/common_api.dart';
import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/models/item/bangumi/actor_ite.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/bangumi/collections_item.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:anime_flow/models/item/bangumi/related_subjects_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/http/dio/bgm_dio_request.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class BgmRequest {
  static const String _nextBaseUrl = BgmNextApi.baseUrl;
  static final Logger _logger = Logger();

  /// 获取热门
  static Future<HotItem> getHotService(int limit, int offset) async {
    final response = await dioRequest.get(_nextBaseUrl + BgmNextApi.hot,
        queryParameters: {'type': 2, 'limit': limit, 'offset': offset},
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return HotItem.fromJson(response.data);
  }

  ///根据id获取条目
  static Future<SubjectsInfoItem> getSubjectByIdService(int id) async {
    final response = await bgmDioRequest.get(
        '$_nextBaseUrl${BgmNextApi.subjects}/$id',
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return SubjectsInfoItem.fromJson(response.data);
  }

  ///获取条目章节
  static Future<EpisodesItem> getSubjectEpisodesByIdService(
      int id, int limit, int offset) async {
    try {
      final response = await bgmDioRequest.get(
          _nextBaseUrl +
              BgmNextApi.episodes.replaceFirst('{subjectId}', id.toString()),
          queryParameters: {'limit': limit, 'offset': offset},
          options: Options(
              headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
      return EpisodesItem.fromJson(response.data);
    } catch (e) {
      _logger.e(e);
      throw Exception('Failed to fetch episodes: $e');
    }
  }

  ///获取条目评论
  static Future<SubjectCommentItem> getSubjectCommentsByIdService({
    required int limit,
    required int offset,
    required int subjectId,
  }) async {
    final response = await bgmDioRequest.get(
      _nextBaseUrl +
          BgmNextApi.subjectComments
              .replaceFirst('{subjectId}', subjectId.toString()),
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      options: Options(
        headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
      ),
    );
    try {
      return SubjectCommentItem.fromJson(response.data);
    } catch (e) {
      _logger.e(e);
      throw Exception('Failed to fetch comments: $e');
    }
  }

  ///条目搜索
  static Future<SubjectItem> searchSubjectService(
      {required String keyword,
      required int limit,
      required int offset}) async {
    final response = await dioRequest.post(
      _nextBaseUrl + BgmNextApi.search,
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      data: {
        'filter': {
          'type': [2]
        },
        'keyword': keyword,
      },
      options: Options(
        headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
      ),
    );

    return SubjectItem.fromJson(response.data);
  }

  ///每日放送
  static Future<Calendar> calendarService() async {
    return await bgmDioRequest
        .get(
          _nextBaseUrl + BgmNextApi.calendar,
          options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
          ),
        )
        .then((value) => Calendar.fromJson(value.data));
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

  ///角色信息
  static Future<CharactersItem> charactersService(int subjectId,
      {required int limit, required int offset, int? type}) async {
    final queryParameters = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (type != null) {
      queryParameters['type'] = type;
    }
    return dioRequest
        .get(
          _nextBaseUrl +
              BgmNextApi.characters
                  .replaceFirst('{subjectId}', subjectId.toString()),
          queryParameters: queryParameters,
          options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
          ),
        )
        .then((response) => (CharactersItem.fromJson(response.data)));
  }

  ///相关条目
  static Future<SubjectRelationItem> relatedSubjectsService(int subjectId,
      {required int limit, required int offset, int? type = 2}) async {
    return dioRequest.get(
      _nextBaseUrl +
          BgmNextApi.relations
              .replaceFirst('{subjectId}', subjectId.toString()),
      queryParameters: {
        'type': type,
        'limit': limit,
        'offset': offset,
      },
    ).then((response) => (SubjectRelationItem.fromJson(response.data)));
  }

  ///排行
  static Future<SubjectItem> rankService({
    int? type = 2,
    required SortType sort,
    int? cat,
    int? year,
    int? month,
    List<String>? tags,
    required int page,
  }) async {
    final queryParameters = <String, dynamic>{};
    queryParameters['sort'] = sort.value;
    queryParameters['page'] = page;
    if (type != null) queryParameters['type'] = type;
    if (cat != null) queryParameters['cat'] = cat;
    if (year != null) queryParameters['year'] = year;
    if (month != null) queryParameters['month'] = month;
    if (tags != null) queryParameters['tags'] = tags;

    return dioRequest
        .get(
          _nextBaseUrl + BgmNextApi.subjects,
          queryParameters: queryParameters,
          options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
          ),
        )
        .then((response) => (SubjectItem.fromJson(response.data)));
  }
}

class UserRequest {
  static const String _nextBaseUrl = BgmNextApi.baseUrl;

  /// 查询用户信息
  static Future<UserInfoItem> queryUserInfoService(String username) async {
    return await dioRequest
        .get(
          _nextBaseUrl +
              BgmUsersApi.userInfo.replaceFirst('{username}', username),
          options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
          ),
        )
        .then((value) => (UserInfoItem.fromJson(value.data)));
  }

  ///用户条目收藏
  static Future<CollectionsItem> queryUserCollectionsService(
      {required int type, required int limit, required int offset}) async {
    return await bgmDioRequest
        .get(
          _nextBaseUrl + BgmUsersApi.collections,
          queryParameters: {
            'type': type,
            'limit': limit,
            'offset': offset,
          },
          options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
          ),
        )
        .then((value) => (CollectionsItem.fromJson(value.data)));
  }

  ///更新用户条目
  static Future<void> updateCollectionService(int subjectId,
      {int? type,
      bool? private,
      bool? progress,
      int? rate,
      String? comment,
      List<String>? tags}) async {
    final data = <String, dynamic>{};
    if (type != null) data['type'] = type;
    if (rate != null) data['rate'] = rate;
    if (private != null) data['private'] = private;
    if (progress != null) data['progress'] = progress;
    if (comment != null) data['comment'] = comment;
    if (tags != null) data['tags'] = tags;
    try {
      bgmDioRequest
          .put(
            '$_nextBaseUrl${BgmUsersApi.collections}/$subjectId',
            data: data,
            options: Options(
              headers: {Constants.userAgentName: CommonApi.bangumiUserAgent},
            ),
          )
          .then((value) => (value.data));
    } catch (e) {
      Logger().e(e);
      rethrow;
    }
  }
}
