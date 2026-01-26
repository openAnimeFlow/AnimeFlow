import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/models/item/bangumi/actor_ite.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/bangumi/character_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/character_detail_item.dart';
import 'package:anime_flow/models/item/bangumi/character_subjects_item.dart';
import 'package:anime_flow/models/item/bangumi/collections_item.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:anime_flow/models/item/bangumi/related_subjects_item.dart';
import 'package:anime_flow/models/item/bangumi/staff_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/http/dio/bgm_dio_request.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/item/bangumi/timeline_item.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class BgmRequest {
  static const String _nextBaseUrl = BgmNextApi.baseUrl;
  static final Logger _logger = Logger();

  static String _getBangumiUserAgent() {
    final appInfoController = Get.find<AppInfoController>();
    return CommonApi.bangumiUserAgent
        .replaceAll('{version}', appInfoController.version);
  }

  /// 获取热门
  static Future<HotItem> getHotService(int limit, int offset) async {
    final response = await dioRequest.get(_nextBaseUrl + BgmNextApi.hot,
        queryParameters: {'type': 2, 'limit': limit, 'offset': offset},
        options:
            Options(headers: {Constants.userAgentName: _getBangumiUserAgent}));
    return HotItem.fromJson(response.data);
  }

  ///根据id获取条目
  static Future<SubjectsInfoItem> getSubjectByIdService(int id) async {
    final response = await bgmDioRequest.get(
        '$_nextBaseUrl${BgmNextApi.subjects}/$id',
        options:
            Options(headers: {Constants.userAgentName: _getBangumiUserAgent}));
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
              headers: {Constants.userAgentName: _getBangumiUserAgent}));
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
        headers: {Constants.userAgentName: _getBangumiUserAgent},
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
      required int offset,
      String? rank,
      List<String>? tags}) async {
    final data = <String, dynamic>{
      'keyword': keyword,
    };

    final filter = <String, dynamic>{
      'type': [2],
    };

    if (tags != null) filter['tags'] = tags;

    data['filter'] = filter;

    if (rank != null) data['rank'] = rank;

    final response = await dioRequest.post(
      _nextBaseUrl + BgmNextApi.search,
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      data: data,
      options: Options(
        headers: {Constants.userAgentName: _getBangumiUserAgent},
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
            headers: {Constants.userAgentName: _getBangumiUserAgent},
          ),
        )
        .then((value) => Calendar.fromJson(value.data))
        .catchError((error) {
      _logger.e(error);
      throw Exception('Failed to fetch calendar: $error');
    });
  }

  ///剧集评论
  static Future<List<EpisodeComment>> episodeCommentsService({
    required int episodeId,
  }) async {
    final response = await dioRequest.get(_nextBaseUrl +
        BgmNextApi.episodeComments
            .replaceFirst('{episodeId}', episodeId.toString()));
    return (response.data as List<dynamic>)
        .map((item) => EpisodeComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  ///角色列表
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
            headers: {Constants.userAgentName: _getBangumiUserAgent},
          ),
        )
        .then((response) => (CharactersItem.fromJson(response.data)));
  }

  ///角色信息
  static Future<CharacterDetailItem> characterInfoService(
      int characterId) async {
    final response = await dioRequest.get(_nextBaseUrl +
        BgmNextApi.character
            .replaceFirst('{characterId}', characterId.toString()));
    return CharacterDetailItem.fromJson(response.data);
  }

  ///角色出演作品
  static Future<CharacterCastsItem> characterWorksService(int characterId,
      {required int limit, required int offset, int subjectType = 2}) async {
    final response = await dioRequest.get(
        _nextBaseUrl +
            BgmNextApi.characterCasts
                .replaceFirst('{characterId}', characterId.toString()),
        queryParameters: {
          'subjectType': subjectType,
          'limit': limit,
          'offset': offset,
        });
    return CharacterCastsItem.fromJson(response.data);
  }

  ///角色吐槽
  static Future<List<CharacterCommentItem>> characterCommentsService(
      int characterId) async {
    final response = await dioRequest.get(_nextBaseUrl +
        BgmNextApi.characterComments
            .replaceFirst('{characterId}', characterId.toString()));
    return (response.data as List<dynamic>)
        .map((item) =>
            CharacterCommentItem.fromJson(item as Map<String, dynamic>))
        .toList();
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
            headers: {Constants.userAgentName: _getBangumiUserAgent},
          ),
        )
        .then((response) => (SubjectItem.fromJson(response.data)));
  }

  ///时间线
  static Future<List<TimelineItem>> timelineService(
    int limit, {
    String? mode,
    int? until,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (mode != null) queryParameters['mode'] = mode;
    if (until != null) queryParameters['until'] = until;
    try {
      final response = await dioRequest.get(
        _nextBaseUrl + BgmNextApi.timeline,
        queryParameters: queryParameters,
        options: Options(
          headers: {Constants.userAgentName: _getBangumiUserAgent},
        ),
      );
      final data = response.data;
      if (data == null) {
        return [];
      }
      final List<dynamic> items = data is List ? data : [];
      final List<TimelineItem> result = [];
      for (final item in items) {
        try {
          final itemMap = item as Map<String, dynamic>;
          result.add(TimelineItem.fromJson(itemMap));
        } catch (e) {
          _logger.w('Failed to parse timeline item: $e');
          // 继续处理其他条目，不抛出异常
        }
      }
      return result;
    } catch (e) {
      _logger.e(e);
      throw Exception('Failed to fetch timeline: $e');
    }
  }

  ///获取条目制作人
  static Future<StaffItem> getProducersService(int subjectId,
      {required int limit, required int offset}) async {
    final response = await dioRequest.get(
      _nextBaseUrl +
          BgmNextApi.staffs.replaceFirst('{subjectId}', subjectId.toString()),
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      options: Options(
        headers: {Constants.userAgentName: _getBangumiUserAgent},
      ),
    );
    return StaffItem.fromJson(response.data);
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
            headers: {
              Constants.userAgentName: BgmRequest._getBangumiUserAgent()
            },
          ),
        )
        .then((value) => (UserInfoItem.fromJson(value.data)));
  }

  ///用户条目收藏
  static Future<CollectionsItem> queryUserCollectionsService(
      {required int type, required int limit, required int offset}) async {
    final response = await bgmDioRequest.get(
      _nextBaseUrl + BgmUsersApi.collections,
      queryParameters: {
        'type': type,
        'limit': limit,
        'offset': offset,
      },
      options: Options(
        headers: {Constants.userAgentName: BgmRequest._getBangumiUserAgent()},
      ),
    );
    try {
      return CollectionsItem.fromJson(response.data);
    } catch (e) {
      Logger().e(e);
      throw Exception('Failed to fetch user collections: $e');
    }
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
              headers: {
                Constants.userAgentName: BgmRequest._getBangumiUserAgent()
              },
            ),
          )
          .then((value) => (value.data));
    } catch (e) {
      Logger().e(e);
      rethrow;
    }
  }

  ///更新章节进度
  static Future<void> updateEpisodeProgressService(int episodeId,
      {required bool batch, required int type}) async {
    bgmDioRequest.put(
      '$_nextBaseUrl${BgmUsersApi.collectionsEpisodes}/$episodeId',
      data: {
        'type': type,
        'batch': batch,
      },
    );
  }
}
