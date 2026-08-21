import 'dart:io';
import 'dart:isolate';

import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'danmaku_chinese_mode.dart';

/// 批量转换弹幕文本；返回 null 表示本次转换失败。
typedef DanmakuBatchConverter = Future<List<String>?> Function(
  DanmakuChineseMode mode,
  List<String> messages,
);

/// 弹幕简体/繁体转换服务。
///
/// 批量转换放到后台 isolate 中执行，避免 OpenCC 的同步 FFI 调用阻塞 UI。
class DanmakuChineseConverter {
  static const int _defaultMaxCacheEntries = 4096;

  DanmakuChineseConverter({
    DanmakuBatchConverter? batchConverter,
    int maxCacheEntries = _defaultMaxCacheEntries,
  }) : _maxCacheEntries = maxCacheEntries {
    _batchConverter = batchConverter ?? _convertBatch;
  }

  String? _dataDir;
  late final DanmakuBatchConverter _batchConverter;
  final int _maxCacheEntries;
  final Map<(DanmakuChineseMode, String), String> _conversionCache = {};

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

    try {
      return await _convertWithCache(danmakus, mode);
    } on Object {
      // 转换失败时保留原始文本，不允许弹幕丢失。
      return [
        for (final danmaku in danmakus)
          danmaku.copyWith(message: danmaku.originalMessage),
      ];
    }
  }

  Future<List<Danmaku>> _convertWithCache(
    List<Danmaku> danmakus,
    DanmakuChineseMode mode,
  ) async {
    final messages = [
      for (final danmaku in danmakus) danmaku.originalMessage,
    ];
    final converted = List<String>.filled(danmakus.length, '');
    final missingIndexes = <int>[];

    for (var i = 0; i < messages.length; i++) {
      final cached = _conversionCache[(mode, messages[i])];
      if (cached != null) {
        converted[i] = cached;
      } else {
        missingIndexes.add(i);
      }
    }

    if (missingIndexes.isNotEmpty) {
      final convertedBatch = await _batchConverter(
        mode,
        [for (final index in missingIndexes) messages[index]],
      );
      if (convertedBatch == null ||
          convertedBatch.length != missingIndexes.length) {
        return [
          for (final danmaku in danmakus)
            danmaku.copyWith(message: danmaku.originalMessage),
        ];
      }

      for (var i = 0; i < missingIndexes.length; i++) {
        final index = missingIndexes[i];
        converted[index] = convertedBatch[i];
        _putCache(mode, messages[index], converted[index]);
      }
    }

    return [
      for (var i = 0; i < danmakus.length; i++)
        danmakus[i].copyWith(message: converted[i]),
    ];
  }

  void _putCache(
    DanmakuChineseMode mode,
    String original,
    String convertedMessage,
  ) {
    if (_maxCacheEntries <= 0) return;
    if (_conversionCache.length >= _maxCacheEntries) {
      _conversionCache.remove(_conversionCache.keys.first);
    }
    _conversionCache[(mode, original)] = convertedMessage;
  }

  Future<List<String>?> _convertBatch(
    DanmakuChineseMode mode,
    List<String> messages,
  ) async {
    try {
      final dataDir = await _ensureDataDir();
      final config = mode.config!;
      return await Isolate.run<List<String>>(
        () => ZhConverter.run(
          config,
          (converter) => converter.convertAll(messages),
          dataDir: dataDir,
        ),
      );
    } on Object {
      return null;
    }
  }

  void dispose() {
    _conversionCache.clear();
  }
}

final danmakuChineseConverterProvider =
    Provider<DanmakuChineseConverter>((ref) {
  final converter = DanmakuChineseConverter();
  ref.onDispose(converter.dispose);
  return converter;
});
