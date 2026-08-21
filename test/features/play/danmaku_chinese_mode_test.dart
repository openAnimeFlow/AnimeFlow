import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DanmakuChineseMode', () {
    test('maps to OpenCC configs', () {
      expect(DanmakuChineseMode.none.config, isNull);
      expect(DanmakuChineseMode.s2t.config, OpenCCConfig.s2t);
      expect(DanmakuChineseMode.t2s.config, OpenCCConfig.t2s);
    });

    test('fromName restores known modes', () {
      expect(DanmakuChineseMode.fromName('none'), DanmakuChineseMode.none);
      expect(DanmakuChineseMode.fromName('s2t'), DanmakuChineseMode.s2t);
      expect(DanmakuChineseMode.fromName('t2s'), DanmakuChineseMode.t2s);
    });

    test('fromName falls back to none for unknown values', () {
      expect(DanmakuChineseMode.fromName('unknown'), DanmakuChineseMode.none);
      expect(DanmakuChineseMode.fromName(null), DanmakuChineseMode.none);
    });
  });
}
