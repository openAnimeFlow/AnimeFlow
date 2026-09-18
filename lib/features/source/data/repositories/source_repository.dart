import 'dart:convert';

import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/features/source/data/datasources/source_local_datasource.dart';
import 'package:flutter/foundation.dart';

/// 数据源持久层的统一入口。
class SourceRepository {
  SourceRepository({SourceLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? SourceLocalDataSource();

  final SourceLocalDataSource _localDataSource;

  Listenable get listenable => _localDataSource.listenable;

  Future<List<CrawlConfigItem>> getSources() async {
    final configs = await _localDataSource.loadConfigs();
    final storedOrder = await _localDataSource.loadOrder();
    final ordered = _applyOrder(configs, storedOrder);
    final normalizedOrder = ordered.map((config) => config.name).toList();

    if (!_sameOrder(storedOrder, normalizedOrder)) {
      await _localDataSource.saveOrder(normalizedOrder);
    }
    return ordered;
  }

  Future<CrawlConfigItem?> getSource(String name) {
    return _localDataSource.loadConfig(name);
  }

  CrawlConfigItem? getSourceSync(String name) {
    return _localDataSource.loadConfigSync(name);
  }

  Future<void> saveSource(
    CrawlConfigItem config, {
    String? originalName,
  }) async {
    final storedOrder = await _localDataSource.loadOrder();
    final oldIndex =
        originalName == null ? -1 : storedOrder.indexOf(originalName);
    if (originalName != null && originalName != config.name) {
      await _localDataSource.deleteConfig(originalName);
    }
    await _localDataSource.saveConfig(config);

    final names = [...storedOrder]..remove(originalName);
    names.remove(config.name);
    final insertIndex =
        oldIndex >= 0 && oldIndex <= names.length ? oldIndex : names.length;
    names.insert(insertIndex, config.name);
    final orderedSources = await getSources();
    final availableNames = orderedSources.map((source) => source.name).toSet();
    await _localDataSource.saveOrder(
      [
        ...names.where(availableNames.contains),
        ...orderedSources
            .map((source) => source.name)
            .where((name) => !names.contains(name)),
      ],
    );
  }

  Future<void> downloadPlugin({
    required String pluginPath,
    required String catalogVersion,
  }) {
    return _installPlugin(
      pluginPath: pluginPath,
      catalogVersion: catalogVersion,
    );
  }

  Future<void> updatePlugin({
    required String pluginPath,
    required String catalogVersion,
  }) {
    return _installPlugin(
      pluginPath: pluginPath,
      catalogVersion: catalogVersion,
    );
  }

  Future<void> _installPlugin({
    required String pluginPath,
    required String catalogVersion,
  }) async {
    var downloadUrl = '${CommonApi.pluginRepo}/$pluginPath';
    if (_isPluginMirrorEnabled()) {
      downloadUrl = Utils.jsDelivrCdnUrl(downloadUrl);
    }

    final raw = await Api.getResources(downloadUrl);
    final json = raw is String ? jsonDecode(raw) : raw;
    if (json is! Map) {
      throw const FormatException('插件配置格式无效');
    }

    final data = CrawlConfigItem.fromJson(Map<String, dynamic>.from(json));
    await saveSource(
      CrawlConfigItem.fromJson({
        ...data.toJson(),
        'version': catalogVersion,
      }),
    );
  }

  Future<void> deleteSource(String name) async {
    await _localDataSource.deleteConfig(name);
    final order = await _localDataSource.loadOrder();
    order.removeWhere((item) => item == name);
    await _localDataSource.saveOrder(order);
  }

  Future<void> reorderSources(int oldIndex, int newIndex) async {
    final sources = await getSources();
    if (oldIndex < 0 || oldIndex >= sources.length) return;
    if (newIndex < 0 || newIndex >= sources.length) return;

    final names = sources.map((source) => source.name).toList();
    final item = names.removeAt(oldIndex);
    names.insert(newIndex, item);
    await _localDataSource.saveOrder(names);
  }

  List<CrawlConfigItem> _applyOrder(
    List<CrawlConfigItem> configs,
    List<String> storedOrder,
  ) {
    final configsByName = {
      for (final config in configs) config.name: config,
    };
    final result = <CrawlConfigItem>[];
    final addedNames = <String>{};

    for (final name in storedOrder) {
      final config = configsByName[name];
      if (config != null && addedNames.add(name)) {
        result.add(config);
      }
    }
    for (final config in configs) {
      if (addedNames.add(config.name)) {
        result.add(config);
      }
    }
    return result;
  }

  bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  bool _isPluginMirrorEnabled() {
    return AppSettings.getSetting<bool>(
          SettingKey.isMirror,
          defaultValue: false,
        ) ??
        false;
  }
}
