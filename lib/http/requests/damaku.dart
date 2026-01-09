import 'dart:convert';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:crypto/crypto.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class DanmakuRequest {

  static const String _danDanPlayMain = DamakuApi.dandanAPIDomain;

  static Future<DanmakuEpisodeResponse> getgetDanDanEpisodesByDanDanBangumiID(
      int bangumiID) async {
    final path = DamakuApi.dandanAPIInfo + bangumiID.toString();
    final endPoint = _danDanPlayMain + path;
    Map<String, String> withRelated = {
      'withRelated': 'true',
    };
    return dioRequest
        .get(endPoint,
        queryParameters: withRelated,
        options: Options(headers: danDanPlayHeaders(path)))
        .then((response) => DanmakuEpisodeResponse.fromJson(
        response.data as Map<String, dynamic>))
        .catchError((error, stackTrace) {
      Logger().e(error);
      throw error;
    });
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

    var path = DamakuApi.dandanAPIComment + bangumiID.toString() + episode.toString().padLeft(4,'0');
    var endPoint = _danDanPlayMain + path;
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
