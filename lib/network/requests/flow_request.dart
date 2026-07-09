import 'dart:typed_data';
import 'dart:ui';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/crawler/itme/bgm_user_page_item.dart';
import 'package:anime_flow/network/api_path.dart';
import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/bangumi/character_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/character_detail_item.dart';
import 'package:anime_flow/models/item/bangumi/character_subjects_item.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:anime_flow/models/item/bangumi/producers_item.dart';
import 'package:anime_flow/models/item/bangumi/related_subjects_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/models/item/bangumi/user_collections_item.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/models/item/captcha_item.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_search_response.dart';
import 'package:anime_flow/models/item/flow/background_image_item.dart';
import 'package:anime_flow/models/item/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/models/item/flow/bangumi_bind_item.dart';
import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/models/item/flow/flow_users.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/models/search/search_suggestions_item.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:anime_flow/repository/flow_token_storage.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';

class FlowRequest {
  static final FlowClient _client = FlowClient.instance;

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
  static Future<Map<String, dynamic>> getSessionService({
    bool bindMode = false,
  }) async {
    final deviceName = SystemUtil.getDevice().toUpperCase();
    final response = await _client.get(
      AnimeFlowApi.session,
      queryParameters: {
        'platform': deviceName,
        if (bindMode) 'bindMode': 'true',
      },
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

  /// 桌面端绑定模式：轮询 OAuth 授权码
  static Future<String?> pollBindCodeService({required String state}) async {
    const maxDuration = Duration(seconds: 60);
    const pollInterval = Duration(seconds: 2);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final response = await _client.get(
          AnimeFlowApi.oauthBindCode,
          queryParameters: {'sessionId': state},
        );

        if (response.code == 200) {
          final code = response.data;
          if (code is String && code.isNotEmpty) {
            return code;
          }
        }
      } catch (_) {
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

  ///根据id获取条目（已登录时携带 Flow Token，服务端换取 Bangumi token 返回 interest）
  static Future<SubjectsInfoItem> getSubjectByIdService(int id) async {
    final response = await _client.get(
      '${AnimeFlowApi.subjects}/$id',
      options: await _optionalFlowAuthOptions(),
    );
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

  /// 搜索建议
  static Future<SearchSuggestionsItem> searchSuggestionsService(
    String keyword, {
    int limit = 20,
    int type = 2,
  }) async {
    final response = await _client.get(
      AnimeFlowApi.bangumiSearchSuggestions,
      queryParameters: {
        'keyword': keyword,
        'limit': limit,
        'type': type,
      },
    );
    return SearchSuggestionsItem.fromJson(response.data);
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
    return _client
        .get(
          AnimeFlowApi.characters
              .replaceFirst('{subjectId}', subjectId.toString()),
          queryParameters: queryParameters,
        )
        .then((response) => (CharactersItem.fromJson(response.data)));
  }

  ///获取条目制作人
  static Future<ProducersItem> getProducersService(int subjectId,
      {required int limit, required int offset}) async {
    final response = await _client.get(
      AnimeFlowApi.staffs.replaceFirst('{subjectId}', subjectId.toString()),
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return ProducersItem.fromJson(response.data);
  }

  ///获取条目评论
  static Future<SubjectCommentItem> getSubjectCommentsByIdService({
    required int limit,
    required int offset,
    required int subjectId,
  }) async {
    final response = await _client.get(
      AnimeFlowApi.subjectComments
          .replaceFirst('{subjectId}', subjectId.toString()),
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    try {
      return SubjectCommentItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  ///角色信息
  static Future<CharacterDetailItem> characterInfoService(
      int characterId) async {
    final response = await _client.get(AnimeFlowApi.character
        .replaceFirst('{characterId}', characterId.toString()));
    return CharacterDetailItem.fromJson(response.data);
  }

  ///角色出演作品
  static Future<CharacterCastsItem> characterWorksService(int characterId,
      {required int limit, required int offset, int subjectType = 2}) async {
    final response = await _client.get(
        AnimeFlowApi.characterCasts
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
    final response = await _client.get(AnimeFlowApi.characterComments
        .replaceFirst('{characterId}', characterId.toString()));
    final list =
        (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list
        .map((item) =>
            CharacterCommentItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  ///相关条目
  static Future<SubjectRelationItem> relatedSubjectsService(int subjectId,
      {required int limit, required int offset, int? type = 2}) async {
    return _client.get(
      AnimeFlowApi.relations.replaceFirst('{subjectId}', subjectId.toString()),
      queryParameters: {
        'type': type,
        'limit': limit,
        'offset': offset,
      },
    ).then((response) => (SubjectRelationItem.fromJson(response.data)));
  }

  /// 查询用户信息
  static Future<UserInfoItem> queryUserInfoService(String username) async {
    return await _client
        .get(AnimeFlowApi.userInfo.replaceFirst('{username}', username))
        .then((value) => (UserInfoItem.fromJson(value.data)));
  }

  ///获取bgm用户统计数据
  static Future<BgmUserStatisticsItem> getBgmUserStatisticsService(
      String username) async {
    final response = await _client.get(
      AnimeFlowApi.userStatistics.replaceFirst('{username}', username),
      options: Options(
        headers: {Constants.userAgentName: Utils.getRandomUA()},
      ),
    );
    return BgmUserStatisticsItem.fromJson(response.data);
  }

  ///查询用户收藏
  static Future<UserCollectionsItem> queryUserCollectionService(String username,
      {int subjectType = 2,
      required int type,
      required int limit,
      required int offset}) async {
    final response = await _client.get(
      AnimeFlowApi.userCollections.replaceFirst('{username}', username),
      queryParameters: {
        'subjectType': subjectType,
        'type': type,
        'limit': limit,
        'offset': offset,
      },
    );
    try {
      return UserCollectionsItem.fromJson(response.data);
    } catch (e) {
      LiggLogger().e(e);
      throw Exception('Failed to fetch user collections: $e');
    }
  }

  static Future<CaptchaItem> generateCaptchaService({String? captchaId}) async {
    final response = await _client.post(
      AnimeFlowApi.captcha,
      queryParameters: captchaId == null || captchaId.isEmpty
          ? null
          : {'captchaId': captchaId},
    );
    return CaptchaItem.fromJson(Map<String, dynamic>.from(response.data));
  }

  static Future<void> sendEmailCodeService({
    required String email,
    required String captchaId,
    required String captcha,
  }) async {
    await _client.post(
      AnimeFlowApi.sendEmail,
      queryParameters: {
        'email': email,
        'captchaId': captchaId,
        'captcha': captcha,
      },
    );
  }

  static Future<void> registerService({
    required String email,
    required String password,
    required String emailCaptcha,
  }) async {
    await _client.post(
      AnimeFlowApi.register,
      data: {
        'email': email,
        'password': password,
        'emailCaptcha': emailCaptcha,
      },
    );
  }

  /// 登录
  static Future<FlowToken> emailLoginService({
    required String email,
    required String password,
    required String platform,
  }) async {
    final response = await _client.post(AnimeFlowApi.emailLogin, data: {
      'email': email,
      'password': password,
      'platform': platform,
    });
    return FlowToken.fromJson(response.data as Map<String, dynamic>);
  }

  /// 忘记密码：通过邮箱验证码重置登录密码
  static Future<void> forgotPasswordService({
    required String email,
    required String password,
    required String emailCaptcha,
  }) async {
    await _client.post(
      AnimeFlowApi.forgotPassword,
      data: {
        'email': email,
        'password': password,
        'emailCaptcha': emailCaptcha,
      },
    );
  }

  /// 刷新 AnimeFlow token
  static Future<FlowToken> flowRefreshTokenService({
    required String refreshToken,
  }) async {
    final response = await _client.post(
      AnimeFlowApi.flowRefreshToken,
      data: {'refreshToken': refreshToken},
      skipFlowTokenRefresh: true,
    );
    return FlowToken.fromJson(response.data as Map<String, dynamic>);
  }

  /// 登出当前会话，销毁服务端 token（无本地 token 时跳过）
  static Future<void> logoutService() async {
    final token = await FlowTokenStorage.instance.getToken();
    if (token == null) {
      return;
    }
    await _client.post(
      AnimeFlowApi.logout,
      options: await _flowAuthOptions(),
      skipFlowTokenRefresh: true,
    );
  }

  /// 获取当前用户信息
  static Future<FlowUsers> getUserInfoService(
      {required String token, required String tokenType}) async {
    return await _client
        .get(
          AnimeFlowApi.flowUsers,
          options: Options(
            headers: {
              Constants.authorization: '$tokenType $token',
            },
          ),
        )
        .then((value) =>
            FlowUsers.fromJson((value.data) as Map<String, dynamic>));
  }

  /// 获取背景图列表
  static Future<List<BackgroundImageItem>> getBackgroundListService() async {
    final response = await _client.get(
      AnimeFlowApi.backgroundList,
      options: await _optionalFlowAuthOptions(),
    );
    return (response.data as List)
        .map((e) => BackgroundImageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 上传当前登录用户的头像（支持 JPEG / PNG / WebP / GIF，最大 2MB）
  static Future<FlowUsers> uploadAvatarService(
    Uint8List imageBytes, {
    String filename = 'avatar.png',
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: filename),
    });
    final response = await _client.post(
      '${AnimeFlowApi.flowUsers}/avatar',
      data: formData,
      options: await _flowAuthOptions(),
    );
    return FlowUsers.fromJson(response.data as Map<String, dynamic>);
  }

  /// 更新当前用户资料（昵称、背景）
  static Future<FlowUsers> updateUserInfoService({
    String? nickname,
    String? avatar,
    int? backgroundId,
  }) async {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (avatar != null) data['avatar'] = avatar;
    if (backgroundId != null) data['backgroundId'] = backgroundId;

    final response = await _client.put(
      AnimeFlowApi.flowUsers,
      data: data,
      options: await _flowAuthOptions(),
    );
    return FlowUsers.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<Options> _flowAuthOptions() async {
    final token = await FlowTokenStorage.instance.getToken();
    if (token == null) {
      throw StateError('未登录');
    }
    return Options(
      headers: {
        Constants.authorization: '${token.tokenType} ${token.accessToken}',
      },
    );
  }

  /// 已登录时附带 Flow Token；未登录返回 {@code null}（公开接口可选鉴权）。
  static Future<Options?> _optionalFlowAuthOptions() async {
    final token = await FlowTokenStorage.instance.getToken();
    if (token == null) {
      return null;
    }
    return Options(
      headers: {
        Constants.authorization: '${token.tokenType} ${token.accessToken}',
      },
    );
  }

  /// 查询当前账号的 Bangumi 绑定状态
  static Future<BangumiBindItem> getBangumiBindService() async {
    final response = await _client.get(
      AnimeFlowApi.bangumiBind,
      options: await _flowAuthOptions(),
    );
    return BangumiBindItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// Bangumi 第三方授权登录
  static Future<FlowToken> bangumiLoginService({
    required String code,
    required String platform,
  }) async {
    final response = await _client.post(
      AnimeFlowApi.bangumiLogin,
      data: {
        'code': code,
        'platform': platform,
      },
    );
    return FlowToken.fromJson(response.data as Map<String, dynamic>);
  }

  /// 绑定 Bangumi 账号
  static Future<BangumiBindItem> bindBangumiService({
    required String code,
  }) async {
    final response = await _client.post(
      AnimeFlowApi.bangumiBindPost,
      data: {'code': code},
      options: await _flowAuthOptions(),
    );
    return BangumiBindItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// 解绑当前账号绑定的 Bangumi 账号
  static Future<BangumiBindItem> unbindBangumiService() async {
    final response = await _client.post(
      AnimeFlowApi.bangumiUnbind,
      options: await _flowAuthOptions(),
    );
    return BangumiBindItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// 提交 Bangumi 收藏同步任务
  static Future<BgmCollectionSyncStatusItem> triggerBgmCollectionSyncService({
    int subjectType = 2,
  }) async {
    final response = await _client.post(
      AnimeFlowApi.bangumiCollectionSync,
      queryParameters: {'subjectType': subjectType},
      options: await _flowAuthOptions(),
    );
    return BgmCollectionSyncStatusItem.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// 查询 Bangumi 收藏同步状态
  static Future<BgmCollectionSyncStatusItem>
      getBgmCollectionSyncStatusService() async {
    final response = await _client.get(
      AnimeFlowApi.bangumiCollectionSync,
      options: await _flowAuthOptions(),
    );
    return BgmCollectionSyncStatusItem.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// 绑定邮箱并设置登录密码
  static Future<FlowUsers> bindEmailService({
    required String email,
    required String password,
    required String emailCaptcha,
  }) async {
    final response = await _client.post(
      AnimeFlowApi.bindEmail,
      data: {
        'email': email,
        'password': password,
        'emailCaptcha': emailCaptcha,
      },
      options: await _flowAuthOptions(),
    );
    return FlowUsers.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取当前用户 Bangumi 收藏列表
  static Future<UserCollectionsItem> myCollectionsService({
    int subjectType = 2,
    required int type,
    required int limit,
    required int offset,
  }) async {
    final response = await _client.get(
      AnimeFlowApi.flowUserCollections,
      queryParameters: {
        'subjectType': subjectType,
        'type': type,
        'limit': limit,
        'offset': offset,
      },
      options: await _flowAuthOptions(),
    );
    try {
      return UserCollectionsItem.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      LiggLogger().e(e);
      throw Exception('Failed to fetch user collections: $e');
    }
  }

  /// 更新当前用户对条目的 Bangumi 收藏（需登录且已绑定 Bangumi）
  static Future<void> updateCollectionService(
    int subjectId, {
    int? type,
    bool? isPrivate,
    bool? progress,
    int? rate,
    String? comment,
    List<String>? tags,
    int? subjectType,
  }) async {
    final data = <String, dynamic>{};
    if (type != null) data['type'] = type;
    if (rate != null) data['rate'] = rate;
    if (isPrivate != null) data['private'] = isPrivate;
    if (progress != null) data['progress'] = progress;
    if (comment != null) data['comment'] = comment;
    if (tags != null) data['tags'] = tags;
    if (subjectType != null) data['subjectType'] = subjectType;

    await _client.put(
      '${AnimeFlowApi.flowUserCollections}/$subjectId',
      data: data,
      options: await _flowAuthOptions(),
    );
  }
}
