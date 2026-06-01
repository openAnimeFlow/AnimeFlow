import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/hive_registrar.g.dart';
import 'package:anime_flow/models/play/play_history.dart';
import 'package:anime_flow/models/search/search_history_module.dart';
import 'package:hive_ce/hive.dart';

class Storage {
  static late final Box<dynamic> setting;
  static late final Box<dynamic> crawlConfigs;
  static late final Box<PlayHistory> playHistory;
  static late final Box<SearchHistory> searchHistory;

  static Future<void> init() async {
    Hive.registerAdapters();
    crawlConfigs = await _openBoxWithFallback<dynamic>(StorageKey.crawlConfigs);
    setting = await _openBoxWithFallback<dynamic>(StorageKey.settingsKey);
    playHistory = await _openBoxWithFallback<PlayHistory>(StorageKey.playHistoryKey);
    searchHistory = await _openBoxWithFallback<SearchHistory>(StorageKey.searchHistoryKey);
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
