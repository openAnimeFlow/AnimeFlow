import 'dart:convert';
import 'dart:ui';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/http/requests/damaku.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class Damaku {
  static const String dandanAPIDomain = 'https://api.dandanplay.net';
  static const String dandanAPIComment = "/api/v2/comment/";

  static String generateDandanSignature(String path, int timestamp) {
    final id = dotenv.env['DANDANPLAY_ID']!;
    final value = dotenv.env['DANDANPLAY_SECRET']!;
    String data = id + timestamp.toString() + path + value;
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  static Future<List<Danmaku>> getDanDanmakuByEpisodeID(int episodeID) async {
    var path = Damaku.dandanAPIComment + episodeID.toString();
    var endPoint = Damaku.dandanAPIDomain + path;
    List<Danmaku> danmakus = [];
    Map<String, String> withRelated = {
      'withRelated': 'true',
    };
    var timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final res = await dioRequest.get(endPoint,
        queryParameters: withRelated,
        options: Options(headers: {
          'user-agent': Utils.getRandomUA(),
          'referer': '',
          'X-Auth': 1,
          'X-AppId': dotenv.env['DANDANPLAY_ID']!,
          'X-Timestamp': timestamp,
          'X-Signature':
              Damaku.generateDandanSignature(Uri.parse(path).path, timestamp),
        }));
    Map<String, dynamic> jsonData = res.data;
    List<dynamic> comments = jsonData['comments'];

    for (var comment in comments) {
      Danmaku danmaku = Danmaku.fromJson(comment);
      danmakus.add(danmaku);
    }
    return danmakus;
  }
}

const Map<String, String> mortis = {
  'id': 'kvpx7qkqjh',
  'value': 'rABUaBLqdz7aCSi3fe88ZDj2gwga9Vax',
};

class Danmaku {
  // 弹幕内容
  String message;

  // 弹幕时间
  double time;

  // 弹幕类型 (1-普通弹幕，4-底部弹幕，5-顶部弹幕)
  int type;

  // 弹幕颜色
  Color color;

  // 弹幕来源 ([BiliBili], [Gamer])
  String source;

  Danmaku(
      {required this.message,
      required this.time,
      required this.type,
      required this.color,
      required this.source});

  factory Danmaku.fromJson(Map<String, dynamic> json) {
    String messageValue = json['m'];
    List<String> parts = json['p'].split(',');
    double timeValue = double.parse(parts[0]);
    int typeValue = int.parse(parts[1]);
    Color color = Utils.generateDanmakuColor(int.parse(parts[2]));
    String sourceValue = parts[3];
    return Danmaku(
        time: timeValue,
        message: messageValue,
        type: typeValue,
        color: color,
        source: sourceValue);
  }

  @override
  String toString() {
    return 'Danmaku{message: $message, time: $time, type: $type, color: $color, source: $source}';
  }
}

void main() {
  test('Get danmaku by episode ID test', () async {
    await dotenv.load(fileName: ".env");
    final BangumiID = await  DanmakuRequest.getDanDanBangumiIDByBgmBangumiID(565802);
    final danmakus = await DanmakuRequest.getDanDanmaku(BangumiID, 1);
    print('弹幕内容：$danmakus');
    print('获取到 ${danmakus.length} 条弹幕');
  });
}
