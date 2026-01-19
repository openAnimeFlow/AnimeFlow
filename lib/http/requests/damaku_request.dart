import 'dart:convert';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_search_response.dart';
import 'package:crypto/crypto.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DanmakuRequest {
  static const String _danDanPlayMain = DamakuApi.dandanAPIDomain;

  static Future<DanmakuEpisodeResponse> getDanDanEpisodesByDanDanBangumiID(
      int bangumiID) async {
    var path = DamakuApi.dandanAPIInfo + bangumiID.toString();
    var endPoint = _danDanPlayMain + path;
    final res = await dioRequest.get(endPoint,
        options: Options(headers: danDanPlayHeaders(path)));
    Map<String, dynamic> jsonData = res.data;
    DanmakuEpisodeResponse danmakuEpisodeResponse =
        DanmakuEpisodeResponse.fromJson(jsonData);
    return danmakuEpisodeResponse;
  }

  static Future<DanmakuSearchResponse> getDanmakuSearchResponse(
      String title) async {
    var path = DamakuApi.dandanAPISearch;
    var endPoint = _danDanPlayMain + path;
    Map<String, String> keywordMap = {
      'keyword': title,
    };

    final res = await dioRequest.get(endPoint,
        options: Options(headers: danDanPlayHeaders(path)),
        queryParameters: keywordMap);
    Map<String, dynamic> jsonData = res.data;
    DanmakuSearchResponse danmakuSearchResponse =
        DanmakuSearchResponse.fromJson(jsonData);
    return danmakuSearchResponse;
  }

  static Future<int> getDanDanBangumiIDByBgmBangumiID(int bgmBangumiID) async {
    var path = DamakuApi.dandanAPIInfoByBgmBangumiId
        .replaceFirst('{bgmtvSubjectId}', bgmBangumiID.toString());
    var endPoint = _danDanPlayMain + path;
    final response = await dioRequest.get(endPoint,
        options: Options(headers: danDanPlayHeaders(path)));

    Map<String, dynamic> jsonData = response.data;
    return DanmakuEpisodeResponse.fromJson(jsonData).bangumiId;
  }

  static Future<List<Danmaku>> getDanDanmaku(int bangumiID, int episode) async {
    List<Danmaku> danmakus = [];
    if (bangumiID == 0) {
      return danmakus;
    }
    // 这里猜测了弹弹Play的分集命名规则，例如上面的番剧ID为1758，第一集弹幕库ID大概率为17580001，但是此命名规则并没有体现在官方API文档里，保险的做法是请求 Api.dandanInfo（kazumi）
    final path = DamakuApi.dandanAPIComment +
        bangumiID.toString() +
        episode.toString().padLeft(4, '0');
    final endPoint = _danDanPlayMain + path;
    Map<String, String> withRelated = {
      'withRelated': 'true',
    };
    final response = await dioRequest.get(endPoint,
        queryParameters: withRelated,
        options: Options(headers: danDanPlayHeaders(path)));
    Map<String, dynamic> jsonData = response.data;
    List<dynamic> comments = jsonData['comments'];
    for (var comment in comments) {
      Danmaku danmaku = Danmaku.fromJson(comment);
      danmakus.add(danmaku);
    }
    return danmakus;
  }

  // 通过episodeID获取弹幕
  static Future<List<Danmaku>> getDanDanmakuByEpisodeID(int episodeID) async {
    var path = DamakuApi.dandanAPIComment + episodeID.toString();
    var endPoint = _danDanPlayMain + path;
    List<Danmaku> danmakus = [];
    Map<String, String> withRelated = {
      'withRelated': 'true',
    };
    final res = await dioRequest.get(endPoint,
        queryParameters: withRelated,
        options: Options(headers: danDanPlayHeaders(path)));
    Map<String, dynamic> jsonData = res.data;
    List<dynamic> comments = jsonData['comments'];

    for (var comment in comments) {
      Danmaku danmaku = Danmaku.fromJson(comment);
      danmakus.add(danmaku);
    }
    return danmakus;
  }

  static Map<String, dynamic> danDanPlayHeaders(String path) {
    var timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      'user-agent': Utils.getRandomUA(),
      'referer': '',
      'X-Auth': 1,
      'X-AppId': dotenv.env['DANDANPLAY_ID']!,
      'X-Timestamp': timestamp,
      'X-Signature': generateDandanSignature(path, timestamp)
    };
  }

  static String generateDandanSignature(String path, int timestamp) {
    final id = dotenv.env['DANDANPLAY_ID']!;
    final value = dotenv.env['DANDANPLAY_SECRET']!;
    String data = id + timestamp.toString() + path + value;
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }
}
