import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';

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

  Danmaku({required this.message, required this.time, required this.type, required this.color, required this.source});

  factory Danmaku.fromJson(Map<String, dynamic> json) {
    String messageValue = json['m'];
    List<String> parts = json['p'].split(',');
    double timeValue = double.parse(parts[0]);
    int typeValue = int.parse(parts[1]);
    Color color = Utils.generateDanmakuColor(int.parse(parts[2]));
    String sourceValue = parts[3];
    return Danmaku(time: timeValue, message: messageValue, type: typeValue, color: color, source: sourceValue);
  }

  @override
  String toString() {
    return 'Danmaku{message: $message, time: $time, type: $type, color: $color, source: $source}';
  }
}