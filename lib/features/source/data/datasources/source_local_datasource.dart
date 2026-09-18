import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';

/// 数据源本地持久化数据源。
///
/// 该类只负责 Hive 读写，不包含排序业务和页面状态。
class SourceLocalDataSource {
  Box<CrawlConfigItem> get configBox => Storage.crawlConfigs;

  Listenable get listenable => configBox.listenable();

  Future<List<CrawlConfigItem>> loadConfigs() async {
    return configBox.values.toList();
  }

  Future<CrawlConfigItem?> loadConfig(String name) async {
    final value = configBox.get(name);
    return value;
  }

  CrawlConfigItem? loadConfigSync(String name) {
    final value = configBox.get(name);
    return value;
  }

  Future<void> saveConfig(CrawlConfigItem config) {
    return configBox.put(config.name, config);
  }

  Future<void> deleteConfig(String name) {
    return configBox.delete(name);
  }

  Future<List<String>> loadOrder() async {
    final value = AppSettings.getSetting<Object?>(StorageKey.crawlConfigOrder);
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  Future<void> saveOrder(List<String> names) {
    return AppSettings.setSetting(StorageKey.crawlConfigOrder, names);
  }
}
