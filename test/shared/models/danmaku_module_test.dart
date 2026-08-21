import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Danmaku', () {
    test('keeps originalMessage after copyWith conversion', () {
      final danmaku = Danmaku(
        message: '鼠标',
        time: 1.5,
        type: 1,
        color: Colors.white,
        source: 'BiliBili',
      );

      final converted = danmaku.copyWith(message: '鼠標');

      expect(converted.message, '鼠標');
      expect(converted.originalMessage, '鼠标');
      expect(danmaku.message, '鼠标');
      expect(danmaku.originalMessage, '鼠标');
    });

    test('fromJson stores raw message as originalMessage', () {
      final danmaku = Danmaku.fromJson({
        'm': '开放中文转换',
        'p': '1.5,1,16777215,BiliBili',
      });

      expect(danmaku.message, '开放中文转换');
      expect(danmaku.originalMessage, '开放中文转换');
    });
  });
}
