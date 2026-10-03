import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
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

  Listenable? _listenable;

  /// 数据源变更通知。
  ///
  /// 必须返回**同一个**实例：`configBox.listenable()` 每次调用都会新建一个
  /// `_BoxListenable`，用后一次拿到的实例去 `removeListener` 无法移除前一次
  /// 注册的监听，监听会残留并在持有者销毁后继续触发。
  Listenable get listenable => _listenable ??= configBox.listenable();

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
