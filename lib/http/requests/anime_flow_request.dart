import 'dart:ui';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/clients/anime_flow_client.dart';
import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_search_response.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';

class AnimeFlowRequest {
  static final AnimeFlowClient _client = AnimeFlowClient.instance;

  static Future<TokenItem> getTokenService({required String code}) async {
    final response = await _client.post(
      AnimeFlowApi.token,
      queryParameters: {'code': code},
    );
    return TokenItem.fromJson(response.data);
  }

  ///刷新token
  static Future<TokenItem> refreshTokenService({
    required String refreshToken,
  }) async {
    final response = await _client.post(
      AnimeFlowApi.refreshToken,
      queryParameters: {'refreshToken': refreshToken},
    );
    return TokenItem.fromJson(response.data);
  }

  //回调api
  static Future<Map<String, dynamic>> callbackService(
    String code,
    String state,
  ) async {
    final response = await _client.get(
      AnimeFlowApi.callback,
      queryParameters: {'code': code, 'state': state},
      signRequest: false,
    );
    return response.data;
  }

  //获取session
  static Future<Map<String, dynamic>> getSessionService() async {
    final deviceName = SystemUtil.getDevice().toUpperCase();
    final response = await _client.get(
      AnimeFlowApi.session,
      queryParameters: {'platform': deviceName},
    );
    return response.data;
  }

  // 持续轮询直到获取到 token 或超时（60秒，与 session 过期时间一致）
  static Future<TokenItem?> pollTokenService({required String state}) async {
    const maxDuration = Duration(seconds: 60);
    const pollInterval = Duration(seconds: 2);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final response = await _client.get(
          AnimeFlowApi.token,
          queryParameters: {'sessionId': state},
        );

        if (response.code == 200 && response.data.isNotEmpty) {
          return TokenItem.fromJson(response.data);
        }
      } catch (e) {
        // 忽略错误，继续轮询
      }

      await Future.delayed(pollInterval);
    }

    return null;
  }

  /// 获取弹幕
  static Future<List<Danmaku>> getDanDanmaku(int bangumiID, int episode) async {
    List<Danmaku> danmakus = [];
    if (bangumiID == 0) {
      return danmakus;
    }
    // 这里猜测了弹弹Play的分集命名规则，例如上面的番剧ID为1758，第一集弹幕库ID大概率为17580001，
    // 但是此命名规则并没有体现在官方API文档里，保险的做法是请求 Api.dandanInfo（kazumi）
    final episodeID =
        int.parse('$bangumiID${episode.toString().padLeft(4, '0')}');
    return getDanDanmakuByEpisodeID(episodeID);
  }

  /// 通过episodeID获取弹幕
  static Future<List<Danmaku>> getDanDanmakuByEpisodeID(int episodeID) async {
    final path = '${AnimeFlowApi.danmaku}/$episodeID';
    final danmakus = <Danmaku>[];
    final response = await _client.get(
      path,
      queryParameters: {'withRelated': 'true'},
    );
    final comments = response.data['comments'];
    if (comments is! List) {
      return danmakus;
    }
    for (final comment in comments) {
      danmakus.add(Danmaku.fromJson(comment));
    }
    return danmakus;
  }

  /// 搜索番剧元素
  static Future<DanmakuSearchResponse> searchResponse(
    String title, {
    int type = 1,
  }) async {
    final response = await _client.get(
      AnimeFlowApi.dandanPlaySearch,
      queryParameters: {'keyword': title, 'type': type},
    );
    return DanmakuSearchResponse.fromJson(response.data);
  }

  static Future<int?> getDanDanBangumiIDByBgmBangumiID(int bgmBangumiID) async {
    final path = '${AnimeFlowApi.animeDetailByBgmId}/$bgmBangumiID';
    final response = await _client.get(path);
    try {
      return DanmakuEpisodeResponse.fromJson(response.data).bangumiId;
    } catch (e) {
      LiggLogger().e('获取番剧ID 为空：$e');
      return null;
    }
  }

  /// 通过番剧ID获取番剧元素
  static Future<DanmakuEpisodeResponse> getDanDanEpisodesByDanDanBangumiID(
    int bangumiID,
  ) async {
    final path = '${AnimeFlowApi.animeDetail}/$bangumiID';
    final response = await _client.get(path);
    return DanmakuEpisodeResponse.fromJson(response.data);
  }

  /// 发送弹幕
  static Future<AnimeFlowResponse> sendDanmaku(
    int bangumiID,
    int episode, {
    required String message,
    required double time,
    required int type,
    required Color color,
  }) async {
    final token = await BangumiToken.instance.getToken();
    final episodeID =
        int.parse('$bangumiID${episode.toString().padLeft(4, '0')}');
    final colorValue = Utils.colorToDecimalRgb(color);
    return _client.post(
      AnimeFlowApi.danmaku,
      data: {
        'episodeId': episodeID,
        'comment': message,
        'time': time,
        'type': type,
        'color': colorValue,
      },
      options: Options(
        headers: {
          Constants.authorization: '${token!.tokenType} ${token.accessToken}',
        },
      ),
    );
  }

  ///每日放送
  static Future<Calendar> calendarService() async {
    return await _client
        .get(AnimeFlowApi.calendar)
        .then((value) => Calendar.fromJson(value.data));
  }

  /// 获取热门
  static Future<HotItem> getHotService(int limit, int offset) async {
    return await _client.get(AnimeFlowApi.hot, queryParameters: {
      'type': 2,
      'limit': limit,
      'offset': offset
    }).then((value) => HotItem.fromJson(value.data));
  }

  ///根据id获取条目
  static Future<SubjectsInfoItem> getSubjectByIdService(int id) async {
    final response = await _client.get('${AnimeFlowApi.subjects}/$id');
    return SubjectsInfoItem.fromJson(response.data);
  }

  ///获取条目章节
  static Future<EpisodesItem> getSubjectEpisodesByIdService(
      int id, int limit, int offset) async {
    try {
      return await _client.get(
          AnimeFlowApi.episodes.replaceFirst('{subjectId}', id.toString()),
          queryParameters: {
            'limit': limit,
            'offset': offset
          }).then((value) => EpisodesItem.fromJson(value.data));
    } catch (e) {
      throw Exception('Failed to fetch episodes: $e');
    }
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
    final queryParameters = <String, dynamic>{
      'type': type,
      'sort': sort.value,
      'page': page,
    };
    if (cat != null) queryParameters['cat'] = cat;
    if (year != null) queryParameters['year'] = year;
    if (month != null) queryParameters['month'] = month;
    if (tags != null) queryParameters['tags'] = tags;

    return _client
        .get(
          AnimeFlowApi.subjects,
          queryParameters: queryParameters,
        )
        .then((response) => (SubjectItem.fromJson(response.data)));
  }

  ///剧集评论
  static Future<List<EpisodeComment>> episodeCommentsService({
    required int episodeId,
  }) async {
    final response = await _client.get(AnimeFlowApi.episodeComments
        .replaceFirst('{episodeId}', episodeId.toString()));
    return (response.data as List)
        .map((item) => EpisodeComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  ///条目搜索
  static Future<SubjectItem> searchSubjectService(String keyword,
      {required int limit,
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

    final response = await _client.post(
      AnimeFlowApi.bangumiSearch,
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      data: data,
    );

    return SubjectItem.fromJson(response.data);
  }
}
