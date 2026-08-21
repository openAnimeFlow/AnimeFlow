import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DanmakuChineseConverter', () {
    final converter = DanmakuChineseConverter();

    tearDown(converter.dispose);

    test('restores original messages when mode is none', () async {
      final danmakus = [
        _danmaku('开放中文转换'),
        _danmaku('鼠标与软件'),
      ];

      final result = await converter.convertDanmakus(
        danmakus,
        DanmakuChineseMode.none,
      );

      expect(result, isNot(same(danmakus)));
      expect(result[0], isNot(same(danmakus[0])));
      expect(result[0].message, '开放中文转换');
      expect(result[0].originalMessage, '开放中文转换');
    });

    test('returns empty list without loading native resources', () async {
      final result = await converter.convertDanmakus(
        const [],
        DanmakuChineseMode.s2t,
      );

      expect(result, isEmpty);
    });
  });
}

Danmaku _danmaku(String message) {
  return Danmaku(
    message: message,
    time: 1.0,
    type: 1,
    color: Colors.white,
    source: 'BiliBili',
  );
}
