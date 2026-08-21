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

    test('converts messages in input order', () async {
      final testConverter = DanmakuChineseConverter(
        batchConverter: (mode, messages) async => [
          for (final message in messages) '${mode.name}:$message',
        ],
      );
      addTearDown(testConverter.dispose);

      final danmakus = [
        _danmaku('开放中文转换'),
        _danmaku('鼠标'),
        _danmaku('软件'),
      ];

      final result = await testConverter.convertDanmakus(
        danmakus,
        DanmakuChineseMode.s2t,
      );

      expect(
        [for (final danmaku in result) danmaku.message],
        ['s2t:开放中文转换', 's2t:鼠标', 's2t:软件'],
      );
      expect(result[0].originalMessage, '开放中文转换');
      expect(result[0], isNot(same(danmakus[0])));
    });

    test('falls back to original text when batch conversion throws', () async {
      final testConverter = DanmakuChineseConverter(
        batchConverter: (mode, messages) async {
          throw StateError('conversion failed');
        },
      );
      addTearDown(testConverter.dispose);

      final result = await testConverter.convertDanmakus(
        [_danmaku('鼠标')],
        DanmakuChineseMode.t2s,
      );

      expect(result.single.message, '鼠标');
      expect(result.single.originalMessage, '鼠标');
    });

    test('does not cache failed conversions', () async {
      var calls = 0;
      final testConverter = DanmakuChineseConverter(
        batchConverter: (mode, messages) async {
          calls++;
          throw StateError('conversion failed');
        },
      );
      addTearDown(testConverter.dispose);
      final danmakus = [_danmaku('鼠标')];

      await testConverter.convertDanmakus(danmakus, DanmakuChineseMode.t2s);
      await testConverter.convertDanmakus(danmakus, DanmakuChineseMode.t2s);

      expect(calls, 2);
    });

    test('reuses cached conversions within a session', () async {
      final requested = <String>[];
      final testConverter = DanmakuChineseConverter(
        batchConverter: (mode, messages) async {
          requested.addAll(messages);
          return [
            for (final message in messages) '已转换:$message',
          ];
        },
      );
      addTearDown(testConverter.dispose);
      final danmakus = [_danmaku('开放中文转换')];

      final first = await testConverter.convertDanmakus(
        danmakus,
        DanmakuChineseMode.s2t,
      );
      final second = await testConverter.convertDanmakus(
        danmakus,
        DanmakuChineseMode.s2t,
      );

      expect(first.single.message, '已转换:开放中文转换');
      expect(second.single.message, '已转换:开放中文转换');
      expect(requested, ['开放中文转换']);
    });

    test('clears cache when disposed', () async {
      var calls = 0;
      final testConverter = DanmakuChineseConverter(
        batchConverter: (mode, messages) async {
          calls++;
          return ['转换结果'];
        },
      );
      final danmakus = [_danmaku('鼠标')];

      await testConverter.convertDanmakus(danmakus, DanmakuChineseMode.t2s);
      testConverter.dispose();
      await testConverter.convertDanmakus(danmakus, DanmakuChineseMode.t2s);

      expect(calls, 2);
    });

    test('evicts oldest entries when cache limit is reached', () async {
      var calls = 0;
      final testConverter = DanmakuChineseConverter(
        batchConverter: (mode, messages) async {
          calls++;
          return [for (final message in messages) 'v:$message'];
        },
        maxCacheEntries: 2,
      );
      addTearDown(testConverter.dispose);
      final danmakus = [
        _danmaku('一'),
        _danmaku('二'),
        _danmaku('三'),
      ];

      await testConverter.convertDanmakus(danmakus, DanmakuChineseMode.s2t);
      await testConverter.convertDanmakus(danmakus, DanmakuChineseMode.s2t);

      expect(calls, 2);
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
