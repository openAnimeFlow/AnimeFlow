import 'dart:io';
import 'dart:isolate';

import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'danmaku_chinese_mode.dart';

/// 弹幕简体/繁体转换服务。
///
/// 批量转换放到后台 isolate 中执行，避免 OpenCC 的同步 FFI 调用阻塞 UI。
class DanmakuChineseConverter {
  String? _dataDir;

  /// 触发一次资源解压，并记录 OpenCC 数据目录。
  ///
  /// 当前 flutter_opencc_plus 会把 package assets 解压到系统临时目录；
  /// 升级依赖后如果路径规则变化，需要同步复核。
  Future<String> _ensureDataDir() async {
    final cached = _dataDir;
    if (cached != null) return cached;

    final seed = await ZhConverter.create(OpenCCConfig.s2t);
    seed.dispose();

    final resolved = p.join(
      Directory.systemTemp.path,
      'flutter_opencc_plus_assets',
    );
    _dataDir = resolved;
    return resolved;
  }

  Future<List<Danmaku>> convertDanmakus(
    List<Danmaku> danmakus,
    DanmakuChineseMode mode,
  ) async {
    if (danmakus.isEmpty) {
      return danmakus;
    }
    if (mode == DanmakuChineseMode.none) {
      return [
        for (final danmaku in danmakus)
          danmaku.copyWith(message: danmaku.originalMessage),
      ];
    }

    final dataDir = await _ensureDataDir();
    final config = mode.config!;
    final messages = [
      for (final danmaku in danmakus) danmaku.originalMessage,
    ];

    try {
      final converted = await Isolate.run<List<String>>(
        () => ZhConverter.run(
          config,
          (converter) => converter.convertAll(messages),
          dataDir: dataDir,
        ),
      );

      return [
        for (var i = 0; i < danmakus.length; i++)
          danmakus[i].copyWith(message: converted[i]),
      ];
    } on Object {
      // 转换失败时保留原始文本。
      return [
        for (final danmaku in danmakus)
          danmaku.copyWith(message: danmaku.originalMessage),
      ];
    }
  }

  void dispose() {}
}

final danmakuChineseConverterProvider =
    Provider<DanmakuChineseConverter>((ref) {
  final converter = DanmakuChineseConverter();
  ref.onDispose(converter.dispose);
  return converter;
});
