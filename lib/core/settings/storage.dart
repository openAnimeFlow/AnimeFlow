import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/hive_registrar.g.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/models/search/search_history_module.dart';
import 'package:hive_ce/hive.dart';

class Storage {
  static late final Box<dynamic> setting;
  static late final Box<CrawlConfigItem> crawlConfigs;
  static late final Box<PlayHistory> playHistory;
  static late final Box<SearchHistory> searchHistory;
  static late final Box<DownloadRecord> downloads;

  static Future<void> init() async {
    Hive.registerAdapters();
    crawlConfigs = await _openCrawlConfigs();
    setting = await _openBoxWithFallback<dynamic>(StorageKey.settingsKey);
    playHistory =
        await _openBoxWithFallback<PlayHistory>(StorageKey.playHistoryKey);
    searchHistory =
        await _openBoxWithFallback<SearchHistory>(StorageKey.searchHistoryKey);
    downloads =
        await _openBoxWithFallback<DownloadRecord>(StorageKey.downloadsKey);
  }

  static Future<Box<CrawlConfigItem>> _openCrawlConfigs() async {
    final legacyBox = await _openBoxWithFallback<dynamic>(
      StorageKey.crawlConfigs,
    );

    // Before the typed box was introduced, configurations were persisted as
    // JSON maps. Convert them in place so existing users keep their plugins.
    for (final entry in legacyBox.toMap().entries) {
      final value = entry.value;
      if (value is CrawlConfigItem) continue;
      if (value is Map) {
        await legacyBox.put(
          entry.key,
          CrawlConfigItem.fromJson(Map<String, dynamic>.from(value)),
        );
      }
    }

    await legacyBox.close();
    return Hive.openBox<CrawlConfigItem>(StorageKey.crawlConfigs);
  }

  static Future<Box<T>> _openBoxWithFallback<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (_) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<dynamic>(boxName).close();
      }
      // Give Windows a moment to release file handles after a failed open.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox<T>(boxName);
    }
  }
}
