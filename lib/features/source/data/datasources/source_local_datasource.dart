import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';

/// 数据源本地持久化数据源。
///
/// 该类只负责 Hive 读写，不包含排序业务和页面状态。
class SourceLocalDataSource {
  Box<dynamic> get configBox => Storage.crawlConfigs;

  Box<dynamic> get settingBox => Storage.setting;

  Listenable get listenable => configBox.listenable();

  Future<List<CrawlConfigItem>> loadConfigs() async {
    return configBox.values.map((value) {
      return CrawlConfigItem.fromJson(Map<String, dynamic>.from(value as Map));
    }).toList();
  }

  Future<CrawlConfigItem?> loadConfig(String name) async {
    final value = configBox.get(name);
    if (value is! Map) return null;
    return CrawlConfigItem.fromJson(Map<String, dynamic>.from(value));
  }

  CrawlConfigItem? loadConfigSync(String name) {
    final value = configBox.get(name);
    if (value is! Map) return null;
    return CrawlConfigItem.fromJson(Map<String, dynamic>.from(value));
  }

  Future<void> saveConfig(CrawlConfigItem config) {
    return configBox.put(config.name, config.toJson());
  }

  Future<void> deleteConfig(String name) {
    return configBox.delete(name);
  }

  Future<List<String>> loadOrder() async {
    final value = settingBox.get(StorageKey.crawlConfigOrder);
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  Future<void> saveOrder(List<String> names) {
    return settingBox.put(StorageKey.crawlConfigOrder, names);
  }
}
