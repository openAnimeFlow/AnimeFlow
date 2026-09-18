import 'dart:convert';

import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/features/source/data/datasources/source_local_datasource.dart';
import 'package:flutter/services.dart';

/// 初始化并升级内置数据源配置。
///
/// 内置插件属于数据源模块，初始化时写入数据源本地数据源，
/// 由 [SourceLocalDataSource] 统一负责持久化。
class SourceConfigInitializer {
  SourceConfigInitializer({SourceLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? SourceLocalDataSource();

  final SourceLocalDataSource _localDataSource;
  final LiggLogger _logger = LiggLogger();

  Future<void> initialize() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final pluginPaths = assetManifest.listAssets().where((asset) =>
        asset.startsWith('assets/plugins/') && asset.endsWith('.json'));

    for (final path in pluginPaths) {
      try {
        final json = jsonDecode(await rootBundle.loadString(path));
        if (json is! Map) {
          throw const FormatException('插件配置必须是 JSON 对象');
        }

        final config = CrawlConfigItem.fromJson(
          Map<String, dynamic>.from(json),
        );
        final assetVersion = config.version;
        final localConfig = await _localDataSource.loadConfig(config.name);

        if (localConfig == null) {
          await _localDataSource.saveConfig(config);
          _logger.i('已加载配置：${config.name},版本：$assetVersion');
          continue;
        }

        if (Utils.compareVersionNumbers(assetVersion, localConfig.version) >
            0) {
          await _localDataSource.saveConfig(config);
          _logger.i(
            '已升级配置：${config.name},'
            '${localConfig.version} -> $assetVersion',
          );
        }
      } catch (error, stackTrace) {
        _logger.e(
          '加载配置失败：$path, 错误：$error',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
