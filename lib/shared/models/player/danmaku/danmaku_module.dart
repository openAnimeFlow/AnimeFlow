import 'package:anime_flow/core/utils/utils.dart';
import 'package:flutter/material.dart';

class Danmaku {
  // 弹幕内容
  String message;

  // 原始文本，切换简繁转换模式时作为转换输入
  final String originalMessage;

  // 弹幕时间
  double time;

  // 弹幕类型 (1-普通弹幕，4-底部弹幕，5-顶部弹幕)
  int type;

  // 弹幕颜色
  Color color;

  // 弹幕来源 ([BiliBili], [Gamer])
  String source;

  int? bgmUserId;

  Danmaku(
      {required String message,
      required this.time,
      required this.type,
      required this.color,
      this.bgmUserId,
      required this.source,
      String? originalMessage})
      : message = message,
        originalMessage = originalMessage ?? message;

  factory Danmaku.fromJson(Map<String, dynamic> json) {
    String messageValue = json['m'];
    List<String> parts = json['p'].split(',');
    double timeValue = double.parse(parts[0]);
    int typeValue = int.parse(parts[1]);
    Color color = Utils.generateDanmakuColor(int.parse(parts[2]));
    String sourceValue = parts[3];
    final int? bgmUserIdValue =
        parts.length > 4 ? int.tryParse(parts[4]) : null;
    return Danmaku(
        time: timeValue,
        message: messageValue,
        originalMessage: messageValue,
        type: typeValue,
        color: color,
        source: sourceValue,
        bgmUserId: bgmUserIdValue);
  }

  Danmaku copyWith({String? message}) {
    return Danmaku(
      message: message ?? this.message,
      originalMessage: originalMessage,
      time: time,
      type: type,
      color: color,
      bgmUserId: bgmUserId,
      source: source,
    );
  }

  @override
  String toString() {
    return 'Danmaku{message: $message, time: $time, type: $type, color: $color, source: $source, bgmUserId: $bgmUserId}';
  }
}
