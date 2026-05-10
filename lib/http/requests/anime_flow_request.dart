import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/clients/anime_flow_client.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_search_response.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/utils/systemUtil.dart';

/// animeFlow统一的响应类
class AnimeFlowResponse {
  final int code;
  final String message;
  final Map<String, dynamic> data;

  AnimeFlowResponse({required this.code, required this.message, required this.data});

  factory AnimeFlowResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return AnimeFlowResponse(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      data: dataRaw is Map
          ? Map<String, dynamic>.from(dataRaw)
          : <String, dynamic>{},
    );
  }
}

class AnimeFlowRequest {
  static final AnimeFlowClient _client = AnimeFlowClient.instance;

  static const String _animeFlowApi = AnimeFlowApi.animeFlowDevApi;

  static Future<TokenItem> getTokenService({required String code}) async {
    final response = await _client.post(
        _animeFlowApi + AnimeFlowApi.token,
        queryParameters: {'code': code});
    return TokenItem.fromJson(response['data']);
  }

  ///刷新token
  static Future<TokenItem> refreshTokenService({required String refreshToken}) async {
    final response = await _client.post(
        '$_animeFlowApi${AnimeFlowApi.refreshToken}',
        queryParameters: {'refreshToken': refreshToken});
    return TokenItem.fromJson(response['data']);
  }

  //回调api
  static Future<Map<String, dynamic>> callbackService(
      String code, String state) async {
    return await _client.get(_animeFlowApi + AnimeFlowApi.callback,
        queryParameters: {
          'code': code,
          'state': state
        }).then((value) => value);
  }

  //获取session
  static Future<Map<String, dynamic>> getSessionService() async {
    String deviceName = SystemUtil.getDevice().toUpperCase();
    return await _client.get(_animeFlowApi + AnimeFlowApi.session,
        queryParameters: {'platform': deviceName}).then((value) => value);
  }

  // 持续轮询直到获取到 token 或超时（60秒，与 session 过期时间一致）
  static Future<TokenItem?> pollTokenService({required String state}) async {
    const maxDuration = Duration(seconds: 60); // session 过期时间
    const pollInterval = Duration(seconds: 2); // 每2秒轮询一次
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final response = await _client.get(
          _animeFlowApi + AnimeFlowApi.token,
          queryParameters: {'sessionId': state},
        );

        if (response['code'] == 200 && response['data'] != null) {
          return TokenItem.fromJson(response['data']);
        }
      } catch (e) {
        // 忽略错误，继续轮询
      }

      await Future.delayed(pollInterval);
    }

    return null; // 超时未获取到 token
  }

  // 获取弹幕
  static Future<List<Danmaku>> getDanDanmaku(int bangumiID, int episode) async {
    List<Danmaku> danmakus = [];
    if (bangumiID == 0) {
      return danmakus;
    }
    // 这里猜测了弹弹Play的分集命名规则，例如上面的番剧ID为1758，第一集弹幕库ID大概率为17580001，
    // 但是此命名规则并没有体现在官方API文档里，保险的做法是请求 Api.dandanInfo（kazumi）
    final episodeID = int.parse('$bangumiID${episode.toString().padLeft(4, '0')}');
    return getDanDanmakuByEpisodeID(episodeID);
  }

  /// 通过episodeID获取弹幕
  static Future<List<Danmaku>> getDanDanmakuByEpisodeID(int episodeID) async {
    var path = '$_animeFlowApi${AnimeFlowApi.danmaku}/$episodeID';
    List<Danmaku> danmakus = [];
    Map<String, String> withRelated = {
      'withRelated': 'true',
    };
    final raw = await _client.get(path, queryParameters: withRelated);
    if (raw is! Map) {
      return danmakus;
    }
    final response = AnimeFlowResponse.fromJson(Map<String, dynamic>.from(raw));
    final comments = response.data['comments'];
    if (comments is! List) {
      return danmakus;
    }
    for (var comment in comments) {
      Danmaku danmaku = Danmaku.fromJson(comment);
      danmakus.add(danmaku);
    }
    return danmakus;
  }

  /// 搜索番剧元素
  static Future<DanmakuSearchResponse> searchResponse(
      String title,{int type = 1}) async {
    const api = _animeFlowApi + AnimeFlowApi.search;

    final res = await _client.get(api,
        queryParameters: {
          'keyword': title,
          'type': type
        });
    final response = AnimeFlowResponse.fromJson(Map<String, dynamic>.from(res));
    return DanmakuSearchResponse.fromJson(response.data);
  }

  /// 通过番剧ID获取番剧元素
  static Future<DanmakuEpisodeResponse> getDanDanEpisodesByDanDanBangumiID(
      int bangumiID) async {
    var path = '$_animeFlowApi${AnimeFlowApi.animeDetail}/$bangumiID';
    final res = await _client.get(path);
    final response = AnimeFlowResponse.fromJson(Map<String, dynamic>.from(res));
    return DanmakuEpisodeResponse.fromJson(response.data);
  }
}